import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class SmartCanteenLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showText;
  final bool isDark;

  const SmartCanteenLogo({
    super.key,
    this.size = 80,
    this.color,
    this.showText = false,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? (isDark ? Colors.white : AppColors.primary);

    Widget iconWidget = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SmartCanteenLogoPainter(color: primaryColor),
      ),
    );

    if (!showText) return iconWidget;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        const SizedBox(height: 12),
        Text(
          'Smart',
          style: TextStyle(
            fontSize: size * 0.32,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        Text(
          'Canteen',
          style: TextStyle(
            fontSize: size * 0.32,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Food Ordering & Tracking System',
          style: TextStyle(
            fontSize: size * 0.14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _SmartCanteenLogoPainter extends CustomPainter {
  final Color color;

  _SmartCanteenLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.055;

    // 1. Cloche Handle / Knob
    final knobRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.48),
        width: w * 0.14,
        height: h * 0.08,
      ),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(knobRect, fillPaint);

    // 2. Cloche Dome
    final domePath = Path();
    domePath.moveTo(w * 0.16, h * 0.74);
    // Control points for smooth dome
    domePath.cubicTo(
      w * 0.18,
      h * 0.50,
      w * 0.82,
      h * 0.50,
      w * 0.84,
      h * 0.74,
    );
    domePath.close();
    canvas.drawPath(domePath, fillPaint);

    // 3. Cloche Base Tray / Platter Rim
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.78),
        width: w * 0.76,
        height: h * 0.07,
      ),
      Radius.circular(w * 0.035),
    );
    canvas.drawRRect(baseRect, fillPaint);

    // 4. Smart Wi-Fi Signal Waves (Arches on Top)
    // Small inner arc
    final arc1 = Rect.fromCircle(center: Offset(w * 0.5, h * 0.42), radius: w * 0.14);
    canvas.drawArc(arc1, -3.14 * 0.82, 3.14 * 0.64, false, strokePaint);

    // Medium middle arc
    final arc2 = Rect.fromCircle(center: Offset(w * 0.5, h * 0.42), radius: w * 0.23);
    canvas.drawArc(arc2, -3.14 * 0.84, 3.14 * 0.68, false, strokePaint);

    // 5. Steam Wisps on the Right
    final steamPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.04;

    final steamPath1 = Path();
    steamPath1.moveTo(w * 0.84, h * 0.48);
    steamPath1.quadraticBezierTo(w * 0.88, h * 0.42, w * 0.85, h * 0.36);
    canvas.drawPath(steamPath1, steamPaint);

    final steamPath2 = Path();
    steamPath2.moveTo(w * 0.91, h * 0.52);
    steamPath2.quadraticBezierTo(w * 0.95, h * 0.46, w * 0.92, h * 0.40);
    canvas.drawPath(steamPath2, steamPaint);
  }

  @override
  bool shouldRepaint(covariant _SmartCanteenLogoPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
