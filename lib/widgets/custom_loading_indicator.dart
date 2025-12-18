import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Özel animasyonlu loading indicator
/// CircularProgressIndicator yerine kullanılır
class CustomLoadingIndicator extends StatefulWidget {
  final double? size;
  final Color? color;
  final double? strokeWidth;

  const CustomLoadingIndicator({
    super.key,
    this.size,
    this.color,
    this.strokeWidth,
  });

  @override
  State<CustomLoadingIndicator> createState() => _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? 40.0;
    final color = widget.color ?? Colors.black;
    final strokeWidth = widget.strokeWidth ?? 3.0;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _LoadingPainter(
              progress: _controller.value,
              color: color,
              strokeWidth: strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

class _LoadingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _LoadingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - strokeWidth / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Ana dönen çizgi
    final startAngle = -math.pi / 2 + (progress * 2 * math.pi);
    final sweepAngle = math.pi * 0.75; // 270 derece

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    // İkinci çizgi (daha kısa ve daha şeffaf)
    final secondPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = strokeWidth * 0.7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final secondStartAngle = startAngle + sweepAngle;
    final secondSweepAngle = math.pi * 0.5; // 90 derece

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      secondStartAngle,
      secondSweepAngle,
      false,
      secondPaint,
    );
  }

  @override
  bool shouldRepaint(_LoadingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

