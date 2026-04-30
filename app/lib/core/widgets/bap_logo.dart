import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Bad A Paname club logo (wide horizontal lockup).
///
/// Pass [color] to tint it (e.g. white on dark backgrounds, primary for brand
/// surfaces). When [color] is null the SVG renders with its native fill.
///
/// The asset has a natural aspect ratio of ~1.64 — give it a [height] and the
/// width is derived automatically.
class BapLogo extends StatelessWidget {
  final double height;
  final Color? color;

  const BapLogo({super.key, this.height = 28, this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo_bap.svg',
      height: height,
      fit: BoxFit.contain,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
