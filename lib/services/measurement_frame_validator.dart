// lib/services/measurement_frame_validator.dart
// Strict measurement frame validation for body analysis
// Ensures body parts are within correct positions in the frame

import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

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
  /// Compute the measurement frame rect (same as in BodyOverlayPainter)
  static Rect computeFrameRect(Size imageSize) {
    final w = imageSize.width * 0.62;
    final h = imageSize.height * 0.62;

    final left = (imageSize.width - w) / 2;
    final top = imageSize.height * 0.22;
    return Rect.fromLTWH(left, top, w, h);
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

    // A) Strict Rules: Height Ratio
    if (heightRatio < 0.75) {
      return MeasurementFrameResult.invalid(
          'Step closer - body too small in frame');
    }
    if (heightRatio > 0.95) {
      return MeasurementFrameResult.invalid(
          'Step back - body too large/cropped');
    }

    // B) Strict Rules: Ankles Position
    // anklesY must be between frameRect.bottom - 4% and frameRect.bottom - 0%
    final anklesRelativeY = (anklesY - frameRect.top) / frameRect.height;
    if (anklesRelativeY < 0.88) {
      return MeasurementFrameResult.invalid(
          'Move down - feet too high in frame');
    }
    if (anklesRelativeY > 0.96) {
      return MeasurementFrameResult.invalid('Move up - feet cut off at bottom');
    }

    // C) Strict Rules: Hips Position
    // hipsY must be around frameRect.top + 52% ± 6%
    final hipsRelativeY = (hipsY - frameRect.top) / frameRect.height;
    if (hipsRelativeY < 0.46 || hipsRelativeY > 0.58) {
      return MeasurementFrameResult.invalid(
          'Adjust position - hips not aligned with guide');
    }

    // D) Strict Rules: Shoulders Position
    // shouldersY must be around frameRect.top + 18% ± 6%
    final shouldersRelativeY = (shouldersY - frameRect.top) / frameRect.height;
    if (shouldersRelativeY < 0.12 || shouldersRelativeY > 0.24) {
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
