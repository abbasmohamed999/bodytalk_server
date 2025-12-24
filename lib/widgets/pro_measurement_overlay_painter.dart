import 'dart:math' as math;
import 'package:flutter/material.dart';

enum BodyOverlayMode { front, side }

enum BodyPreset { slim, normal, heavy }

class BodyOverlaySpec {
  // Frame in screen space - FULL SCREEN
  static const double frameWFrac = 0.95; // Almost full width
  static const double frameTopFrac = 0.12; // Start below status bar
  static const double frameHFrac = 0.75; // Leave room for bottom UI

  // Guide lines in frame space (0..1) - NON-NEGOTIABLE
  static const double shouldersY = 0.18;
  static const double hipsY = 0.48;
  static const double feetY = 0.95;
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
    final baseWidth = w * 0.22 * widthFactor;

    // Head center placed at ~0.08h, shoulders at 0.18h (matches guide line)
    final headCY = frame.top + 0.08 * h;
    final shouldersY = frame.top + BodyOverlaySpec.shouldersY * h;

    // Body proportions
    final shoulderHalf = baseWidth * 1.15;
    final armLength = h * 0.32; // Arms extend down
    final elbowY = shouldersY + armLength * 0.45;
    final wristY = shouldersY + armLength;
    final waistHalf = baseWidth * 0.72;
    final hipsHalf = baseWidth * 0.95;
    final thighHalf = baseWidth * 0.50;
    final kneeHalf = baseWidth * 0.35;
    final ankleHalf = baseWidth * 0.28;

    // Y landmarks
    final chestY = frame.top + 0.25 * h;
    final waistY = frame.top + 0.38 * h;
    final hipsY = frame.top + BodyOverlaySpec.hipsY * h;
    final thighY = frame.top + 0.58 * h;
    final kneesY = frame.top + 0.70 * h;
    final calfY = frame.top + 0.82 * h;
    final feetY = frame.top + BodyOverlaySpec.feetY * h;

