import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';

/// The صك ring logo, drawn from the launcher icon's adaptive foreground so it
/// stays sharp at any size.
///
/// The artwork is white with a yellow dot, for blue or dark backgrounds. On
/// light backgrounds pass [color] (usually `AppColors.primary`): the white
/// ring and lettering are recolored, the yellow dot is kept.
///
/// [size] is the full SVG canvas; the ring fills about 60% of it, matching
/// the Android adaptive-icon safe zone, so pass the size of the tile it sits in.
class SakkLogo extends StatelessWidget {
  const SakkLogo({super.key, required this.size, this.color});

  static const _asset = 'assets/icons/android_adaptive_foreground.svg';

  /// The white logo, decoded ahead of time by [precache].
  static PictureInfo? _precachedWhite;

  /// Decodes the white logo before `runApp`, so its first frame paints the
  /// logo synchronously. [SvgPicture] loads asynchronously and would show an
  /// empty frame right after the native splash, which reads as a flicker.
  static Future<void> precache() async {
    _precachedWhite ??= await vg.loadPicture(const SvgAssetLoader(_asset), null);
  }

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final precached = _precachedWhite;
    if (color == null && precached != null) {
      return Semantics(
        label: AppLocalizations.of(context)?.appName,
        image: true,
        child: CustomPaint(
          size: Size.square(size),
          painter: _PicturePainter(precached),
        ),
      );
    }
    return SvgPicture.asset(
      _asset,
      width: size,
      height: size,
      colorMapper: color == null ? null : _WhiteToColorMapper(color!),
      semanticsLabel: AppLocalizations.of(context)?.appName,
    );
  }
}

class _PicturePainter extends CustomPainter {
  _PicturePainter(this.info);

  final PictureInfo info;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / info.size.width, size.height / info.size.height);
    canvas.drawPicture(info.picture);
  }

  @override
  bool shouldRepaint(_PicturePainter oldDelegate) => oldDelegate.info != info;
}

class _WhiteToColorMapper extends ColorMapper {
  const _WhiteToColorMapper(this.color);

  final Color color;

  @override
  Color substitute(String? id, String elementName, String attributeName, Color color) {
    // Keep each element's own alpha (the faint ring track is white at 22%).
    if ((color.toARGB32() & 0x00FFFFFF) == 0x00FFFFFF) {
      return this.color.withAlpha((color.a * 255).round());
    }
    return color;
  }

  // flutter_svg caches parsed pictures by loader, which includes the mapper.
  @override
  bool operator ==(Object other) => other is _WhiteToColorMapper && other.color == color;

  @override
  int get hashCode => color.hashCode;
}
