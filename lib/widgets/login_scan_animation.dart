// Scanning animation widget
import 'package:flutter/material.dart';

class LoginScanAnimation extends StatefulWidget {
  const LoginScanAnimation({super.key});

  @override
  State<LoginScanAnimation> createState() => _LoginScanAnimationState();
}

class _LoginScanAnimationState extends State<LoginScanAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(painter: _ScanPainter(_animation.value));
      },
    );
  }
}

class _ScanPainter extends CustomPainter {
  final double progress;

  _ScanPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.withValues(alpha: 0.0),
          Colors.blue.withValues(alpha: 0.5),
          Colors.blue.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, progress * size.height - 30, size.width, 60));

    canvas.drawRect(Rect.fromLTWH(0, progress * size.height - 30, size.width, 60), paint);
  }

  @override
  bool shouldRepaint(covariant _ScanPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
