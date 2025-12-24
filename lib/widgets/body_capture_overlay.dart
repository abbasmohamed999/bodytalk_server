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
    final screenHeight = MediaQuery.of(context).size.height;

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

        // Close button (top-left) - above everything
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

        // Top info card (blue) - compact, positioned above the frame
        Positioned(
          top: 35,
          left: 55,
          right: 55,
          child: _buildInfoCard(context),
        ),

        // Side label buttons (shoulders, hips, feet)
        _buildSideLabelButtons(context),

        // Bottom message banner - below the silhouette
        Positioned(
          bottom: screenHeight * 0.12 + 10,
          left: 20,
          right: 20,
          child: _buildBottomMessage(context, isReady),
        ),

        // Capture button (bottom center)
        if (onCapture != null)
          Positioned(
            bottom: 20,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            BodyTalkApp.tr(context,
                en: isFrontMode ? 'Front Photo' : 'Turn 90° Sideways',
                fr: isFrontMode ? 'Photo de face' : 'Tournez de 90°',
                ar: isFrontMode ? 'صورة أمامية' : 'استدر 90 درجة'),
            style: GoogleFonts.tajawal(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            BodyTalkApp.tr(context,
                en: 'Face NOT required',
                fr: 'Visage NON requis',
                ar: 'الوجه غير مطلوب'),
            style: GoogleFonts.tajawal(
              color: Colors.white.withOpacity(0.85),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSideLabelButtons(BuildContext context) {
    // Get screen dimensions for positioning - match BodyOverlaySpec
    final screenHeight = MediaQuery.of(context).size.height;
    final frameTop = screenHeight * BodyOverlaySpec.frameTopFrac;
    final frameHeight = screenHeight * BodyOverlaySpec.frameHFrac;

    // Calculate Y positions based on BodyOverlaySpec (updated values)
    final shouldersY = frameTop + frameHeight * BodyOverlaySpec.shouldersY;
    final hipsY = frameTop + frameHeight * BodyOverlaySpec.hipsY;
    final feetY = frameTop + frameHeight * BodyOverlaySpec.feetY;

    return Stack(
      children: [
        // Shoulders label (left)
        _buildLabel(
          context,
          top: shouldersY - 16,
          left: 8,
          text: BodyTalkApp.tr(context,
              en: 'Shoulders', fr: 'Épaules', ar: 'كتفين'),
        ),
        // Hips label (left)
        _buildLabel(
          context,
          top: hipsY - 16,
          left: 8,
          text: BodyTalkApp.tr(context, en: 'Hips', fr: 'Hanches', ar: 'وركين'),
        ),
        // Feet label (left)
        _buildLabel(
          context,
          top: feetY - 16,
          left: 8,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.35),
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
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.arrow_forward,
              color: Colors.white.withOpacity(0.7),
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomMessage(BuildContext context, bool isReady) {
    // Only show message when there's something to show
    if (!isReady && (guidanceText == null || guidanceText!.isEmpty)) {
      return const SizedBox.shrink();
    }

    final message = isReady
        ? BodyTalkApp.tr(context,
            en: 'Hold still - Capturing...',
            fr: 'Ne bougez pas - Capture...',
            ar: 'ابق ثابتاً - جاري الالتقاط...')
        : guidanceText!;

    final bgColor = isReady
        ? const Color(0xFF39D98A).withOpacity(0.9)
        : Colors.orange.withOpacity(0.85);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReady ? Icons.check_circle : Icons.info_outline,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: GoogleFonts.tajawal(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton(bool isReady) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isReady ? onCapture : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.45),
            border: Border.all(
              color: isReady
                  ? const Color(0xFF39D98A)
                  : Colors.white.withOpacity(0.5),
              width: 4,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.camera_alt,
              color: isReady ? Colors.white : Colors.white.withOpacity(0.35),
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
