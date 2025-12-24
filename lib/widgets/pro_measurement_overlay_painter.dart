import 'dart:math' as math;
import 'package:flutter/material.dart';

enum BodyOverlayMode { front, side }

enum BodyPreset { slim, normal, heavy }

class BodyOverlaySpec {
  // Frame in screen space
  static const double frameWFrac = 0.72;
  static const double frameTopFrac = 0.10; // Frame starts at 10% from top
  static const double frameHFrac = 0.78;

  // Guide lines in frame space (0..1) - NON-NEGOTIABLE
  static const double shouldersY = 0.23;
  static const double hipsY = 0.52;
  static const double feetY = 0.92;
  static const double centerX = 0.50;

  static const double dimOpacity = 0.16;
  static const double outlineOpacity = 0.75;
  static const double guideOpacity = 0.65;

  // Width scaling ONLY
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

    // Frame definition (NON-NEGOTIABLE)
    final frameTop = sh * 0.10;
    final frameH = sh * BodyOverlaySpec.frameHFrac;
    final frameBottom = frameTop + frameH;
    final frameW = sw * BodyOverlaySpec.frameWFrac;
    final frameLeft = (sw - frameW) / 2;
    final frameRect = Rect.fromLTWH(frameLeft, frameTop, frameW, frameH);

    // Background dim layer
    final dimPaint = Paint()
      ..color = Colors.black.withOpacity(BodyOverlaySpec.dimOpacity)
      ..style = PaintingStyle.fill;

    // Silhouette cutout path (in screen coords)
    final cutout = _buildSilhouettePath(frameRect, mode, preset);

    // Dim everywhere EXCEPT silhouette window
    final full = Path()..addRect(Rect.fromLTWH(0, 0, sw, sh));
    final overlay = Path.combine(PathOperation.difference, full, cutout);
    canvas.drawPath(overlay, dimPaint);

