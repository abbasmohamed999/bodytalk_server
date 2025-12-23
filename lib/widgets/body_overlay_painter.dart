// lib/widgets/body_overlay_painter.dart
// Professional Camera Overlay with Body Shape Presets
// Provides measurement frame for consistent body analysis

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

enum BodyOverlayMode { front, side }

enum BodyShapePreset { slim, normal, heavy }

class BodyOverlayPainter extends CustomPainter {
  final BodyOverlayMode mode;
  final BodyShapePreset preset;

  /// 0..1 (كلما أقل زادت الشفافية/خفّت الطبقة)
  final double dimOpacity;

  /// لون حدود السيلويت
  final Color outlineColor;

  /// لون تعبئة داخل السيلويت (شفاف)
  final Color fillColor;

  /// لون خطوط القياس
  final Color guideLineColor;

  /// لإظهار حالة "جاهز" بالأخضر
  final bool isReady;

  BodyOverlayPainter({
    required this.mode,
    required this.preset,
    this.dimOpacity = 0.25, // زِد الشفافية: 0.20-0.30 مناسب
    this.outlineColor = const Color(0xFFFFFFFF),
    this.fillColor = const Color(0x33FFFFFF), // تعبئة شفافة
    this.guideLineColor = const Color(0x99FFFFFF),
    this.isReady = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // طبقة تعتيم خفيفة فوق الكاميرا حتى يظهر السيلويت
    final dimPaint = Paint()
      ..color = Colors.black.withOpacity(dimOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, dimPaint);

    // مستطيل الإطار الأساسي (مكان الوقوف)
    final frameRect = _computeFrameRect(size);

    // رسم إطار خارجي ناعم (اختياري)
    final framePaint = Paint()
      ..color = (isReady ? Colors.greenAccent : Colors.white).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(18)),
      framePaint,
    );

    // رسم السيلويت (نحيف/بدين) داخل نفس frameRect
    final silhouettePath = (mode == BodyOverlayMode.front)
        ? _frontSilhouettePath(frameRect, preset)
        : _sideSilhouettePath(frameRect, preset);

    // تعبئة داخلية شفافة للسيلويت (لتوضيح الجسم)
    final fillPaint = Paint()
      ..color = fillColor.withOpacity(isReady ? 0.28 : 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawPath(silhouettePath, fillPaint);

    // حدود السيلويت
    final outlinePaint = Paint()
      ..color = (isReady ? Colors.greenAccent : outlineColor).withOpacity(0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(silhouettePath, outlinePaint);

    // خطوط قياس صحيحة: كتفين / وركين / قدمين
    _drawGuides(canvas, frameRect, size);
  }

  Rect _computeFrameRect(Size size) {
    // إطار مركزي مناسب لمعظم الشاشات
    final w = size.width * 0.62;
    final h = size.height * 0.62;

    final left = (size.width - w) / 2;
    final top = size.height * 0.22; // تحت شريط العنوان
    return Rect.fromLTWH(left, top, w, h);
  }

  void _drawGuides(Canvas canvas, Rect frameRect, Size size) {
    // نسب صحيحة داخل إطار الجسم:
    // - shoulders: أعلى الصدر تحت الرأس مباشرة
    // - hips: منتصف/أسفل الجذع
    // - feet: قرب أسفل الإطار
    final shouldersY = frameRect.top + frameRect.height * 0.18;
    final hipsY = frameRect.top + frameRect.height * 0.52;
    final feetY = frameRect.top + frameRect.height * 0.92;

    final paint = Paint()
      ..color = guideLineColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // خطوط متقطعة
    _drawDashedLine(canvas, Offset(frameRect.left, shouldersY),
        Offset(frameRect.right, shouldersY), paint);
    _drawDashedLine(canvas, Offset(frameRect.left, hipsY),
        Offset(frameRect.right, hipsY), paint);
    _drawDashedLine(canvas, Offset(frameRect.left, feetY),
        Offset(frameRect.right, feetY), paint);

    // (اختياري) خط منتصف لتثبيت الوقفة
    final midX = frameRect.center.dx;
    _drawDashedLine(
        canvas,
        Offset(midX, frameRect.top),
        Offset(midX, frameRect.bottom),
        paint..color = paint.color.withOpacity(0.35));
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dash = 10,
    double gap = 8,
  }) {
    final total = (end - start).distance;
    final dir = (end - start) / total;

    double dist = 0;
    while (dist < total) {
      final a = start + dir * dist;
      final b = start + dir * (dist + dash).clamp(0, total);
      canvas.drawLine(a, b, paint);
      dist += dash + gap;
    }
  }

  // ========= Silhouette Paths =========

