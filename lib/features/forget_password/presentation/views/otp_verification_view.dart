import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../home/presentation/widgets/circle_icon_button.dart';
import '../../../../core/error/user_facing_error.dart';
import '../../../../core/util/localized_number.dart';
import '../../../../core/util/pii_masker.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/auth_primary_button.dart';
import '../cubit/password_reset_cubit.dart';
import '../widgets/otp_box.dart';
import 'new_password_view.dart';
import '../../../../core/theme/app_icons.dart';

class OtpVerificationView extends StatefulWidget {
  const OtpVerificationView({super.key, required this.email});

  final String email;

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
  static const _length = 6;
  final List<TextEditingController> _controllers = List.generate(
    _length,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _length,
    (_) => FocusNode(),
  );
  Timer? _cooldownTimer;
  Duration _cooldownLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  /// Counts down the cubit's resend cooldown, once a second.
  void _startCooldown() {
    _cooldownTimer?.cancel();
    void tick() {
      final left = context.read<PasswordResetCubit>().resendCooldownLeft;
      setState(() => _cooldownLeft = left);
      if (left == Duration.zero) _cooldownTimer?.cancel();
    }

    _cooldownLeft = context.read<PasswordResetCubit>().resendCooldownLeft;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  /// [value] in the app's digits.
  String _count(int value) =>
      formatLocalizedInt(Localizations.localeOf(context), value);

  String get _otp => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_otp.length == _length) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    setState(() {}); // refresh button enabled-state
  }

  void _verify() {
    if (_otp.length != _length) {
      AppSnackBar.error(
        context,
        AppLocalizations.of(context)!.enterDigitCode(_count(_length)),
      );
      return;
    }
    context.read<PasswordResetCubit>().verifyOtp(_otp);
  }

  void _resend() {
    context.read<PasswordResetCubit>().sendOtp(widget.email);
  }

  void _handleStateChange(BuildContext context, PasswordResetState state) {
    // Screens further down the stack share this cubit; only the visible one
    // should react (otherwise "resend code" pushes a second code screen).
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final l10n = AppLocalizations.of(context)!;
    if (state is PasswordResetError) {
      AppSnackBar.error(context, userFacingError(l10n, state.message));
    } else if (state is PasswordResetOtpSent) {
      if (state.resent) AppSnackBar.success(context, l10n.newCodeSentToEmail);
      for (final c in _controllers) {
        c.clear();
      }
      _startCooldown();
    } else if (state is PasswordResetOtpVerified) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<PasswordResetCubit>(),
            child: const NewPasswordView(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: BlocConsumer<PasswordResetCubit, PasswordResetState>(
        listener: _handleStateChange,
        builder: (context, state) {
          final isLoading = state is PasswordResetLoading;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleIconButton(
                    icon: AppIcons.back,
                    semanticLabel: l10n.back,
                    onTap: () => Navigator.of(context).pop(),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  SizedBox(height: 28.h),
                  Text(
                    l10n.enterCode,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    l10n.resetCodeSentIfAccountExists(
                      PiiMasker.maskEmail(widget.email),
                      _count(_length),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 32.h),
                  // Codes are read left to right in every language, so the
                  // boxes don't follow the Arabic layout direction.
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        _length,
                        (i) => OtpBox(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          onChanged: (v) => _onChanged(i, v),
                          enabled: !isLoading,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 28.h),
                  AuthPrimaryButton(
                    label: l10n.verify,
                    isLoading: isLoading,
                    onPressed: _verify,
                  ),
                  SizedBox(height: 16.h),
                  Center(
                    child: TextButton(
                      onPressed: isLoading || _cooldownLeft > Duration.zero
                          ? null
                          : _resend,
                      child: Text(
                        _cooldownLeft > Duration.zero
                            ? l10n.resendCodeIn(
                                _count(
                                  (_cooldownLeft.inMilliseconds / 1000).ceil(),
                                ),
                              )
                            : l10n.resendCode,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
