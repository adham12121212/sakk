import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_icons.dart';

class MoreActionsSheet {
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onEdit,
    required VoidCallback onShare,
    required VoidCallback onDownload,
    required VoidCallback onDelete,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(AppIcons.edit),
              title: Text(l10n.edit),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(AppIcons.share),
              title: Text(l10n.share),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onShare();
              },
            ),
            ListTile(
              leading: const Icon(AppIcons.download),
              title: Text(l10n.downloadInvoice),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onDownload();
              },
            ),
            ListTile(
              leading: Icon(AppIcons.delete, color: AppColors.error),
              title: Text(
                l10n.delete,
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
