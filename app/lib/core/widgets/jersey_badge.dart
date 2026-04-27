import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bap_pulse/shared/data/mock_repository.dart';
import 'package:bap_pulse/shared/models/jersey.dart';

/// Visual jersey badge — used as a small overlay on player avatars and as
/// a centerpiece on the jerseys screen.
///
/// Three rendering variants — the default `jersey` is a stylised shirt
/// silhouette, `disc` is a round medal, `flat` is a chip.
enum JerseyVariant { jersey, disc, flat }

class JerseyBadge extends StatelessWidget {
  final JerseyKind kind;
  final double size;
  final JerseyVariant variant;

  const JerseyBadge({
    super.key,
    required this.kind,
    this.size = 56,
    this.variant = JerseyVariant.jersey,
  });

  @override
  Widget build(BuildContext context) {
    final j = MockRepository.instance.jersey(kind);

    return switch (variant) {
      JerseyVariant.jersey => SizedBox(
          width: size,
          height: size * 1.05,
          child: CustomPaint(painter: _JerseyShirtPainter(j)),
        ),
      JerseyVariant.disc => _disc(j),
      JerseyVariant.flat => _flat(j),
    };
  }

  Widget _disc(Jersey j) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: j.color,
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _discContent(j),
      );

  Widget _discContent(Jersey j) {
    switch (kind) {
      case JerseyKind.yellow:
        return Text(
          '1',
          style: GoogleFonts.spaceGrotesk(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
            color: j.textColor,
          ),
        );
      case JerseyKind.green:
        return Icon(Icons.check_rounded,
            size: size * 0.55, color: Colors.white);
      case JerseyKind.fight:
        return Icon(Icons.star_rounded,
            size: size * 0.6, color: j.accent ?? Colors.black);
      case JerseyKind.polka:
        return CustomPaint(
            size: Size(size, size), painter: _PolkaDotsPainter(j));
    }
  }

  Widget _flat(Jersey j) => Container(
        width: size,
        height: size * 0.72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: j.color,
          borderRadius: BorderRadius.circular(size * 0.18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Text(
          switch (kind) {
            JerseyKind.yellow => 'GC',
            JerseyKind.polka => 'KOM',
            JerseyKind.green => 'W4',
            JerseyKind.fight => 'FGT',
          },
          style: GoogleFonts.spaceGrotesk(
            fontSize: size * 0.28,
            fontWeight: FontWeight.w700,
            color: j.textColor,
            letterSpacing: -0.3,
          ),
        ),
      );
}

class _JerseyShirtPainter extends CustomPainter {
  final Jersey jersey;
  _JerseyShirtPainter(this.jersey);

  @override
  void paint(Canvas canvas, Size size) {
    // The shirt path is built in a 56×60 viewBox (matches jersey.jsx) and
    // scaled to the target size.
    const vbW = 56.0;
    const vbH = 60.0;
    final scaleX = size.width / vbW;
    final scaleY = size.height / vbH;

    final shirt = Path()
      ..moveTo(8 * scaleX, 12 * scaleY)
      ..lineTo(20 * scaleX, 4 * scaleY)
      ..lineTo(22 * scaleX, 8 * scaleY)
      ..lineTo(28 * scaleX, 10 * scaleY)
      ..lineTo(34 * scaleX, 8 * scaleY)
      ..lineTo(36 * scaleX, 4 * scaleY)
      ..lineTo(48 * scaleX, 12 * scaleY)
      ..lineTo(44 * scaleX, 22 * scaleY)
      ..lineTo(40 * scaleX, 20 * scaleY)
      ..lineTo(40 * scaleX, 56 * scaleY)
      ..lineTo(16 * scaleX, 56 * scaleY)
      ..lineTo(16 * scaleX, 20 * scaleY)
      ..lineTo(12 * scaleX, 22 * scaleY)
      ..close();

    // Drop shadow
    canvas.drawPath(
      shirt.shift(const Offset(0, 1)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8),
    );

    // Body fill
    canvas.drawPath(
      shirt,
      Paint()..color = jersey.color,
    );

    // Polka dots overlay
    if (jersey.kind == JerseyKind.polka && jersey.accent != null) {
      canvas.save();
      canvas.clipPath(shirt);
      final dotPaint = Paint()..color = jersey.accent!;
      const step = 7.0;
      for (double y = 0; y < vbH; y += step) {
        for (double x = 0; x < vbW; x += step) {
          canvas.drawCircle(
            Offset(
              (x + 3.5) * scaleX,
              (y + 3.5) * scaleY,
            ),
            2 * ((scaleX + scaleY) / 2),
            dotPaint,
          );
        }
      }
      canvas.restore();
    }

    // Outline
    canvas.drawPath(
      shirt,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.black.withValues(alpha: 0.18),
    );

    // Collar shadow
    final collar = Path()
      ..moveTo(22 * scaleX, 8 * scaleY)
      ..lineTo(28 * scaleX, 10 * scaleY)
      ..lineTo(34 * scaleX, 8 * scaleY)
      ..lineTo(32 * scaleX, 13 * scaleY)
      ..lineTo(28 * scaleX, 14 * scaleY)
      ..lineTo(24 * scaleX, 13 * scaleY)
      ..close();
    canvas.drawPath(
      collar,
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );

    // Mark / number
    final tp = TextPainter(textDirection: TextDirection.ltr);
    switch (jersey.kind) {
      case JerseyKind.yellow:
        tp
          ..text = TextSpan(
            text: '1',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16 * ((scaleX + scaleY) / 2),
              fontWeight: FontWeight.w700,
              color: jersey.textColor,
            ),
          )
          ..layout()
          ..paint(canvas,
              Offset(28 * scaleX - tp.width / 2, 32 * scaleY));
        break;
      case JerseyKind.green:
        final check = Path()
          ..moveTo(20 * scaleX, 34 * scaleY)
          ..lineTo(26 * scaleX, 40 * scaleY)
          ..lineTo(36 * scaleX, 28 * scaleY);
        canvas.drawPath(
          check,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = Colors.white,
        );
        break;
      case JerseyKind.fight:
        final star = Path()
          ..moveTo(28 * scaleX, 26 * scaleY)
          ..lineTo(30 * scaleX, 32 * scaleY)
          ..lineTo(36 * scaleX, 32 * scaleY)
          ..lineTo(31 * scaleX, 36 * scaleY)
          ..lineTo(33 * scaleX, 42 * scaleY)
          ..lineTo(28 * scaleX, 38 * scaleY)
          ..lineTo(23 * scaleX, 42 * scaleY)
          ..lineTo(25 * scaleX, 36 * scaleY)
          ..lineTo(20 * scaleX, 32 * scaleY)
          ..lineTo(26 * scaleX, 32 * scaleY)
          ..close();
        canvas.drawPath(
          star,
          Paint()..color = jersey.accent ?? const Color(0xFF0A84FF),
        );
        break;
      case JerseyKind.polka:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _JerseyShirtPainter oldDelegate) =>
      oldDelegate.jersey != jersey;
}

class _PolkaDotsPainter extends CustomPainter {
  final Jersey jersey;
  _PolkaDotsPainter(this.jersey);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = jersey.accent ?? const Color(0xFFE63946);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 2;
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    const dots = [
      [14, 16], [36, 12], [22, 30], [42, 28], [16, 40], [38, 44], [28, 22]
    ];
    final s = size.width / 56;
    for (final d in dots) {
      canvas.drawCircle(
        Offset(d[0] * s, d[1] * s),
        size.width > 40 ? 3.5 * s : 2.5 * s,
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PolkaDotsPainter oldDelegate) => false;
}
