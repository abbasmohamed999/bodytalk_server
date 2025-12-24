import 'dart:math' as math;
import 'package:flutter/material.dart';

enum BodyOverlayMode { front, side }

enum BodyPreset { slim, normal, heavy }

class BodyOverlaySpec {
  // Frame in screen space
  static const double frameWFrac = 0.90;
  static const double frameTopFrac = 0.15;
  static const double frameHFrac = 0.70;

  // Guide lines in frame space (0..1)
  static const double shouldersY = 0.15;
  static const double hipsY = 0.50;
  static const double feetY = 0.95;
  static const double centerX = 0.50;

  static const double guideOpacity = 0.55;

  static double presetScale(BodyPreset p) {
    switch (p) {
      case BodyPreset.slim:
        return 0.85;
      case BodyPreset.normal:
        return 1.00;
      case BodyPreset.heavy:
        return 1.18;
    }
  }
}

/// Simple guide lines overlay - NO silhouette, just positioning guides
class ProMeasurementOverlayPainter extends CustomPainter {
  ProMeasurementOverlayPainter({
    required this.mode,
    required this.preset,
    required this.isReady,
  });

  final BodyOverlayMode mode;
  final BodyPreset preset;
  final bool isReady;

  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.width;
    final sh = size.height;

    // Frame definition
    final frameTop = sh * BodyOverlaySpec.frameTopFrac;
    final frameH = sh * BodyOverlaySpec.frameHFrac;
    final frameW = sw * BodyOverlaySpec.frameWFrac;
    final frameLeft = (sw - frameW) / 2;
    final frameRect = Rect.fromLTWH(frameLeft, frameTop, frameW, frameH);

    // Guide line positions
    final shouldersY = frameTop + frameH * BodyOverlaySpec.shouldersY;
    final hipsY = frameTop + frameH * BodyOverlaySpec.hipsY;
    final feetY = frameTop + frameH * BodyOverlaySpec.feetY;
    final centerX = frameLeft + frameW * BodyOverlaySpec.centerX;

    // Guide lines paint
    final guidePaint = Paint()
      ..color = (isReady ? const Color(0xFF39D98A) : Colors.white)
          .withOpacity(BodyOverlaySpec.guideOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw horizontal guide lines (dashed)
    _drawDashedLine(
      canvas,
      Offset(frameLeft + 20, shouldersY),
      Offset(frameLeft + frameW - 20, shouldersY),
      guidePaint,
    );
    _drawDashedLine(
      canvas,
      Offset(frameLeft + 20, hipsY),
      Offset(frameLeft + frameW - 20, hipsY),
      guidePaint,
    );
    _drawDashedLine(
      canvas,
      Offset(frameLeft + 20, feetY),
      Offset(frameLeft + frameW - 20, feetY),
      guidePaint,
    );

    // Draw center vertical line (dashed)
    _drawDashedLine(
      canvas,
      Offset(centerX, frameTop + 20),
      Offset(centerX, frameTop + frameH - 20),
      guidePaint,
    );

    // Draw frame border (subtle)
    final frameBorderPaint = Paint()
      ..color =
          (isReady ? const Color(0xFF39D98A) : Colors.white).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(16)),
      frameBorderPaint,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint,
      {double dash = 12, double gap = 8}) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final steps = (dist / (dash + gap)).floor();
    final vx = dx / dist;
    final vy = dy / dist;

    var start = 0.0;
    for (var i = 0; i < steps; i++) {
      final p1 = Offset(a.dx + vx * start, a.dy + vy * start);
      final p2 = Offset(a.dx + vx * (start + dash), a.dy + vy * (start + dash));
      canvas.drawLine(p1, p2, paint);
      start += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant ProMeasurementOverlayPainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.preset != preset ||
        oldDelegate.isReady != isReady;
  }
}
