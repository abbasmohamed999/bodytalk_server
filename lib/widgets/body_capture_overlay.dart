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
    return Stack(
      children: [
        // Dark overlay background
        Container(
          color: Colors.black.withValues(alpha: 0.5),
        ),

        // Cutout silhouette area
        Center(
          child: CustomPaint(
            size: Size(
              MediaQuery.of(context).size.width * 0.6,
              MediaQuery.of(context).size.height * 0.7,
            ),
            painter: _BodySilhouettePainter(
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

        // Bottom guidance text
        if (guidanceText != null && guidanceText!.isNotEmpty)
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: _buildGuidanceText(context),
          ),

        // Body part labels (Privacy-safe: shoulders, hips, feet only)
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

  Widget _buildGuidanceText(BuildContext context) {
    final isReady = validationState == LiveValidationState.OK_READY;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isReady
            ? Colors.green.withValues(alpha: 0.9)
            : Colors.orange.withValues(alpha: 0.9),
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
            isReady ? Icons.check_circle : Icons.info_outline,
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

/// Custom painter for body silhouette overlay
/// Privacy-safe: NO FACE - only shoulders, torso, hips, legs
class _BodySilhouettePainter extends CustomPainter {
  final bool isFrontMode;
  final LiveValidationState validationState;

  _BodySilhouettePainter({
    required this.isFrontMode,
    required this.validationState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isReady = validationState == LiveValidationState.OK_READY;
    final paint = Paint()
      ..color = isReady
          ? Colors.green.withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final path = Path();

    if (isFrontMode) {
      _drawFrontSilhouette(path, size);
    } else {
      _drawSideSilhouette(path, size);
    }

    // Draw filled silhouette
    canvas.drawPath(path, fillPaint);

    // Draw outline
    canvas.drawPath(path, paint);

    // Draw dashed guide lines
    _drawGuideLines(canvas, size);
  }

  void _drawFrontSilhouette(Path path, Size size) {
    final centerX = size.width / 2;
    final shoulderWidth = size.width * 0.4;
    final hipWidth = size.width * 0.35;

    // Start from shoulders (NO HEAD/NECK)
    path.moveTo(centerX - shoulderWidth / 2, size.height * 0.15);

    // Left shoulder to hip
    path.lineTo(centerX - hipWidth / 2, size.height * 0.45);

    // Left hip to left knee
    path.lineTo(centerX - hipWidth / 3, size.height * 0.70);

    // Left knee to left ankle
    path.lineTo(centerX - shoulderWidth / 4, size.height * 0.95);

    // Bottom feet gap
    path.lineTo(centerX + shoulderWidth / 4, size.height * 0.95);

    // Right ankle to right knee
    path.lineTo(centerX + hipWidth / 3, size.height * 0.70);

    // Right knee to right hip
    path.lineTo(centerX + hipWidth / 2, size.height * 0.45);

    // Right hip to right shoulder
    path.lineTo(centerX + shoulderWidth / 2, size.height * 0.15);

    // Close at shoulders
    path.close();
  }

  void _drawSideSilhouette(Path path, Size size) {
    final shoulderX = size.width * 0.4;
    final bodyDepth = size.width * 0.25;

    // Start from back shoulder (NO HEAD)
    path.moveTo(shoulderX - bodyDepth * 0.3, size.height * 0.15);

    // Back shoulder to back hip
    path.lineTo(shoulderX - bodyDepth * 0.2, size.height * 0.45);

    // Back hip to back knee
    path.lineTo(shoulderX - bodyDepth * 0.1, size.height * 0.70);

    // Back knee to back ankle
    path.lineTo(shoulderX, size.height * 0.95);

    // Front ankle to front knee
    path.lineTo(shoulderX + bodyDepth * 0.3, size.height * 0.70);

    // Front knee to front hip
    path.lineTo(shoulderX + bodyDepth * 0.4, size.height * 0.45);

    // Front hip to front shoulder
    path.lineTo(shoulderX + bodyDepth * 0.5, size.height * 0.15);

    // Close path
    path.close();
  }

  void _drawGuideLines(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Horizontal guide lines (shoulders, hips, knees, feet)
    final guides = [0.15, 0.45, 0.70, 0.95];
    for (final ratio in guides) {
      final y = size.height * ratio;
      _drawDashedLine(
        canvas,
        Offset(0, y),
        Offset(size.width, y),
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
  bool shouldRepaint(_BodySilhouettePainter oldDelegate) {
    return oldDelegate.isFrontMode != isFrontMode ||
        oldDelegate.validationState != validationState;
  }
}
