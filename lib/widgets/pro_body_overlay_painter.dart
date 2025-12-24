import 'dart:math';
import 'package:flutter/material.dart';

enum BodyOverlayMode { front, side }

enum BodyPreset { slim, normal, heavy }

class ProBodyOverlayPainter extends CustomPainter {
  ProBodyOverlayPainter({
    required this.mode,
    required this.preset,
    required this.isReady,
    this.dimOpacity = 0.16, // أعلى شفافية = يرى المستخدم نفسه
    this.strokeOpacity = 0.75,
  });

  final BodyOverlayMode mode;
  final BodyPreset preset;
  final bool isReady;

  /// Dim layer opacity (0.14 - 0.20 recommended)
  final double dimOpacity;

  /// Silhouette stroke opacity
  final double strokeOpacity;

  // Guide lines positions (relative to frame height)
  static const double kShouldersY = 0.23;
  static const double kHipsY = 0.52;
  static const double kFeetY = 0.92;

  // Frame size ratios (central measurement frame)
  static const double kFrameWidthRatio = 0.72;
  static const double kFrameHeightRatio = 0.78;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Measurement frame rect
    final frameW = size.width * kFrameWidthRatio;
    final frameH = size.height * kFrameHeightRatio;
    final frameRect =
        Rect.fromCenter(center: center, width: frameW, height: frameH);

    // --- Background dim layer with a "cutout" silhouette window ---
    final dimPaint = Paint()
      ..color = Colors.black.withOpacity(dimOpacity)
      ..style = PaintingStyle.fill;

    final overlayPath = Path()..addRect(Offset.zero & size);

    // Build silhouette cutout path (human-shaped window)
    final cutout = (mode == BodyOverlayMode.front)
        ? _buildFrontSilhouette(frameRect, preset)
        : _buildSideSilhouette(frameRect, preset);

    // Cut out silhouette from dim layer
    final combined =
        Path.combine(PathOperation.difference, overlayPath, cutout);
    canvas.drawPath(combined, dimPaint);

    // --- Frame border (subtle) ---
    final framePaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rrect = RRect.fromRectAndRadius(frameRect, const Radius.circular(28));
    canvas.drawRRect(rrect, framePaint);

    // --- Silhouette outline (ready => green tint) ---
    final outlineColor = isReady ? const Color(0xFF39D98A) : Colors.white;
    final outlinePaint = Paint()
      ..color = outlineColor.withOpacity(strokeOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(cutout, outlinePaint);

    // --- Measurement guide lines (correct positions) ---
    _drawGuides(canvas, frameRect, isReady);
  }

  void _drawGuides(Canvas canvas, Rect frame, bool ready) {
    final guideColor = ready ? const Color(0xFF39D98A) : Colors.white;
    final dashPaint = Paint()
      ..color = guideColor.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Horizontal dashed lines
    final yShoulders = frame.top + frame.height * kShouldersY;
    final yHips = frame.top + frame.height * kHipsY;
    final yFeet = frame.top + frame.height * kFeetY;

    _dashedLine(canvas, Offset(frame.left + 14, yShoulders),
        Offset(frame.right - 14, yShoulders), dashPaint);
    _dashedLine(canvas, Offset(frame.left + 14, yHips),
        Offset(frame.right - 14, yHips), dashPaint);
    _dashedLine(canvas, Offset(frame.left + 14, yFeet),
        Offset(frame.right - 14, yFeet), dashPaint);

    // Vertical center dashed line
    final xCenter = frame.left + frame.width * 0.50;
    _dashedLine(canvas, Offset(xCenter, frame.top + 14),
        Offset(xCenter, frame.bottom - 14), dashPaint);

    // Optional tiny labels can be added by the page UI (NOT inside painter).
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint,
      {double dash = 10, double gap = 8}) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final dist = sqrt(dx * dx + dy * dy);
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

  /// Body width tuning by preset (only affects silhouette width proportions)
  double _widthFactor(BodyPreset p) {
    switch (p) {
      case BodyPreset.slim:
        return 0.86;
      case BodyPreset.normal:
        return 1.00;
      case BodyPreset.heavy:
        return 1.16;
    }
  }

