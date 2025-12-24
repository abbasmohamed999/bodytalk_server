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
  final VoidCallback? onClose; // Close button callback
  final VoidCallback? onCapture; // Capture button callback

  const BodyCaptureOverlay({
    super.key,
    required this.isFrontMode,
    this.validationState = LiveValidationState.noPerson,
    this.guidanceText,
    this.bodyPreset = BodyPreset.normal,
    this.onClose,
    this.onCapture,
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

        // Close button (top-left)
        if (onClose != null)
          Positioned(
            top: 40,
            left: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onClose,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

        // Top info card (blue)
        Positioned(
          top: 40,
          left: 60,
          right: 60,
          child: _buildInfoCard(context),
        ),

        // Side label buttons (shoulders, hips, feet)
        _buildSideLabelButtons(context),

        // Bottom message banner
        Positioned(
          bottom: 120,
          left: 20,
          right: 20,
          child: _buildBottomMessage(context, isReady),
        ),

        // Capture button (bottom center)
        if (onCapture != null)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: _buildCaptureButton(isReady),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            BodyTalkApp.tr(context,
                en: isFrontMode ? 'Front Photo' : 'Turn 90° Sideways',
                fr: isFrontMode ? 'Photo de face' : 'Tournez-vous de 90°',
                ar: isFrontMode ? 'صورة أمامية' : 'جيرة: استندر 90 درجة'),
            style: GoogleFonts.tajawal(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            BodyTalkApp.tr(context,
                en: 'Face camera directly',
                fr: 'Faites face à la caméra',
                ar: 'صورد واجه الكاميرا مباشرة'),
            style: GoogleFonts.tajawal(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            BodyTalkApp.tr(context,
                en: 'Face NOT required (privacy-safe)',
                fr: 'Visage NON requis (respect vie privée)',
                ar: 'الوجه لحظة غير مطلوب (حفظ الخصوصية)'),
            style: GoogleFonts.tajawal(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSideLabelButtons(BuildContext context) {
    // Get screen dimensions for positioning
    final screenHeight = MediaQuery.of(context).size.height;
    final frameTop = screenHeight * 0.10;
    final frameHeight = screenHeight * 0.78;

    // Calculate Y positions based on BodyOverlaySpec
    final shouldersY = frameTop + frameHeight * 0.23;
    final hipsY = frameTop + frameHeight * 0.52;
    final feetY = frameTop + frameHeight * 0.92;

    return Stack(
      children: [
        // Shoulders label (left)
        _buildLabel(
          context,
          top: shouldersY - 20,
          left: 16,
          text: BodyTalkApp.tr(context,
              en: 'Shoulders', fr: 'Épaules', ar: 'كتفين'),
        ),
        // Hips label (left)
        _buildLabel(
          context,
          top: hipsY - 20,
          left: 16,
          text: BodyTalkApp.tr(context, en: 'Hips', fr: 'Hanches', ar: 'وركين'),
        ),
        // Feet label (left)
        _buildLabel(
          context,
          top: feetY - 20,
          left: 16,
          text: BodyTalkApp.tr(context, en: 'Feet', fr: 'Pieds', ar: 'قدمين'),
        ),
      ],
    );
  }

  Widget _buildLabel(BuildContext context,
      {required double top,
      double? left,
      double? right,
      required String text}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: GoogleFonts.tajawal(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward,
              color: Colors.white.withOpacity(0.8),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomMessage(BuildContext context, bool isReady) {
    if (isReady) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                BodyTalkApp.tr(context,
                    en: 'Rotate with the previous photo',
                    fr: 'Faites pivoter avec la photo précédente',
                    ar: 'استدر °90 يوافق حسك مع الصورة القلبة'),
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
    } else if (guidanceText != null && guidanceText!.isNotEmpty) {
      // Show guidance text
      final isWarning = guidanceText!.contains('close') ||
          guidanceText!.contains('far') ||
          guidanceText!.contains('orientation') ||
          guidanceText!.contains('partial');

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isWarning
              ? Colors.orange.withOpacity(0.9)
              : const Color(0xFF2563EB).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isWarning ? Icons.warning_amber : Icons.info_outline,
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

    return const SizedBox.shrink();
  }

  Widget _buildCaptureButton(bool isReady) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isReady ? onCapture : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.5),
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 4,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.camera_alt,
              color: isReady ? Colors.white : Colors.white.withOpacity(0.4),
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}
