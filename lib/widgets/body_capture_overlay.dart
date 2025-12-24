// lib/widgets/body_capture_overlay.dart
// C2-FINAL: Professional Measurement Frame Overlay
// Privacy-Safe: NO FACE DETECTION, NO FACE REQUIRED

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bodytalk_app/main.dart';
import 'package:bodytalk_app/services/live_pose_validator.dart';
import 'package:bodytalk_app/widgets/pro_measurement_overlay_painter.dart';

/// Camera overlay widget that guides users to align their body correctly
/// Shows professional human silhouette cutout window (FRONT and SIDE poses)
/// Privacy-safe: Only shows shoulders, hips, legs - NO FACE
class BodyCaptureOverlay extends StatelessWidget {
  final bool isFrontMode; // true = front pose, false = side pose
  final LiveValidationState validationState; // Live validation state
  final String? guidanceText; // Real-time guidance message
  final BodyPreset bodyPreset; // Body shape preset (slim/normal/heavy)

  const BodyCaptureOverlay({
    super.key,
    required this.isFrontMode,
    this.validationState = LiveValidationState.noPerson,
    this.guidanceText,
    this.bodyPreset = BodyPreset.normal,
  });

  @override
  Widget build(BuildContext context) {
    final isReady = validationState == LiveValidationState.okReady;

    return Stack(
      children: [
        // Professional measurement frame overlay
        Positioned.fill(
          child: CustomPaint(
            painter: ProMeasurementOverlayPainter(
              mode: isFrontMode ? BodyOverlayMode.front : BodyOverlayMode.side,
              preset: bodyPreset,
              isReady: isReady,
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
}
