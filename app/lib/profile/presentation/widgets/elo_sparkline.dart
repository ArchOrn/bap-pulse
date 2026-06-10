import 'package:flutter/material.dart';
import 'package:bap_pulse/core/theme/colors.dart';

/// Smoothed line chart of ELO over the month, with a gradient area below.
class EloSparkline extends StatelessWidget {
  final List<int> data;
  final double height;

  const EloSparkline({super.key, required this.data, this.height = 70});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(painter: _SparklinePainter(data)),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> data;
  _SparklinePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minV = data.reduce((a, b) => a < b ? a : b) - 5;
    final maxV = data.reduce((a, b) => a > b ? a : b) + 5;

    final pts = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - (data[i] - minV) / (maxV - minV) * size.height;
      pts.add(Offset(x, y));
    }

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      line.lineTo(pts[i].dx, pts[i].dy);
    }

    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.35),
            AppColors.primary.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // End dot
    canvas.drawCircle(pts.last, 4, Paint()..color = AppColors.primary);
    canvas.drawCircle(
      pts.last,
      4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.data != data;
}