  Path _buildFrontSilhouette(Rect frame, BodyPreset preset) {
    final wf = _widthFactor(preset);

    // Key Y positions (relative)
    final headTop = frame.top + frame.height * 0.06;
    final headR = frame.width * 0.08; // head circle size
    final neckY = frame.top + frame.height * 0.16;
    final shouldersY = frame.top + frame.height * kShouldersY;
    final waistY = frame.top + frame.height * 0.44;
    final hipsY = frame.top + frame.height * kHipsY;
    final kneesY = frame.top + frame.height * 0.74;
    final feetY = frame.top + frame.height * 0.95;

    final cx = frame.center.dx;

    // Half-widths
    final shoulderHW = frame.width * 0.30 * wf;
    final chestHW = frame.width * 0.26 * wf;
    final waistHW = frame.width * 0.20 * wf;
    final hipHW = frame.width * 0.24 * wf;
    final kneeHW = frame.width * 0.16 * wf;
    final ankleHW = frame.width * 0.14 * wf;

    final p = Path();

    // Head (privacy: you can remove this circle if you want)
    p.addOval(
        Rect.fromCircle(center: Offset(cx, headTop + headR), radius: headR));

    // Torso + legs outline (single continuous shape)
    final left = Path();
    left.moveTo(cx - headR * 0.55, neckY);
    left.cubicTo(cx - headR * 1.4, neckY + 8, cx - shoulderHW, shouldersY - 6,
        cx - shoulderHW, shouldersY);
    left.cubicTo(cx - chestHW, shouldersY + 28, cx - waistHW, waistY - 10,
        cx - waistHW, waistY);
    left.cubicTo(
        cx - waistHW, waistY + 14, cx - hipHW, hipsY - 10, cx - hipHW, hipsY);
    left.cubicTo(
        cx - hipHW, hipsY + 40, cx - kneeHW, kneesY - 8, cx - kneeHW, kneesY);
    left.cubicTo(cx - kneeHW, kneesY + 34, cx - ankleHW, feetY - 18,
        cx - ankleHW, feetY);

    final right = Path();
    right.moveTo(cx + headR * 0.55, neckY);
    right.cubicTo(cx + headR * 1.4, neckY + 8, cx + shoulderHW, shouldersY - 6,
        cx + shoulderHW, shouldersY);
    right.cubicTo(cx + chestHW, shouldersY + 28, cx + waistHW, waistY - 10,
        cx + waistHW, waistY);
    right.cubicTo(
        cx + waistHW, waistY + 14, cx + hipHW, hipsY - 10, cx + hipHW, hipsY);
    right.cubicTo(
        cx + hipHW, hipsY + 40, cx + kneeHW, kneesY - 8, cx + kneeHW, kneesY);
    right.cubicTo(cx + kneeHW, kneesY + 34, cx + ankleHW, feetY - 18,
        cx + ankleHW, feetY);

    // Build a closed cutout by connecting left->feet->right->neck
    final body = Path();
    body.addPath(left, Offset.zero);
    body.lineTo(cx, feetY); // small join
    body.addPath(right, Offset.zero);

    // Close around neck
    body.close();

    // Merge head + body
    return Path.combine(PathOperation.union, p, body);
  }

  Path _buildSideSilhouette(Rect frame, BodyPreset preset) {
    final wf = _widthFactor(preset);

    final headTop = frame.top + frame.height * 0.06;
    final headR = frame.width * 0.075;
    final neckY = frame.top + frame.height * 0.17;
    final shouldersY = frame.top + frame.height * kShouldersY;
    final chestY = frame.top + frame.height * 0.33;
    final bellyY = frame.top + frame.height * 0.48;
    final hipsY = frame.top + frame.height * kHipsY;
    final kneesY = frame.top + frame.height * 0.75;
    final feetY = frame.top + frame.height * 0.95;

    final cx = frame.center.dx;

    // Side profile widths (front/back)
    final shoulderFront = frame.width * 0.10 * wf;
    final back = frame.width * 0.16 * wf;
    final belly = frame.width * 0.18 * wf; // increases with heavy preset
    final hip = frame.width * 0.15 * wf;
    final knee = frame.width * 0.10 * wf;
    final ankle = frame.width * 0.09 * wf;

    // Shift silhouette slightly to look like a side stance
    final x = cx - frame.width * 0.05;

    final head = Path()
      ..addOval(
          Rect.fromCircle(center: Offset(x, headTop + headR), radius: headR));

    final side = Path();
    // Start at neck (back)
    side.moveTo(x - back, neckY);

    // Back curve down to hips
    side.cubicTo(x - back * 1.05, shouldersY + 10, x - back * 0.95, hipsY - 10,
        x - back * 0.90, hipsY);

    // Back down to ankle
    side.cubicTo(x - back * 0.85, hipsY + 70, x - knee * 0.90, kneesY + 10,
        x - ankle, feetY);

    // Foot (tiny forward)
    side.lineTo(x + ankle * 0.8, feetY);

    // Front leg up to knee
    side.cubicTo(
        x + ankle * 0.9, feetY - 30, x + knee, kneesY + 8, x + knee, kneesY);

    // Front body to hips & belly
    final bellyOut = belly; // preset affects this
    side.cubicTo(
        x + hip, hipsY + 10, x + bellyOut, bellyY + 12, x + bellyOut, bellyY);

    // Chest to shoulders
    side.cubicTo(x + bellyOut * 0.85, chestY, x + shoulderFront, shouldersY,
        x + shoulderFront, shouldersY);

    // Back to neck
    side.cubicTo(x + shoulderFront * 0.70, shouldersY - 18, x + headR * 0.5,
        neckY + 6, x + headR * 0.3, neckY);

    side.close();

    return Path.combine(PathOperation.union, head, side);
  }

  @override
  bool shouldRepaint(covariant ProBodyOverlayPainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.preset != preset ||
        oldDelegate.isReady != isReady ||
        oldDelegate.dimOpacity != dimOpacity ||
        oldDelegate.strokeOpacity != strokeOpacity;
  }
}