    if (mode == BodyOverlayMode.front) {
      final p = Path();

      // Head (oval)
      final headR = 0.045 * h;
      p.addOval(Rect.fromCenter(
          center: Offset(cx, headCY),
          width: headR * 1.3,
          height: headR * 1.45));

      // ===== BODY WITH ARMS =====
      // Start from left arm (wrist)
      final leftWrist = Offset(cx - shoulderHalf - baseWidth * 0.35, wristY);
      final leftElbow = Offset(cx - shoulderHalf - baseWidth * 0.20, elbowY);
      final leftShoulder = Offset(cx - shoulderHalf, shouldersY);

      final rightWrist = Offset(cx + shoulderHalf + baseWidth * 0.35, wristY);
      final rightElbow = Offset(cx + shoulderHalf + baseWidth * 0.20, elbowY);
      final rightShoulder = Offset(cx + shoulderHalf, shouldersY);

      // Torso points
      final leftChest = Offset(cx - shoulderHalf * 0.88, chestY);
      final leftWaist = Offset(cx - waistHalf, waistY);
      final leftHips = Offset(cx - hipsHalf, hipsY);
      final leftThigh = Offset(cx - thighHalf, thighY);
      final leftKnee = Offset(cx - kneeHalf, kneesY);
      final leftCalf = Offset(cx - kneeHalf * 0.85, calfY);
      final leftAnkle = Offset(cx - ankleHalf, feetY);

      final rightChest = Offset(cx + shoulderHalf * 0.88, chestY);
      final rightWaist = Offset(cx + waistHalf, waistY);
      final rightHips = Offset(cx + hipsHalf, hipsY);
      final rightThigh = Offset(cx + thighHalf, thighY);
      final rightKnee = Offset(cx + kneeHalf, kneesY);
      final rightCalf = Offset(cx + kneeHalf * 0.85, calfY);
      final rightAnkle = Offset(cx + ankleHalf, feetY);

      // Start at left wrist (arm hanging down)
      p.moveTo(leftWrist.dx - baseWidth * 0.08, leftWrist.dy);

      // Left arm outer edge (wrist to elbow)
      p.cubicTo(
        leftWrist.dx - baseWidth * 0.10,
        leftWrist.dy - armLength * 0.15,
        leftElbow.dx - baseWidth * 0.12,
        elbowY + armLength * 0.10,
        leftElbow.dx - baseWidth * 0.10,
        elbowY,
      );

      // Left arm (elbow to shoulder)
      p.cubicTo(
        leftElbow.dx - baseWidth * 0.08,
        elbowY - armLength * 0.15,
        leftShoulder.dx - baseWidth * 0.05,
        shouldersY + 0.02 * h,
        leftShoulder.dx,
        shouldersY,
      );

      // Neck (left shoulder to head)
      p.lineTo(cx - shoulderHalf * 0.25, headCY + headR * 0.6);
      p.lineTo(cx + shoulderHalf * 0.25, headCY + headR * 0.6);

      // Right shoulder
      p.lineTo(rightShoulder.dx, shouldersY);

      // Right arm (shoulder to elbow)
      p.cubicTo(
        rightShoulder.dx + baseWidth * 0.05,
        shouldersY + 0.02 * h,
        rightElbow.dx + baseWidth * 0.08,
        elbowY - armLength * 0.15,
        rightElbow.dx + baseWidth * 0.10,
        elbowY,
      );

      // Right arm (elbow to wrist)
      p.cubicTo(
        rightElbow.dx + baseWidth * 0.12,
        elbowY + armLength * 0.10,
        rightWrist.dx + baseWidth * 0.10,
        rightWrist.dy - armLength * 0.15,
        rightWrist.dx + baseWidth * 0.08,
        rightWrist.dy,
      );

      // Right arm inner edge (wrist back up to armpit)
      p.cubicTo(
        rightWrist.dx,
        rightWrist.dy - armLength * 0.10,
        rightElbow.dx + baseWidth * 0.02,
        elbowY + armLength * 0.05,
        rightElbow.dx,
        elbowY,
      );
      p.cubicTo(
        rightElbow.dx - baseWidth * 0.02,
        elbowY - armLength * 0.10,
        rightChest.dx + baseWidth * 0.05,
        chestY - 0.02 * h,
        rightChest.dx,
        chestY,
      );

      // Right torso down
      p.cubicTo(
        rightChest.dx + baseWidth * 0.02,
        chestY + 0.04 * h,
        rightWaist.dx + baseWidth * 0.02,
        waistY - 0.03 * h,
        rightWaist.dx,
        rightWaist.dy,
      );
      p.cubicTo(
        rightWaist.dx + baseWidth * 0.02,
        waistY + 0.04 * h,
        rightHips.dx + baseWidth * 0.02,
        hipsY - 0.03 * h,
        rightHips.dx,
        rightHips.dy,
      );

      // Right leg
      p.cubicTo(
        rightHips.dx,
        hipsY + 0.03 * h,
        rightThigh.dx + baseWidth * 0.02,
        thighY - 0.02 * h,
        rightThigh.dx,
        rightThigh.dy,
      );
      p.cubicTo(
        rightThigh.dx,
        thighY + 0.04 * h,
        rightKnee.dx + baseWidth * 0.02,
        kneesY - 0.03 * h,
        rightKnee.dx,
        rightKnee.dy,
      );
      p.cubicTo(
        rightKnee.dx,
        kneesY + 0.04 * h,
        rightCalf.dx + baseWidth * 0.01,
        calfY - 0.02 * h,
        rightCalf.dx,
        rightCalf.dy,
      );
      p.cubicTo(
        rightCalf.dx,
        calfY + 0.04 * h,
        rightAnkle.dx + baseWidth * 0.01,
        feetY - 0.03 * h,
        rightAnkle.dx,
        rightAnkle.dy,
      );

      // Feet bottom (gap between legs)
      p.lineTo(cx + ankleHalf * 0.3, feetY);
      p.lineTo(cx - ankleHalf * 0.3, feetY);
      p.lineTo(leftAnkle.dx, feetY);

      // Left leg up
      p.cubicTo(
        leftAnkle.dx - baseWidth * 0.01,
        feetY - 0.03 * h,
        leftCalf.dx,
        calfY + 0.04 * h,
        leftCalf.dx,
        leftCalf.dy,
      );
      p.cubicTo(
        leftCalf.dx - baseWidth * 0.01,
        calfY - 0.02 * h,
        leftKnee.dx,
        kneesY + 0.04 * h,
        leftKnee.dx,
        leftKnee.dy,
      );
      p.cubicTo(
        leftKnee.dx - baseWidth * 0.02,
        kneesY - 0.03 * h,
        leftThigh.dx,
        thighY + 0.04 * h,
        leftThigh.dx,
        leftThigh.dy,
      );
      p.cubicTo(
        leftThigh.dx - baseWidth * 0.02,
        thighY - 0.02 * h,
        leftHips.dx,
        hipsY + 0.03 * h,
        leftHips.dx,
        leftHips.dy,
      );

      // Left torso up
      p.cubicTo(
        leftHips.dx - baseWidth * 0.02,
        hipsY - 0.03 * h,
        leftWaist.dx - baseWidth * 0.02,
        waistY + 0.04 * h,
        leftWaist.dx,
        leftWaist.dy,
      );
      p.cubicTo(
        leftWaist.dx - baseWidth * 0.02,
        waistY - 0.03 * h,
        leftChest.dx - baseWidth * 0.02,
        chestY + 0.04 * h,
        leftChest.dx,
        leftChest.dy,
      );

      // Left arm inner (chest to elbow)
      p.cubicTo(
        leftChest.dx - baseWidth * 0.05,
        chestY - 0.02 * h,
        leftElbow.dx + baseWidth * 0.02,
        elbowY - armLength * 0.10,
        leftElbow.dx,
        elbowY,
      );
      p.cubicTo(
        leftElbow.dx - baseWidth * 0.02,
        elbowY + armLength * 0.05,
        leftWrist.dx,
        leftWrist.dy - armLength * 0.10,
        leftWrist.dx - baseWidth * 0.08,
        leftWrist.dy,
      );

      p.close();
      return p;
    }

    // SIDE silhouette with arm
    final p = Path();

