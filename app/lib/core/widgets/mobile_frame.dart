import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bap_pulse/core/theme/colors.dart';

/// On wide viewports (web on desktop), constrains the app's content to a
/// phone-sized column centered on a darker backdrop. On narrow viewports
/// (mobile browsers, native iOS/Android), it is a no-op.
///
/// This is wired through `MaterialApp.router.builder` so it wraps every route
/// transparently — including modal sheets and dialogs.
class MobileFrame extends StatelessWidget {
  final Widget child;

  /// Width below which we don't apply any framing (treat as a real phone).
  static const double mobileBreakpoint = 600;

  /// Target column width on desktop — matches a typical iPhone width.
  static const double phoneWidth = 430;

  const MobileFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Native targets never need framing.
    if (!kIsWeb) return child;

    final w = MediaQuery.of(context).size.width;
    if (w < mobileBreakpoint) return child;

    return Container(
      color: const Color(0xFF06090C),
      alignment: Alignment.topCenter,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: phoneWidth,
          decoration: const BoxDecoration(color: AppColors.bgScaffold),
          child: MediaQuery(
            // Force MediaQuery.size to the phone width so widgets that read
            // the width (e.g. SafeArea, headers using MediaQuery padding)
            // behave as on a phone.
            data: MediaQuery.of(context).copyWith(
              size: Size(phoneWidth, MediaQuery.of(context).size.height),
              padding: const EdgeInsets.only(top: 24),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