    // Frame subtle border (optional)
    final frameBorder = Paint()
      ..color = Colors.white.withOpacity(0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(18)),
      frameBorder,
    );

    // Silhouette outline
    final outlinePaint = Paint()
      ..color = (isReady ? const Color(0xFF39D98A) : Colors.white)
          .withOpacity(BodyOverlaySpec.outlineOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(cutout, outlinePaint);

    // Guide lines (dashed) - Fixed positions (NON-NEGOTIABLE)
    final guidePaint = Paint()
      ..color = Colors.white.withOpacity(BodyOverlaySpec.guideOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final shouldersY = frameTop + frameH * BodyOverlaySpec.shouldersY;
    final hipsY = frameTop + frameH * BodyOverlaySpec.hipsY;
    final feetY = frameTop + frameH * BodyOverlaySpec.feetY;
    final centerX = frameLeft + frameW * BodyOverlaySpec.centerX;

    _drawDashedLine(
      canvas,
      Offset(frameLeft + 16, shouldersY),
      Offset(frameLeft + frameW - 16, shouldersY),
      guidePaint,
    );
    _drawDashedLine(
      canvas,
      Offset(frameLeft + 16, hipsY),
      Offset(frameLeft + frameW - 16, hipsY),
      guidePaint,
    );
    _drawDashedLine(
      canvas,
      Offset(frameLeft + 16, feetY),
      Offset(frameLeft + frameW - 16, feetY),
      guidePaint,
    );
    _drawDashedLine(
      canvas,
      Offset(centerX, frameTop + 16),
      Offset(centerX, frameBottom - 16),
      guidePaint,
    );
  }

  Path _buildSilhouettePath(
      Rect frame, BodyOverlayMode mode, BodyPreset preset) {
    final w = frame.width;
    final h = frame.height;
    final cx = frame.center.dx;

    // Width scaling ONLY (NON-NEGOTIABLE)
    final widthFactor = BodyOverlaySpec.presetScale(preset);
    final halfWidth = w * 0.25 * widthFactor;

    // We intentionally do NOT require face; head is just a neutral oval marker.
    // Head center placed at ~0.12h, shoulders at 0.23h (matches guide line)
    final headCY = frame.top + 0.12 * h;
    final shouldersY = frame.top + BodyOverlaySpec.shouldersY * h;

    // Base widths (in frame coords), then scaled
    final shoulderHalf = halfWidth * 1.1; // slightly wider at shoulders
    final waistHalf = halfWidth * 0.75;
    final hipsHalf = halfWidth * 0.95;
    final ankleHalf = halfWidth * 0.40;

    // Y landmarks
    final chestY = frame.top + 0.30 * h;
    final waistY = frame.top + 0.42 * h;
    final hipsY = frame.top + BodyOverlaySpec.hipsY * h;
    final kneesY = frame.top + 0.73 * h;
    final feetY = frame.top + BodyOverlaySpec.feetY * h;

    if (mode == BodyOverlayMode.front) {
      final p = Path();

      // Head (oval) - neutral marker, not "face"
      final headR = 0.055 * h;
      p.addOval(Rect.fromCenter(
          center: Offset(cx, headCY),
          width: headR * 1.2,
          height: headR * 1.35));

      // Body outline: build as one continuous path (left side down, then right side up)
      final leftShoulder = Offset(cx - shoulderHalf, shouldersY);
      final rightShoulder = Offset(cx + shoulderHalf, shouldersY);

      final leftChest = Offset(cx - (shoulderHalf * 0.92), chestY);
      final leftWaist = Offset(cx - waistHalf, waistY);
      final leftHips = Offset(cx - hipsHalf, hipsY);
      final leftKnees = Offset(cx - (hipsHalf * 0.55), kneesY);
      final leftAnkles = Offset(cx - ankleHalf, feetY);

      final rightChest = Offset(cx + (shoulderHalf * 0.92), chestY);
      final rightWaist = Offset(cx + waistHalf, waistY);
      final rightHips = Offset(cx + hipsHalf, hipsY);
      final rightKnees = Offset(cx + (hipsHalf * 0.55), kneesY);
      final rightAnkles = Offset(cx + ankleHalf, feetY);

      // Start at left shoulder
      p.moveTo(leftShoulder.dx, leftShoulder.dy);

      // Left shoulder -> chest (smooth)
      p.cubicTo(
        cx - shoulderHalf,
        shouldersY + 0.02 * h,
        leftChest.dx,
        leftChest.dy - 0.03 * h,
        leftChest.dx,
        leftChest.dy,
      );

      // Chest -> waist
      p.cubicTo(
        leftChest.dx - 0.02 * w,
        chestY + 0.06 * h,
        leftWaist.dx - 0.02 * w,
        waistY - 0.05 * h,
        leftWaist.dx,
        leftWaist.dy,
      );

      // Waist -> hips
      p.cubicTo(
        leftWaist.dx - 0.01 * w,
        waistY + 0.05 * h,
        leftHips.dx - 0.02 * w,
        hipsY - 0.04 * h,
        leftHips.dx,
        leftHips.dy,
      );

      // Hips -> knees
      p.cubicTo(
        leftHips.dx - 0.01 * w,
        hipsY + 0.08 * h,
        leftKnees.dx - 0.02 * w,
        kneesY - 0.06 * h,
        leftKnees.dx,
        leftKnees.dy,
      );

      // Knees -> ankles/feet
      p.cubicTo(
        leftKnees.dx,
        kneesY + 0.10 * h,
        leftAnkles.dx - 0.01 * w,
        feetY - 0.06 * h,
        leftAnkles.dx,
        leftAnkles.dy,
      );

      // Bottom cross (feet)
      p.lineTo(rightAnkles.dx, rightAnkles.dy);

      // Right side up (ankles -> knees)
      p.cubicTo(
        rightAnkles.dx + 0.01 * w,
        feetY - 0.06 * h,
        rightKnees.dx,
        kneesY + 0.10 * h,
        rightKnees.dx,
        rightKnees.dy,
      );

      // Knees -> hips
      p.cubicTo(
        rightKnees.dx + 0.02 * w,
        kneesY - 0.06 * h,
        rightHips.dx + 0.01 * w,
        hipsY + 0.08 * h,
        rightHips.dx,
        rightHips.dy,
      );

      // Hips -> waist
      p.cubicTo(
        rightHips.dx + 0.02 * w,
        hipsY - 0.04 * h,
        rightWaist.dx + 0.01 * w,
        waistY + 0.05 * h,
        rightWaist.dx,
        rightWaist.dy,
      );

      // Waist -> chest
      p.cubicTo(
        rightWaist.dx + 0.02 * w,
        waistY - 0.05 * h,
        rightChest.dx + 0.02 * w,
        chestY + 0.06 * h,
        rightChest.dx,
        rightChest.dy,
      );

      // Chest -> right shoulder
      p.cubicTo(
        rightChest.dx,
        rightChest.dy - 0.03 * h,
        cx + shoulderHalf,
        shouldersY + 0.02 * h,
        rightShoulder.dx,
        rightShoulder.dy,
      );

      // Close across neck area (not needed to be anatomically perfect)
      // Connect shoulder to top near head
      p.lineTo(cx + shoulderHalf * 0.20, headCY + 0.03 * h);
      p.lineTo(cx - shoulderHalf * 0.20, headCY + 0.03 * h);
      p.close();

      return p;
    }

    // SIDE silhouette
    final p = Path();

    // Head oval (profile marker)
    final headR = 0.055 * h;
    final headCX = frame.left + 0.54 * w;
    p.addOval(Rect.fromCenter(
        center: Offset(headCX, headCY),
        width: headR * 1.15,
        height: headR * 1.35));

    // Side body: one contour (back) + one contour (front)
    final backX = frame.left + 0.46 * w;
    final frontXBase = frame.left + 0.60 * w;

    final sideChestY = frame.top + 0.30 * h;
    final sideWaistY = frame.top + 0.44 * h;
    final sideHipsY = frame.top + BodyOverlaySpec.hipsY * h;
    final sideKneesY = frame.top + 0.73 * h;
    final sideFeetY = frame.top + BodyOverlaySpec.feetY * h;

    // Belly/hip projection increases with preset
    final belly = (preset == BodyPreset.heavy)
        ? 0.08 * w
        : (preset == BodyPreset.normal ? 0.05 * w : 0.03 * w);
    final chest = (preset == BodyPreset.heavy) ? 0.06 * w : 0.045 * w;

    final frontShoulder = Offset(frontXBase + chest, shouldersY);
    final frontChest = Offset(frontXBase + chest, sideChestY);
    final frontWaist = Offset(frontXBase + belly, sideWaistY);
    final frontHips = Offset(frontXBase + belly, sideHipsY);
    final frontKnees = Offset(frontXBase + 0.02 * w, sideKneesY);
    final frontFeet = Offset(frontXBase + 0.02 * w, sideFeetY);

    final backShoulder = Offset(backX, shouldersY);
    final backHips = Offset(backX, sideHipsY);
    final backKnees = Offset(backX + 0.01 * w, sideKneesY);
    final backFeet = Offset(backX + 0.01 * w, sideFeetY);

    // Start at back shoulder
    p.moveTo(backShoulder.dx, backShoulder.dy);

    // Back contour down
    p.cubicTo(
      backX - 0.01 * w,
      shouldersY + 0.10 * h,
      backX - 0.01 * w,
      sideHipsY - 0.08 * h,
      backHips.dx,
      backHips.dy,
    );
    p.cubicTo(
      backHips.dx,
      sideHipsY + 0.10 * h,
      backKnees.dx - 0.01 * w,
      sideKneesY - 0.06 * h,
      backKnees.dx,
      backKnees.dy,
    );
    p.cubicTo(
      backKnees.dx,
      sideKneesY + 0.10 * h,
      backFeet.dx - 0.01 * w,
      sideFeetY - 0.06 * h,
      backFeet.dx,
      backFeet.dy,
    );

    // Feet bottom
    p.lineTo(frontFeet.dx, frontFeet.dy);

    // Front contour up (shin -> belly -> chest -> shoulder)
    p.cubicTo(
      frontFeet.dx + 0.01 * w,
      sideFeetY - 0.06 * h,
      frontKnees.dx + 0.01 * w,
      sideKneesY + 0.10 * h,
      frontKnees.dx,
      frontKnees.dy,
    );
    p.cubicTo(
      frontKnees.dx + 0.01 * w,
      sideKneesY - 0.04 * h,
      frontHips.dx + 0.01 * w,
      sideHipsY + 0.08 * h,
      frontHips.dx,
      frontHips.dy,
    );
    p.cubicTo(
      frontHips.dx + 0.01 * w,
      sideHipsY - 0.03 * h,
      frontWaist.dx + 0.01 * w,
      sideWaistY + 0.04 * h,
      frontWaist.dx,
      frontWaist.dy,
    );
    p.cubicTo(
      frontWaist.dx + 0.01 * w,
      sideWaistY - 0.06 * h,
      frontChest.dx + 0.01 * w,
      sideChestY + 0.05 * h,
      frontChest.dx,
      frontChest.dy,
    );
    p.cubicTo(
      frontChest.dx,
      sideChestY - 0.04 * h,
      frontShoulder.dx,
      shouldersY + 0.04 * h,
      frontShoulder.dx,
      frontShoulder.dy,
    );

    // Close via neck area
    p.lineTo(headCX + headR * 0.15, headCY + 0.04 * h);
    p.lineTo(headCX - headR * 0.50, headCY + 0.02 * h);
    p.close();

    return p;
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint,
      {double dash = 10, double gap = 8}) {
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
