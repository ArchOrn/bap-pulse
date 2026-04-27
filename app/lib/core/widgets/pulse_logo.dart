import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The BAP Pulse logo (stylised shuttlecock + waveform).
///
/// Pass [color] to tint it (e.g. white on dark backgrounds, or low-opacity
/// for the watermark on auth screens). When [color] is null the SVG renders
/// with its native colors.
class PulseLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const PulseLogo({super.key, this.size = 48, this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/bap_pulse_logo.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
