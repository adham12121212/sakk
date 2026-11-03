import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/app_localizations.dart';

/// The permissions Sakk asks for through [AppPermissions].
enum AppPermission {
  camera(Permission.camera),
  notifications(Permission.notification);

  const AppPermission(this.platform);

  final Permission platform;
}

/// The operating system's side of [AppPermissions], replaced in tests.
class PermissionBackend {
  const PermissionBackend();

  Future<PermissionStatus> status(Permission permission) => permission.status;
  Future<PermissionStatus> request(Permission permission) =>
      permission.request();
  Future<bool> openSettings() => openAppSettings();
}

/// The one way into a permission, for the camera and for notifications.
class AppPermissions {
  AppPermissions({PermissionBackend backend = const PermissionBackend()})
    : _backend = backend;

  static final instance = AppPermissions();

  final PermissionBackend _backend;

  /// True from a tap until the system prompt or dialog it opened is answered:
  /// a second request at that point would throw on Android.
  bool _asking = false;

  /// The wait for a trip to Settings that hasn't come back yet.
  Completer<bool>? _settingsTrip;

  /// Whether the action behind a tap can go ahead, asking if need be:
  ///
  /// - granted: true straight away.
  /// - not decided, or denied but askable: shows the system prompt. Saying no
  ///   to it just returns false; the next tap asks again.
  /// - the system won't ask (permanently denied, restricted): explains why
  ///   Sakk needs it and offers Settings. Coming back from there checks again
  ///   and returns true if it was turned on, so the action continues by itself.
  ///
  /// Android only reveals "permanently denied" by answering a request without
  /// a prompt, and on Android 12 and below notifications have no prompt at all
  /// (a plain "denied" every time). So what decides between a quiet false and
  /// the dialog is whether a prompt really appeared: a tap always shows
  /// something.
  ///
  /// If the check itself fails this returns true, leaving the outcome to the
  /// camera or the notification rather than blocking the user.
  Future<bool> ensure(BuildContext context, AppPermission permission) async {
    if (!_isRuntimePermission(permission)) return true;
    if (_asking) return false;

    // Whoever is still waiting on an abandoned trip to Settings gives way, so
    // one return from Settings can't run two actions.
    final abandoned = _settingsTrip;
    if (abandoned != null && !abandoned.isCompleted) abandoned.complete(false);
    _settingsTrip = null;

    _asking = true;
    final bool openSettings;
    try {
      switch (await _ask(permission)) {
        case _Answer.granted:
          return true;
        case _Answer.declined:
          return false;
        case _Answer.blocked:
          if (!context.mounted) return false;
          openSettings = await _explain(context, permission);
      }
    } catch (e) {
      developer.log('Permission check failed for $permission: $e');
      return true;
    } finally {
      _asking = false;
    }
    return openSettings ? _throughSettings(permission) : false;
  }

  /// [ensure] with no UI, for when the user didn't tap anything (app start):
  /// asks if the system still can, and never shows the Settings dialog.
  Future<bool> requestQuietly(AppPermission permission) async {
    if (!_isRuntimePermission(permission)) return true;
    try {
      final status = await _backend.status(permission.platform);
      if (_isAllowed(status)) return true;
      return _isAllowed(await _backend.request(permission.platform));
    } catch (e) {
      developer.log('Permission request failed for $permission: $e');
      return false;
    }
  }

  /// The current state, without asking. Like [ensure], true if the check
  /// itself fails: "not granted" is only said when the system says so.
  Future<bool> isGranted(AppPermission permission) async {
    if (!_isRuntimePermission(permission)) return true;
    try {
      return _isAllowed(await _backend.status(permission.platform));
    } catch (e) {
      developer.log('Permission check failed for $permission: $e');
      return true;
    }
  }

  /// Android's camera needs nothing: without CAMERA in the manifest,
  /// image_picker hands off to the system camera app, so it can't be denied.
  bool _isRuntimePermission(AppPermission permission) =>
      permission != AppPermission.camera ||
      defaultTargetPlatform != TargetPlatform.android;

  bool _isAllowed(PermissionStatus status) =>
      status.isGranted || status.isLimited || status.isProvisional;

  Future<_Answer> _ask(AppPermission permission) async {
    final status = await _backend.status(permission.platform);
    if (_isAllowed(status)) return _Answer.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return _Answer.blocked;
    }

    // A system prompt takes the app out of the resumed state.
    var promptShown = false;
    final listener = AppLifecycleListener(
      onStateChange: (state) {
        if (state != AppLifecycleState.resumed) promptShown = true;
      },
    );
    try {
      final answer = await _backend.request(permission.platform);
      if (_isAllowed(answer)) return _Answer.granted;
      return promptShown ? _Answer.declined : _Answer.blocked;
    } finally {
      listener.dispose();
    }
  }

  /// True if the user chose to open Settings.
  Future<bool> _explain(BuildContext context, AppPermission permission) async {
    final l10n = AppLocalizations.of(context)!;
    final (title, message) = switch (permission) {
      AppPermission.camera => (
        l10n.cameraPermissionTitle,
        l10n.cameraPermissionMessage,
      ),
      AppPermission.notifications => (
        l10n.notificationPermissionTitle,
        l10n.notificationPermissionMessage,
      ),
    };
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
    return openSettings ?? false;
  }

  /// Opens Settings, waits for the user to come back and checks again.
  Future<bool> _throughSettings(AppPermission permission) async {
    final trip = Completer<bool>();
    _settingsTrip = trip;

    // Only a resume after really leaving counts: the app can flick through
    // inactive while Settings is still opening.
    var left = false;
    final listener = AppLifecycleListener(
      onStateChange: (state) {
        switch (state) {
          case AppLifecycleState.hidden || AppLifecycleState.paused:
            left = true;
          case AppLifecycleState.resumed when left && !trip.isCompleted:
            trip.complete(true);
          default:
            break;
        }
      },
    );
    try {
      // Listening first: the app may leave before this call returns.
      if (!await _backend.openSettings()) return false;
      if (!await trip.future) return false;
      return await isGranted(permission);
    } catch (e) {
      developer.log('Could not open Settings for $permission: $e');
      return false;
    } finally {
      listener.dispose();
      if (identical(_settingsTrip, trip)) _settingsTrip = null;
    }
  }
}

enum _Answer { granted, declined, blocked }
