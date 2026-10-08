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

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _asset,
      width: size,
      height: size,
      colorMapper: color == null ? null : _WhiteToColorMapper(color!),
      semanticsLabel: AppLocalizations.of(context)?.appName,
    );
  }
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