    // Head oval (profile marker)
    final headR = 0.045 * h;
    final headCX = frame.left + 0.52 * w;
    p.addOval(Rect.fromCenter(
        center: Offset(headCX, headCY),
        width: headR * 1.20,
        height: headR * 1.45));

    // Side body proportions
    final bodyDepth = baseWidth * 0.65; // Front-to-back thickness
    final backX = frame.left + 0.42 * w;
    final frontX = backX + bodyDepth;

    // Arm hanging down
    final armFrontX = frontX + baseWidth * 0.15;
    final armBackX = frontX - baseWidth * 0.05;
    final sideElbowY = shouldersY + armLength * 0.45;
    final sideWristY = shouldersY + armLength;

    final sideChestY = frame.top + 0.25 * h;
    final sideWaistY = frame.top + 0.38 * h;
    final sideHipsY = frame.top + BodyOverlaySpec.hipsY * h;
    final sideThighY = frame.top + 0.58 * h;
    final sideKneesY = frame.top + 0.70 * h;
    final sideCalfY = frame.top + 0.82 * h;
    final sideFeetY = frame.top + BodyOverlaySpec.feetY * h;

    // Belly/hip projection increases with preset
    final bellyProj = (preset == BodyPreset.heavy)
        ? baseWidth * 0.35
        : (preset == BodyPreset.normal ? baseWidth * 0.22 : baseWidth * 0.15);
    final chestProj =
        (preset == BodyPreset.heavy) ? baseWidth * 0.25 : baseWidth * 0.18;
    final buttProj = baseWidth * 0.20;

    // Start at back of head/neck
    p.moveTo(backX - baseWidth * 0.05, headCY + headR * 0.5);

    // Back of neck to shoulder
    p.cubicTo(
      backX - baseWidth * 0.08,
      shouldersY - 0.02 * h,
      backX - buttProj * 0.3,
      shouldersY,
      backX,
      shouldersY,
    );

    // Back contour (shoulder -> butt -> legs)
    p.cubicTo(
      backX - buttProj * 0.2,
      shouldersY + 0.08 * h,
      backX - buttProj * 0.5,
      sideWaistY,
      backX - buttProj * 0.3,
      sideHipsY,
    );
    p.cubicTo(
      backX - buttProj * 0.4,
      sideHipsY + 0.05 * h,
      backX - baseWidth * 0.15,
      sideThighY,
      backX - baseWidth * 0.08,
      sideKneesY,
    );
    p.cubicTo(
      backX - baseWidth * 0.05,
      sideCalfY,
      backX - baseWidth * 0.02,
      sideFeetY - 0.03 * h,
      backX,
      sideFeetY,
    );

    // Feet
    p.lineTo(frontX, sideFeetY);

    // Front leg contour up
    p.cubicTo(
      frontX + baseWidth * 0.02,
      sideFeetY - 0.03 * h,
      frontX + baseWidth * 0.05,
      sideCalfY,
      frontX + baseWidth * 0.08,
      sideKneesY,
    );
    p.cubicTo(
      frontX + baseWidth * 0.10,
      sideThighY,
      frontX + bellyProj * 0.8,
      sideHipsY + 0.03 * h,
      frontX + bellyProj,
      sideHipsY,
    );

    // Belly to chest
    p.cubicTo(
      frontX + bellyProj * 1.1,
      sideWaistY + 0.02 * h,
      frontX + chestProj * 0.9,
      sideWaistY - 0.02 * h,
      frontX + chestProj,
      sideChestY,
    );

    // Chest to arm (front of arm starts here)
    p.cubicTo(
      frontX + chestProj,
      sideChestY - 0.03 * h,
      armFrontX,
      shouldersY + 0.02 * h,
      armFrontX,
      shouldersY + 0.04 * h,
    );

    // Arm front contour down to wrist
    p.cubicTo(
      armFrontX + baseWidth * 0.03,
      sideElbowY - 0.03 * h,
      armFrontX + baseWidth * 0.05,
      sideElbowY,
      armFrontX + baseWidth * 0.03,
      sideElbowY + 0.02 * h,
    );
    p.cubicTo(
      armFrontX + baseWidth * 0.02,
      sideWristY - 0.05 * h,
      armFrontX,
      sideWristY - 0.02 * h,
      armFrontX - baseWidth * 0.02,
      sideWristY,
    );

    // Arm back contour up
    p.cubicTo(
      armBackX - baseWidth * 0.02,
      sideWristY - 0.02 * h,
      armBackX - baseWidth * 0.03,
      sideElbowY + 0.05 * h,
      armBackX,
      sideElbowY,
    );
    p.cubicTo(
      armBackX + baseWidth * 0.02,
      sideElbowY - 0.05 * h,
      armBackX,
      shouldersY + 0.05 * h,
      frontX + chestProj * 0.5,
      shouldersY,
    );

    // Shoulder to front of neck/head
    p.cubicTo(
      frontX + chestProj * 0.3,
      shouldersY - 0.02 * h,
      headCX + headR * 0.3,
      headCY + headR * 0.8,
      headCX + headR * 0.2,
      headCY + headR * 0.5,
    );

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
