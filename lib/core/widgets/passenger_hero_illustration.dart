import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Lightweight decorative travel illustration created using Flutter CustomPainter.
/// Represents a curved intercity road, destination map pins, and subtle travel motion.
class PassengerHeroIllustration extends StatelessWidget {
  final double width;
  final double height;
  final Color primaryColor;
  final Color accentColor;

  const PassengerHeroIllustration({
    super.key,
    this.width = 160,
    this.height = 120,
    this.primaryColor = Colors.white,
    this.accentColor = const Color(0xFFF5A623),
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _TravelPathPainter(
            primaryColor: primaryColor,
            accentColor: accentColor,
          ),
          child: Stack(
            children: [
              // Subtle Pin 1 (Origin)
              Positioned(
                left: width * 0.15,
                top: height * 0.55,
                child: Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: primaryColor.withValues(alpha: 0.8),
                ),
              ),
              // Pin 2 (Destination)
              Positioned(
                right: width * 0.12,
                top: height * 0.15,
                child: Icon(
                  Icons.place_rounded,
                  size: 20,
                  color: accentColor,
                ),
              ),
              // Vehicle silhouette along the path
              Positioned(
                left: width * 0.48,
                top: height * 0.32,
                child: Transform.rotate(
                  angle: -math.pi / 10,
                  child: Icon(
                    Icons.directions_car_filled_rounded,
                    size: 22,
                    color: primaryColor.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TravelPathPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  _TravelPathPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw curved highway road
    final roadPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.75);
    path.cubicTo(
      size.width * 0.35,
      size.height * 0.85,
      size.width * 0.45,
      size.height * 0.35,
      size.width * 0.88,
      size.height * 0.28,
    );

    canvas.drawPath(path, roadPaint);

    // Draw secondary dashed decorative route
    final dashedPath = Path();
    dashedPath.moveTo(size.width * 0.2, size.height * 0.72);
    dashedPath.cubicTo(
      size.width * 0.38,
      size.height * 0.8,
      size.width * 0.47,
      size.height * 0.38,
      size.width * 0.82,
      size.height * 0.3,
    );
    canvas.drawPath(dashedPath, dashPaint);

    // Subtle route pulse circles
    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.28),
      6.0,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TravelPathPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}
