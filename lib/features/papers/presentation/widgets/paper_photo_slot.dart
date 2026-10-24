import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../l10n/app_localizations.dart';

/// What a photo slot shows: a photo picked in the form (not uploaded yet),
/// the saved one, or nothing.
class PaperPhoto {
  const PaperPhoto.none() : localPath = null, url = null, isSaved = false;
  const PaperPhoto.local(String this.localPath) : url = null, isSaved = false;

  /// [url] is null if the saved photo's link couldn't be signed; the photo
  /// is still there and kept.
  const PaperPhoto.saved(this.url) : localPath = null, isSaved = true;

  final String? localPath;

  /// Signed link to the saved photo.
  final String? url;
  final bool isSaved;

  bool get isEmpty => localPath == null && !isSaved;
}

/// One side of a paper in the form. Empty, a tap picks a photo; with one,
/// a tap offers to view, replace or remove it.
class PaperPhotoSlot extends StatelessWidget {
  const PaperPhotoSlot({
    super.key,
    required this.label,
    required this.photo,
    required this.onChanged,
    this.enabled = true,
    ImagePicker? picker,
  }) : _picker = picker;

  final String label;
  final PaperPhoto photo;

  /// A new local photo, or [PaperPhoto.none] when it's removed.
  final ValueChanged<PaperPhoto> onChanged;
  final bool enabled;
  final ImagePicker? _picker;

  Future<void> _onTap(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<_Action>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!photo.isEmpty)
              ListTile(
                leading: const Icon(AppIcons.show),
                title: Text(l10n.paperViewPhoto),
                onTap: () => Navigator.of(sheet).pop(_Action.view),
              ),
            ListTile(
              leading: const Icon(AppIcons.camera),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.of(sheet).pop(_Action.camera),
            ),
            ListTile(
              leading: const Icon(AppIcons.gallery),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.of(sheet).pop(_Action.gallery),
            ),
            if (!photo.isEmpty)
              ListTile(
                leading: Icon(AppIcons.delete, color: AppColors.error),
                title: Text(
                  l10n.paperRemovePhoto,
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => Navigator.of(sheet).pop(_Action.remove),
              ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _Action.view:
        _showFullScreen(context);
      case _Action.remove:
        onChanged(const PaperPhoto.none());
      case _Action.camera || _Action.gallery:
        // Sharp enough to read the small print, small enough to upload.
        final picked = await (_picker ?? ImagePicker()).pickImage(
          source: action == _Action.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 2000,
          maxHeight: 2000,
        );
        if (picked != null) onChanged(PaperPhoto.local(picked.path));
    }
  }

  void _showFullScreen(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (dialog) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(child: InteractiveViewer(child: _image(BoxFit.contain))),
            PositionedDirectional(
              top: 40,
              end: 20,
              child: IconButton(
                tooltip: MaterialLocalizations.of(dialog).closeButtonTooltip,
                onPressed: () => Navigator.of(dialog).pop(),
                icon: const Icon(AppIcons.close, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image(BoxFit fit) {
    const broken = Center(child: Icon(AppIcons.brokenImage));
    final localPath = photo.localPath;
    if (localPath != null) return Image.file(File(localPath), fit: fit);
    final url = photo.url;
    if (url == null) return broken;
    return Image.network(url, fit: fit, errorBuilder: (_, _, _) => broken);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final shape = BorderRadius.circular(16);

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => _onTap(context) : null,
          // ID cards are about 1.6 wide for 1 high.
          child: AspectRatio(
            aspectRatio: 1.6,
            child: photo.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(AppIcons.camera, color: colorScheme.primary),
                      const SizedBox(height: 6),
                      Text(label, style: textTheme.labelLarge),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      _image(BoxFit.cover),
                      PositionedDirectional(
                        start: 8,
                        bottom: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: Text(
                              label,
                              style: textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

enum _Action { view, camera, gallery, remove }
