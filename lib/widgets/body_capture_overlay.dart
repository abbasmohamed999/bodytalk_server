// lib/widgets/body_capture_overlay.dart
// Phase C2.1: Camera Overlay Guidance with Live Pose Detection
// Privacy-Safe: NO FACE DETECTION, NO FACE REQUIRED

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bodytalk_app/main.dart';
import 'package:bodytalk_app/services/live_pose_validator.dart';

/// Camera overlay widget that guides users to align their body correctly
/// Shows different silhouettes for FRONT and SIDE poses
/// Privacy-safe: Only shows shoulders, hips, legs - NO FACE
class BodyCaptureOverlay extends StatelessWidget {
  final bool isFrontMode; // true = front pose, false = side pose
  final LiveValidationState validationState; // Live validation state
  final String? guidanceText; // Real-time guidance message

  const BodyCaptureOverlay({
    super.key,
    required this.isFrontMode,
    this.validationState = LiveValidationState.NO_PERSON,
    this.guidanceText,
  });

  @override
  Widget build(BuildContext context) {
    final isReady = validationState == LiveValidationState.OK_READY;

    return Stack(
      children: [
        // Safe crop mask (darken area outside silhouette - spotlight effect)
        Positioned.fill(
          child: CustomPaint(
            painter: _SafeCropMaskPainter(
              isFrontMode: isFrontMode,
              validationState: validationState,
            ),
          ),
        ),

        // Top instruction banner
        Positioned(
          top: 60,
          left: 20,
          right: 20,
          child: _buildInstructionBanner(context),
        ),

        // Bottom guidance text - ONLY show success when OK_READY
        if (guidanceText != null && guidanceText!.isNotEmpty)
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: _buildGuidanceText(context, isReady),
          ),

        // Body part labels (Privacy-safe: shoulders, hips, feet only)
        if (!isReady)
          Positioned.fill(
            child: _buildBodyPartLabels(context),
          ),
      ],
    );
  }

  Widget _buildInstructionBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isFrontMode ? Icons.person : Icons.person_outline,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            BodyTalkApp.tr(context,
                en: isFrontMode
                    ? 'Front Photo: Face camera directly'
                    : 'Side Photo: Turn 90° sideways',
                fr: isFrontMode
                    ? 'Photo de face : Faites face à la caméra'
                    : 'Photo de profil : Tournez-vous de 90°',
                ar: isFrontMode
                    ? 'صورة أمامية: واجه الكاميرا مباشرة'
                    : 'صورة جانبية: استدر 90 درجة'),
            style: GoogleFonts.tajawal(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            BodyTalkApp.tr(context,
                en: 'Face NOT required (privacy-safe)',
                fr: 'Visage NON requis (respect vie privée)',
                ar: 'الوجه غير مطلوب (حفظ الخصوصية)'),
            style: GoogleFonts.tajawal(
              color: Colors.white70,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceText(BuildContext context, bool isReady) {
    // Determine color based on validation state - NO premature success
    Color backgroundColor;
    IconData icon;

    if (isReady) {
      backgroundColor = Colors.green.withValues(alpha: 0.9);
      icon = Icons.check_circle;
    } else {
      // Show neutral blue for instructions, orange for warnings
      final isWarning = guidanceText!.contains('close') ||
          guidanceText!.contains('far') ||
          guidanceText!.contains('orientation') ||
          guidanceText!.contains('partial');
      backgroundColor = isWarning
          ? Colors.orange.withValues(alpha: 0.9)
          : const Color(0xFF2563EB).withValues(alpha: 0.9);
      icon = isWarning ? Icons.warning_amber : Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              guidanceText!,
              style: GoogleFonts.tajawal(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyPartLabels(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final overlayHeight = screenHeight * 0.7;
    final centerY = (screenHeight - overlayHeight) / 2;

    return Stack(
      children: [
        // Shoulder label
        Positioned(
          top: centerY + overlayHeight * 0.15,
          left: 30,
          child: _buildLabel(
            context,
            BodyTalkApp.tr(context,
                en: 'Shoulders', fr: 'Épaules', ar: 'كتفين'),
            Icons.arrow_forward,
          ),
        ),

        // Hip label
        Positioned(
          top: centerY + overlayHeight * 0.45,
          left: 30,
          child: _buildLabel(
            context,
            BodyTalkApp.tr(context, en: 'Hips', fr: 'Hanches', ar: 'وركين'),
            Icons.arrow_forward,
          ),
        ),

        // Feet label
        Positioned(
          bottom: centerY + overlayHeight * 0.1,
          left: 30,
          child: _buildLabel(
            context,
            BodyTalkApp.tr(context, en: 'Feet', fr: 'Pieds', ar: 'قدمين'),
            Icons.arrow_forward,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(BuildContext context, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.tajawal(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for safe crop mask with professional human silhouette
/// Creates spotlight effect - dim outside, clear silhouette inside
/// Privacy-safe: NO FACE - shoulders → feet only
class _SafeCropMaskPainter extends CustomPainter {
  final bool isFrontMode;
  final LiveValidationState validationState;

  _SafeCropMaskPainter({
    required this.isFrontMode,
    required this.validationState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isReady = validationState == LiveValidationState.OK_READY;

    // خلفية زرقاء داكنة #0F2A4A مع تعتيم
    final darkOverlay = Paint()
      ..color = const Color(0xFF0F2A4A).withValues(alpha: 0.75);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), darkOverlay);

    // حساب أبعاد الصورة الظلية (مركزية، نسب صحيحة)
    final silhouetteHeight = size.height * 0.70;
    final silhouetteWidth = isFrontMode
        ? silhouetteHeight * 0.50 // الوضع الأمامي: عرض متوسط
        : silhouetteHeight * 0.45; // الوضع الجانبي: عرض أقل قليلاً

    final centerX = size.width / 2;
    final startY = (size.height - silhouetteHeight) / 2 + size.height * 0.05;

    // إنشاء مسار الصورة الظلية الاحترافي
    final silhouettePath = Path();
    if (isFrontMode) {
      _drawProfessionalFrontSilhouette(
          silhouettePath, centerX, startY, silhouetteWidth, silhouetteHeight);
    } else {
      _drawProfessionalSideSilhouette(
          silhouettePath, centerX, startY, silhouetteWidth, silhouetteHeight);
    }

    // قص الصورة الظلية من الخلفية الداكنة (تأثير الكشاف)
    canvas.drawPath(
      silhouettePath,
      Paint()
        ..color = Colors.transparent
        ..blendMode = BlendMode.clear,
    );

    // رسم حدود الصورة الظلية
    // الخطوط: بيضاء، سمك 3px (كما هو مطلوب)
    final outlineColor =
        isReady ? Colors.green.withValues(alpha: 0.9) : Colors.white;

    canvas.drawPath(
      silhouettePath,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0, // سمك 3px كما هو مطلوب
    );

    // رسم تعبئة خفيفة داخل الصورة الظلية
    canvas.drawPath(
      silhouettePath,
      Paint()
        ..color = outlineColor.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawProfessionalFrontSilhouette(
      Path path, double centerX, double startY, double width, double height) {
    // استخدام نظام نسبي (0..1) كما هو مطلوب
    // تحويل الإحداثيات النسبية إلى إحداثيات حقيقية
    double toX(double nx) => centerX - width / 2 + nx * width;
    double toY(double ny) => startY + ny * height;

    // الرأس (بيضاوي صغير أعلى المنتصف)
    path.addOval(Rect.fromCenter(
      center: Offset(toX(0.5), toY(0.09)),
      width: width * 0.18,
      height: height * 0.11,
    ));

    // خط الكتفين (من اليسار إلى اليمين عند y ≈ 0.20)
    path.moveTo(toX(0.30), toY(0.20));
    path.quadraticBezierTo(
      toX(0.50),
      toY(0.18),
      toX(0.70),
      toY(0.20),
    );

    // الذراع الأيسر
    path.moveTo(toX(0.30), toY(0.20));
    path.quadraticBezierTo(toX(0.28), toY(0.35), toX(0.32), toY(0.55));
    path.quadraticBezierTo(toX(0.33), toY(0.62), toX(0.34), toY(0.66));
    path.quadraticBezierTo(toX(0.35), toY(0.70), toX(0.36), toY(0.72));

    // الذراع الأيمن
    path.moveTo(toX(0.70), toY(0.20));
    path.quadraticBezierTo(toX(0.72), toY(0.35), toX(0.68), toY(0.55));
    path.quadraticBezierTo(toX(0.67), toY(0.62), toX(0.66), toY(0.66));
    path.quadraticBezierTo(toX(0.65), toY(0.70), toX(0.64), toY(0.72));

    // الجذع (من الصدر إلى الوركين)
    path.moveTo(toX(0.32), toY(0.28));
    path.quadraticBezierTo(toX(0.50), toY(0.33), toX(0.68), toY(0.28));
    path.quadraticBezierTo(toX(0.66), toY(0.45), toX(0.62), toY(0.52));
    path.quadraticBezierTo(toX(0.50), toY(0.56), toX(0.38), toY(0.52));
    path.quadraticBezierTo(toX(0.34), toY(0.45), toX(0.32), toY(0.28));

    // خط الوركين (منحني قليلاً عند y ≈ 0.56)
    path.moveTo(toX(0.36), toY(0.56));
    path.quadraticBezierTo(toX(0.50), toY(0.58), toX(0.64), toY(0.56));

    // الساق اليسرى
    path.moveTo(toX(0.42), toY(0.56));
    path.quadraticBezierTo(toX(0.40), toY(0.70), toX(0.40), toY(0.86));
    path.lineTo(toX(0.40), toY(0.95));

    // الساق اليمنى
    path.moveTo(toX(0.58), toY(0.56));
    path.quadraticBezierTo(toX(0.60), toY(0.70), toX(0.60), toY(0.86));
    path.lineTo(toX(0.60), toY(0.95));

    // الخط الإرشادي عند الصدر
    path.moveTo(toX(0.28), toY(0.36));
    path.lineTo(toX(0.72), toY(0.36));

    // الخط الإرشادي عند الوركين
    path.moveTo(toX(0.32), toY(0.56));
    path.lineTo(toX(0.68), toY(0.56));
  }

  void _drawProfessionalSideSilhouette(
      Path path, double centerX, double startY, double width, double height) {
    // استخدام نظام نسبي (0..1) كما هو مطلوب
    double toX(double nx) => centerX - width / 2 + nx * width;
    double toY(double ny) => startY + ny * height;

    // الرأس (بيضاوي جانبي عند x ≈ 0.60, y ≈ 0.09)
    path.addOval(Rect.fromCenter(
      center: Offset(toX(0.60), toY(0.09)),
      width: width * 0.18,
      height: height * 0.11,
    ));

    // العنق إلى الكتف
    path.moveTo(toX(0.58), toY(0.14));
    path.quadraticBezierTo(toX(0.56), toY(0.18), toX(0.54), toY(0.20));

    // الصدر إلى البطن
    path.moveTo(toX(0.54), toY(0.20));
    path.quadraticBezierTo(toX(0.52), toY(0.30), toX(0.52), toY(0.42));
    path.quadraticBezierTo(toX(0.53), toY(0.50), toX(0.52), toY(0.56));

    // الورك إلى الفخذ
    path.moveTo(toX(0.52), toY(0.56));
    path.quadraticBezierTo(toX(0.51), toY(0.64), toX(0.51), toY(0.72));

    // الركبة إلى الكاحل
    path.moveTo(toX(0.51), toY(0.72));
    path.quadraticBezierTo(toX(0.51), toY(0.84), toX(0.51), toY(0.95));

    // الذراع الجانبي
    path.moveTo(toX(0.56), toY(0.26));
    path.quadraticBezierTo(toX(0.57), toY(0.42), toX(0.55), toY(0.66));

    // خط الأرضي (عند القدمين)
    path.moveTo(toX(0.40), toY(0.95));
    path.lineTo(toX(0.75), toY(0.95));
  }

  // لا حاجة لخطوط إرشادية إضافية - مرسومة في الشكل نفسه

  @override
  bool shouldRepaint(_SafeCropMaskPainter oldDelegate) {
    return oldDelegate.isFrontMode != isFrontMode ||
        oldDelegate.validationState != validationState;
  }
}
