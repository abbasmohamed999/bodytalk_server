// lib/widgets/body_capture_overlay.dart
// Simple guide lines overlay - NO silhouette
// Privacy-Safe: NO FACE DETECTION, NO FACE REQUIRED

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bodytalk_app/main.dart';
import 'package:bodytalk_app/services/live_pose_validator.dart';
import 'package:bodytalk_app/widgets/pro_measurement_overlay_painter.dart';

/// Camera overlay widget with simple guide lines (no silhouette)
class BodyCaptureOverlay extends StatelessWidget {
  final bool isFrontMode;
  final LiveValidationState validationState;
  final String? guidanceText;
  final BodyPreset bodyPreset;
  final VoidCallback? onClose;
  final VoidCallback? onCapture;

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
        // Guide lines overlay (no silhouette)
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
            top: 45,
            left: 16,
            child: _buildCloseButton(),
          ),

        // Top info card
        Positioned(
          top: 40,
          left: 70,
          right: 70,
          child: _buildInfoCard(context),
        ),

        // Bottom message
        Positioned(
          bottom: 100,
          left: 24,
          right: 24,
          child: _buildBottomMessage(context, isReady),
        ),

        // Capture button
        if (onCapture != null)
          Positioned(
            bottom: 25,
            left: 0,
            right: 0,
            child: Center(
              child: _buildCaptureButton(isReady),
            ),
          ),
      ],
    );
  }

  Widget _buildCloseButton() {
    return Material(
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
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            BodyTalkApp.tr(context,
                en: 'Align with guide lines',
                fr: 'Alignez avec les lignes',
                ar: 'وازن الجسم مع الخطوط'),
            style: GoogleFonts.tajawal(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomMessage(BuildContext context, bool isReady) {
    if (!isReady && (guidanceText == null || guidanceText!.isEmpty)) {
      return const SizedBox.shrink();
    }

    final message = isReady
        ? BodyTalkApp.tr(context,
            en: 'Ready! Tap to capture',
            fr: 'Prêt! Appuyez pour capturer',
            ar: 'جاهز! اضغط للالتقاط')
        : guidanceText!;

    final bgColor = isReady
        ? const Color(0xFF39D98A).withOpacity(0.9)
        : Colors.orange.withOpacity(0.85);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
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
            size: 20,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: GoogleFonts.tajawal(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
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
            color: Colors.black.withOpacity(0.4),
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
              color: isReady ? Colors.white : Colors.white.withOpacity(0.4),
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
