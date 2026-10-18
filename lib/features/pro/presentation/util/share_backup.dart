import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/get_it.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/network_info.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/backup_data_source.dart';
import '../../domain/pro_limit.dart';
import '../pro_actions.dart';

/// Sakk Pro's backup: writes everything to `sakk-backup-<date>.json` and
/// opens the share sheet (save to Files / Drive, send by email...). Free
/// users get the paywall.
Future<void> shareBackup(BuildContext context) async {
  if (!ProActions.ensurePro(context, PaywallReason.backup)) return;
  final l10n = AppLocalizations.of(context)!;
  if (!await getIt<NetworkInfo>().isConnected) {
    if (context.mounted) AppSnackBar.error(context, l10n.errorNoInternet);
    return;
  }
  try {
    final backup = await getIt<BackupDataSource>().exportAll();
    final dir = await getTemporaryDirectory();
    final date = DateTime.now().toIso8601String().split('T').first;
    final file = File('${dir.path}/sakk-backup-$date.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(backup));
    if (!context.mounted) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'application/json')], subject: l10n.backupExport),
    );
  } on ServerException catch (e, st) {
    getIt<AppLogger>().error('Backup export failed', error: e, stackTrace: st);
    if (context.mounted) AppSnackBar.error(context, l10n.backupFailed);
  }
}
