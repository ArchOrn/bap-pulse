import 'package:flutter/material.dart';
import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/widgets/pulse_logo.dart';

/// Subtle full-screen background used by all auth screens — a darker green
/// gradient with the BAP Pulse logo as a faint watermark off-canvas.
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF13201A), Color(0xFF0B0F14)],
          stops: [0.0, 0.6],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -120,
            right: -90,
            child: Opacity(opacity: 0.05, child: PulseLogo(size: 540, color: AppColors.primary)),
          ),
          child,
        ],
      ),
    );
  }
}
