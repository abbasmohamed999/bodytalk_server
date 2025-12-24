// lib/services/measurement_frame_validator.dart
// Strict measurement frame validation for body analysis
// Uses EXACT same frame and guide line positions as ProMeasurementOverlayPainter

import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:bodytalk_app/widgets/pro_measurement_overlay_painter.dart';

/// Validation result for measurement frame
class MeasurementFrameResult {
  final bool isValid;
  final String? errorMessage;
  final double? heightRatio;
  final double? bodyWidthRatio;

  const MeasurementFrameResult({
    required this.isValid,
    this.errorMessage,
    this.heightRatio,
    this.bodyWidthRatio,
  });

  factory MeasurementFrameResult.valid({
    required double heightRatio,
    required double bodyWidthRatio,
  }) {
    return MeasurementFrameResult(
      isValid: true,
      heightRatio: heightRatio,
      bodyWidthRatio: bodyWidthRatio,
    );
  }

  factory MeasurementFrameResult.invalid(String errorMessage) {
    return MeasurementFrameResult(
      isValid: false,
      errorMessage: errorMessage,
    );
  }
}

class MeasurementFrameValidator {
  /// Compute the measurement frame rect (EXACT same as ProMeasurementOverlayPainter)
  static Rect computeFrameRect(Size imageSize) {
    final sw = imageSize.width;
    final sh = imageSize.height;
    final frameTop = sh * BodyOverlaySpec.frameTopFrac;
    final frameH = sh * BodyOverlaySpec.frameHFrac;
    final frameW = sw * BodyOverlaySpec.frameWFrac;
    final frameLeft = (sw - frameW) / 2;
    return Rect.fromLTWH(frameLeft, frameTop, frameW, frameH);
  }

  /// Validate that body parts are within the measurement frame
  /// Returns MeasurementFrameResult with validation status
  static MeasurementFrameResult validateFrame({
    required List<Pose> poses,
    required Size imageSize,
  }) {
    if (poses.isEmpty) {
      return MeasurementFrameResult.invalid('No person detected');
    }

    final pose = poses.first;
    final frameRect = computeFrameRect(imageSize);

    // Extract key landmarks
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    // Check if all critical landmarks are detected
    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null ||
        leftAnkle == null ||
        rightAnkle == null) {
      return MeasurementFrameResult.invalid('Body parts not fully visible');
    }

    // Calculate body dimensions
    final shouldersY = (leftShoulder.y + rightShoulder.y) / 2;
    final hipsY = (leftHip.y + rightHip.y) / 2;
    final anklesY = (leftAnkle.y + rightAnkle.y) / 2;

    final bodyTopY = shouldersY;
    final bodyBottomY = anklesY;
    final bodyPixelHeight = bodyBottomY - bodyTopY;

    // Calculate height ratio within frame
    final heightRatio = bodyPixelHeight / frameRect.height;

    // A) Height Ratio check (lenient)
    if (heightRatio < 0.60) {
      return MeasurementFrameResult.invalid(
          'Step closer - body too small in frame');
    }
    if (heightRatio > 1.10) {
      return MeasurementFrameResult.invalid(
          'Step back - body too large/cropped');
    }

    // B) Ankles/Feet Position (lenient)
    final anklesRelativeY = (anklesY - frameRect.top) / frameRect.height;
    if (anklesRelativeY < (BodyOverlaySpec.feetY - 0.15)) {
      return MeasurementFrameResult.invalid(
          'Move down - feet too high in frame');
    }
    if (anklesRelativeY > 1.05) {
      return MeasurementFrameResult.invalid('Move up - feet cut off at bottom');
    }

    // C) Hips Position (lenient)
    final hipsRelativeY = (hipsY - frameRect.top) / frameRect.height;
    if (hipsRelativeY < (BodyOverlaySpec.hipsY - 0.15) ||
        hipsRelativeY > (BodyOverlaySpec.hipsY + 0.15)) {
      return MeasurementFrameResult.invalid(
          'Adjust position - hips not aligned with guide');
    }

    // D) Shoulders Position (lenient)
    final shouldersRelativeY = (shouldersY - frameRect.top) / frameRect.height;
    if (shouldersRelativeY < (BodyOverlaySpec.shouldersY - 0.15) ||
        shouldersRelativeY > (BodyOverlaySpec.shouldersY + 0.15)) {
      return MeasurementFrameResult.invalid(
          'Adjust position - shoulders not aligned with guide');
    }

    // E) Check body parts are within frame horizontally
    final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
    final hipWidth = (leftHip.x - rightHip.x).abs();
    final bodyWidth = shoulderWidth > hipWidth ? shoulderWidth : hipWidth;

    // Check if body is too far left/right
    final leftMostX = [
      leftShoulder.x,
      rightShoulder.x,
      leftHip.x,
      rightHip.x,
      leftAnkle.x,
      rightAnkle.x
    ].reduce((a, b) => a < b ? a : b);

    final rightMostX = [
      leftShoulder.x,
      rightShoulder.x,
      leftHip.x,
      rightHip.x,
      leftAnkle.x,
      rightAnkle.x
    ].reduce((a, b) => a > b ? a : b);

    if (leftMostX < frameRect.left + frameRect.width * 0.05) {
      return MeasurementFrameResult.invalid(
          'Move right - body too close to left edge');
    }
    if (rightMostX > frameRect.right - frameRect.width * 0.05) {
      return MeasurementFrameResult.invalid(
          'Move left - body too close to right edge');
    }

    // Calculate body width ratio (for determining body shape preset)
    final bodyWidthRatio = bodyWidth / frameRect.width;

    // All validations passed!
    return MeasurementFrameResult.valid(
      heightRatio: heightRatio,
      bodyWidthRatio: bodyWidthRatio,
    );
  }

  /// Determine body shape preset based on body width ratio
  static String determineBodyShapePreset(double bodyWidthRatio) {
    if (bodyWidthRatio < 0.32) {
      return 'slim';
    } else if (bodyWidthRatio < 0.42) {
      return 'normal';
    } else {
      return 'heavy';
    }
  }
}