  Path _frontSilhouettePath(Rect r, BodyShapePreset preset) {
    // إعدادات عرض حسب الجسم
    // كلما heavy أكبر، زاد عرض الصدر/البطن/الورك
    final s = _shapeScale(preset);

    final cx = r.center.dx;
    final top = r.top;
    final bottom = r.bottom;

    // مراكز Y المهمة
    final neckY = top + r.height * 0.10;
    final shoulderY = top + r.height * 0.18;
    final chestY = top + r.height * 0.28;
    final waistY = top + r.height * 0.45;
    final hipY = top + r.height * 0.54;
    final kneeY = top + r.height * 0.78;
    final ankleY = top + r.height * 0.92;

    // أنصاف الأعراض
    final headR = r.width * 0.10;
    final shoulderHalf = r.width * (0.28 + 0.05 * s);
    final chestHalf = r.width * (0.24 + 0.06 * s);
    final waistHalf = r.width * (0.20 + 0.08 * s);
    final hipHalf = r.width * (0.23 + 0.09 * s);

    final legHalfTop = r.width * (0.12 + 0.03 * s);
    final legHalfBottom = r.width * (0.10 + 0.02 * s);

    // الرأس (موجود كدليل، لكن التطبيق يقول الوجه غير مطلوب)
    final headCenter = Offset(cx, top + r.height * 0.06);

    final p = Path();

    // Head
    p.addOval(Rect.fromCircle(center: headCenter, radius: headR));

    // Neck to shoulder
    p.moveTo(cx - headR * 0.55, neckY);
    p.quadraticBezierTo(
        cx - headR * 0.9, shoulderY, cx - shoulderHalf, shoulderY);

    // Left torso outer
    p.cubicTo(
      cx - shoulderHalf,
      chestY,
      cx - chestHalf,
      waistY,
      cx - waistHalf,
      waistY,
    );
    p.cubicTo(
      cx - waistHalf,
      hipY,
      cx - hipHalf,
      hipY,
      cx - hipHalf,
      hipY,
    );

    // Left leg outer
    p.cubicTo(
      cx - hipHalf,
      hipY + (kneeY - hipY) * 0.35,
      cx - legHalfTop,
      kneeY,
      cx - legHalfBottom,
      ankleY,
    );

    // Between legs (small gap)
    p.lineTo(cx - r.width * 0.03, ankleY);
    p.lineTo(cx - r.width * 0.03, ankleY - r.height * 0.02);
    p.lineTo(cx + r.width * 0.03, ankleY - r.height * 0.02);
    p.lineTo(cx + r.width * 0.03, ankleY);

    // Right leg outer
    p.cubicTo(
      cx + legHalfBottom,
      ankleY,
      cx + legHalfTop,
      kneeY,
      cx + hipHalf,
      hipY,
    );

    // Right torso outer
    p.cubicTo(
      cx + hipHalf,
      hipY,
      cx + waistHalf,
      hipY,
      cx + waistHalf,
      waistY,
    );
    p.cubicTo(
      cx + waistHalf,
      waistY,
      cx + chestHalf,
      chestY,
      cx + shoulderHalf,
      shoulderY,
    );

    // Close up to neck
    p.quadraticBezierTo(cx + headR * 0.9, shoulderY, cx + headR * 0.55, neckY);

    p.close();
    return p;
  }

  Path _sideSilhouettePath(Rect r, BodyShapePreset preset) {
    final s = _shapeScale(preset);

    final left = r.left;
    final right = r.right;
    final top = r.top;

    final headR = r.width * 0.10;
    final headCenter = Offset(left + r.width * 0.55, top + r.height * 0.07);

    final neckY = top + r.height * 0.12;
    final shoulderY = top + r.height * 0.20;
    final chestY = top + r.height * 0.30;
    final bellyY = top + r.height * 0.46;
    final hipY = top + r.height * 0.55;
    final kneeY = top + r.height * 0.78;
    final ankleY = top + r.height * 0.92;

    // عمق/بروز البطن والصدر للـ heavy
    final chestOut = r.width * (0.12 + 0.05 * s);
    final bellyOut = r.width * (0.10 + 0.09 * s);
    final buttOut = r.width * (0.08 + 0.07 * s);

    // خط العمود الفقري التقريبي
    final spineX = left + r.width * 0.52;

    final p = Path();
    p.addOval(Rect.fromCircle(center: headCenter, radius: headR));

    // من الرقبة للكتف (أعلى الظهر)
    p.moveTo(spineX, neckY);
    p.quadraticBezierTo(
        spineX - r.width * 0.10, shoulderY, spineX - r.width * 0.05, chestY);

    // الصدر (أمام)
    p.quadraticBezierTo(spineX + chestOut, chestY, spineX + chestOut, bellyY);

    // البطن
    p.quadraticBezierTo(
        spineX + bellyOut, bellyY, spineX + bellyOut * 0.85, hipY);

    // الورك/المؤخرة (خلف)
    p.quadraticBezierTo(spineX - buttOut, hipY, spineX - buttOut * 0.55,
        hipY + r.height * 0.05);

    // الرجل
    p.quadraticBezierTo(
        spineX - r.width * 0.06, kneeY, spineX - r.width * 0.04, ankleY);

    // القدم
    p.lineTo(spineX + r.width * 0.16, ankleY);
    p.lineTo(spineX + r.width * 0.16, ankleY - r.height * 0.02);
    p.lineTo(spineX - r.width * 0.04, ankleY - r.height * 0.02);

    // العودة للأعلى (أمام الجسم)
    p.quadraticBezierTo(
        spineX + r.width * 0.06, kneeY, spineX + r.width * 0.05, hipY);
    p.quadraticBezierTo(
        spineX + bellyOut * 0.75, bellyY, spineX + chestOut * 0.85, chestY);
    p.quadraticBezierTo(spineX + r.width * 0.02, shoulderY, spineX, neckY);

    p.close();
    return p;
  }

  double _shapeScale(BodyShapePreset preset) {
    switch (preset) {
      case BodyShapePreset.slim:
        return 0.0;
      case BodyShapePreset.normal:
        return 0.5;
      case BodyShapePreset.heavy:
        return 1.0;
    }
  }

  @override
  bool shouldRepaint(covariant BodyOverlayPainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.preset != preset ||
        oldDelegate.dimOpacity != dimOpacity ||
        oldDelegate.isReady != isReady;
  }
}
