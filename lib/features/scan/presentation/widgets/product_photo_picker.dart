import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/user_facing_error.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import 'invoice_preview.dart';
import 'invoice_preview_dialog.dart';

/// An optional photo for a product added without one (by voice or by
/// hand): the receipt, the box or the product. [onPicked] uploads it and
/// returns null, or the failure's message.
class ProductPhotoPicker extends StatefulWidget {
  const ProductPhotoPicker({
    super.key,
    required this.imageUrl,
    required this.onPicked,
    ImagePicker? picker,
  }) : _picker = picker;

  final String? imageUrl;
  final Future<String?> Function(String path) onPicked;
  final ImagePicker? _picker;

  @override
  State<ProductPhotoPicker> createState() => _ProductPhotoPickerState();
}

class _ProductPhotoPickerState extends State<ProductPhotoPicker> {
  late final _picker = widget._picker ?? ImagePicker();
  bool _uploading = false;

  Future<void> _choose() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(AppIcons.camera),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.of(sheet).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(AppIcons.gallery),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.of(sheet).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    // Same size as scanned photos: sharp enough to read, small to upload.
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2000,
      maxHeight: 2000,
    );
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    final error = await widget.onPicked(picked.path);
    if (!mounted) return;
    setState(() => _uploading = false);
    if (error != null) AppSnackBar.error(context, userFacingError(l10n, error));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = widget.imageUrl;

    if (imageUrl != null && !_uploading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InvoicePreview(
            imageUrl: imageUrl,
            onTap: () => showInvoicePreviewDialog(context, imageUrl),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: _choose,
              icon: const Icon(AppIcons.camera),
              label: Text(l10n.changePhoto),
            ),
          ),
        ],
      );
    }

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _uploading ? null : _choose,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: _uploading
                    ? const Padding(
                        padding: EdgeInsets.all(4),
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Icon(AppIcons.camera, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.addPhoto, style: textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      l10n.addPhotoHint,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
