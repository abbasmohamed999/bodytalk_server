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

    // Draw dark overlay (full screen)
    final darkOverlay = Paint()..color = Colors.black.withValues(alpha: 0.65);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), darkOverlay);

    // Calculate silhouette dimensions (centered, proper proportions)
    final silhouetteHeight = size.height * 0.70; // 70% of screen
    final silhouetteWidth = isFrontMode
        ? silhouetteHeight * 0.35 // Front: narrow (shoulders width)
        : silhouetteHeight * 0.42; // Side: slightly wider

    final centerX = size.width / 2;
    final startY = (size.height - silhouetteHeight) / 2 + size.height * 0.05;

    // Create professional human silhouette path
    final silhouettePath = Path();
    if (isFrontMode) {
      _drawProfessionalFrontSilhouette(
          silhouettePath, centerX, startY, silhouetteWidth, silhouetteHeight);
    } else {
      _drawProfessionalSideSilhouette(
          silhouettePath, centerX, startY, silhouetteWidth, silhouetteHeight);
    }

    // Cut out silhouette from dark overlay (spotlight effect)
    canvas.drawPath(
      silhouettePath,
      Paint()
        ..color = Colors.transparent
        ..blendMode = BlendMode.clear,
    );

    // Draw silhouette outline
    final outlineColor = isReady
        ? Colors.green.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.35);

    canvas.drawPath(
      silhouettePath,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Draw subtle fill inside silhouette
    canvas.drawPath(
      silhouettePath,
      Paint()
        ..color = outlineColor.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );

    // Draw guide lines (shoulders, hips, knees, feet baseline)
    _drawGuideLines(canvas, centerX, startY, silhouetteWidth, silhouetteHeight,
        outlineColor);
  }

  void _drawProfessionalFrontSilhouette(
      Path path, double centerX, double startY, double width, double height) {
    // Human proportions (privacy-safe: shoulders → feet)
    final shoulderWidth = width * 0.95;
    final hipWidth = width * 0.85;
    final kneeWidth = width * 0.50;
    final ankleWidth = width * 0.40;

    // Vertical positions
    final shoulderY = startY;
    final waistY = startY + height * 0.30;
    final hipY = startY + height * 0.35;
    final kneeY = startY + height * 0.65;
    final ankleY = startY + height * 0.95;
    final footY = startY + height;

    // Start from left shoulder
    path.moveTo(centerX - shoulderWidth / 2, shoulderY);

    // Left side (shoulder → waist → hip → knee → ankle → foot)
    path.quadraticBezierTo(
      centerX - shoulderWidth / 2.2,
      waistY,
      centerX - hipWidth / 2,
      hipY,
    );
    path.lineTo(centerX - kneeWidth / 2, kneeY);
    path.lineTo(centerX - ankleWidth / 2, ankleY);
    path.lineTo(centerX - ankleWidth / 2.5, footY);

    // Bottom (feet gap)
    path.lineTo(centerX + ankleWidth / 2.5, footY);

    // Right side (foot → ankle → knee → hip → waist → shoulder)
    path.lineTo(centerX + ankleWidth / 2, ankleY);
    path.lineTo(centerX + kneeWidth / 2, kneeY);
    path.lineTo(centerX + hipWidth / 2, hipY);
    path.quadraticBezierTo(
      centerX + shoulderWidth / 2.2,
      waistY,
      centerX + shoulderWidth / 2,
      shoulderY,
    );

    path.close();
  }

  void _drawProfessionalSideSilhouette(
      Path path, double centerX, double startY, double width, double height) {
    // Side view proportions (90° turn)
    final chestDepth = width * 0.55;
    final hipDepth = width * 0.50;
    final legThickness = width * 0.35;

    // Vertical positions
    final shoulderY = startY;
    final chestY = startY + height * 0.20;
    final waistY = startY + height * 0.30;
    final hipY = startY + height * 0.35;
    final kneeY = startY + height * 0.65;
    final ankleY = startY + height * 0.95;
    final footY = startY + height;

    // Start from back shoulder
    path.moveTo(centerX - chestDepth * 0.25, shoulderY);

    // Back profile (shoulder → chest → waist → hip → back leg)
    path.quadraticBezierTo(
      centerX - chestDepth * 0.15,
      chestY,
      centerX - hipDepth * 0.15,
      waistY,
    );
    path.lineTo(centerX - hipDepth * 0.10, hipY);
    path.lineTo(centerX - legThickness * 0.15, kneeY);
    path.lineTo(centerX - legThickness * 0.10, ankleY);
    path.lineTo(centerX, footY);

    // Front profile (front leg → knee → hip → waist → chest → shoulder)
    path.lineTo(centerX + legThickness * 0.25, ankleY);
    path.lineTo(centerX + legThickness * 0.30, kneeY);
    path.lineTo(centerX + hipDepth * 0.35, hipY);
    path.quadraticBezierTo(
      centerX + hipDepth * 0.40,
      waistY,
      centerX + chestDepth * 0.45,
      chestY,
    );
    path.quadraticBezierTo(
      centerX + chestDepth * 0.40,
      shoulderY,
      centerX + chestDepth * 0.30,
      shoulderY,
    );

    path.close();
  }

  void _drawGuideLines(Canvas canvas, double centerX, double startY,
      double width, double height, Color color) {
    final guidePaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Horizontal guide lines with labels
    final guides = [
      (0.0, 'Shoulders'),
      (0.35, 'Hips'),
      (0.65, 'Knees'),
      (1.0, 'Feet'),
    ];

    for (final guide in guides) {
      final y = startY + height * guide.$1;
      _drawDashedLine(
        canvas,
        Offset(centerX - width * 0.6, y),
        Offset(centerX + width * 0.6, y),
        guidePaint,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double distance = (end - start).distance;
    double drawnDistance = 0.0;

    while (drawnDistance < distance) {
      final dashEnd = drawnDistance + dashWidth;
      if (dashEnd > distance) break;

      final startRatio = drawnDistance / distance;
      final endRatio = dashEnd / distance;

      canvas.drawLine(
        Offset.lerp(start, end, startRatio)!,
        Offset.lerp(start, end, endRatio)!,
        paint,
      );

      drawnDistance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_SafeCropMaskPainter oldDelegate) {
    return oldDelegate.isFrontMode != isFrontMode ||
        oldDelegate.validationState != validationState;
  }
}
