// lib/services/live_pose_validator.dart
// Live Pose Detection Validation Service for C2 Camera Overlay
// Privacy-Safe: NO FACE REQUIRED - uses shoulders, hips, knees, ankles only

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:camera/camera.dart';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';

enum LiveValidationState {
  NO_PERSON,
  PARTIAL_BODY,
  WRONG_ORIENTATION,
  TOO_CLOSE,
  TOO_FAR,
  OK_READY,
}

class LivePoseValidationResult {
  final LiveValidationState state;
  final String guidanceKey;
  final double? bodyHeightRatio; // For height calibration

  LivePoseValidationResult({
    required this.state,
    required this.guidanceKey,
    this.bodyHeightRatio,
  });
}

class LivePoseValidator {
  final PoseDetector _poseDetector;
  final bool isFrontMode;
  final double? userHeightCm; // Optional height calibration

  // Thresholds for validation
  static const double minConfidence = 0.5;
  static const double minBodyHeightRatio =
      0.40; // Body must be at least 40% of frame
  static const double maxBodyHeightRatio =
      0.85; // Body must not exceed 85% of frame
  static const double frontSymmetryThreshold =
      0.15; // 15% tolerance for front pose
  static const double sideOverlapThreshold =
      0.30; // 30% threshold for side pose detection

  LivePoseValidator({
    required this.isFrontMode,
    this.userHeightCm,
  }) : _poseDetector = PoseDetector(
          options: PoseDetectorOptions(
            mode:
                PoseDetectionMode.stream, // Use stream mode for live detection
            model: PoseDetectionModel.accurate,
          ),
        );

  Future<LivePoseValidationResult> validateFrame(CameraImage image) async {
    try {
      // Convert CameraImage to InputImage
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        return LivePoseValidationResult(
          state: LiveValidationState.NO_PERSON,
          guidanceKey: 'no_person_detected',
        );
      }

      // Detect poses
      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isEmpty) {
        return LivePoseValidationResult(
          state: LiveValidationState.NO_PERSON,
          guidanceKey: 'step_into_frame',
        );
      }

      if (poses.length > 1) {
        return LivePoseValidationResult(
          state: LiveValidationState.NO_PERSON,
          guidanceKey: 'multiple_persons_detected',
        );
      }

      final pose = poses.first;

      // Check if essential body parts are visible (Privacy-safe: NO FACE required)
      final essentialParts = _checkEssentialBodyParts(pose);
      if (!essentialParts['hasMinimumParts']!) {
        return LivePoseValidationResult(
          state: LiveValidationState.PARTIAL_BODY,
          guidanceKey: essentialParts['guidanceKey']!,
        );
      }

      // Check body size in frame
      final bodyHeightRatio =
          _calculateBodyHeightRatio(pose, image.height.toDouble());
      if (bodyHeightRatio < minBodyHeightRatio) {
        return LivePoseValidationResult(
          state: LiveValidationState.TOO_FAR,
          guidanceKey: 'step_closer_full_body',
          bodyHeightRatio: bodyHeightRatio,
        );
      }
      if (bodyHeightRatio > maxBodyHeightRatio) {
        return LivePoseValidationResult(
          state: LiveValidationState.TOO_CLOSE,
          guidanceKey: 'step_back_full_body',
          bodyHeightRatio: bodyHeightRatio,
        );
      }

      // Check orientation (front vs side)
      final orientationValid = _checkOrientation(pose);
      if (!orientationValid) {
        return LivePoseValidationResult(
          state: LiveValidationState.WRONG_ORIENTATION,
          guidanceKey:
              isFrontMode ? 'face_camera_directly' : 'turn_sideways_90',
        );
      }

      // All checks passed - OK to capture
      return LivePoseValidationResult(
        state: LiveValidationState.OK_READY,
        guidanceKey: 'ready_to_capture',
        bodyHeightRatio: bodyHeightRatio,
      );
    } catch (e) {
      return LivePoseValidationResult(
        state: LiveValidationState.NO_PERSON,
        guidanceKey: 'detection_error',
      );
    }
  }

  Map<String, dynamic> _checkEssentialBodyParts(Pose pose) {
    // Privacy-safe: Check shoulders, hips, knees, ankles - NO FACE
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    // Check shoulders (must have both)
    final hasBothShoulders = leftShoulder != null &&
        rightShoulder != null &&
        (leftShoulder.likelihood > minConfidence ||
            rightShoulder.likelihood > minConfidence);

    if (!hasBothShoulders) {
      return {'hasMinimumParts': false, 'guidanceKey': 'show_shoulders'};
    }

    // Check hips (must have at least one)
    final hasHips = (leftHip != null && leftHip.likelihood > minConfidence) ||
        (rightHip != null && rightHip.likelihood > minConfidence);

    if (!hasHips) {
      return {'hasMinimumParts': false, 'guidanceKey': 'show_full_body_hips'};
    }

    // Check at least one knee
    final hasKnee = (leftKnee != null && leftKnee.likelihood > minConfidence) ||
        (rightKnee != null && rightKnee.likelihood > minConfidence);

    if (!hasKnee) {
      return {'hasMinimumParts': false, 'guidanceKey': 'show_legs'};
    }

    // Check at least one ankle/foot
    final hasAnkle =
        (leftAnkle != null && leftAnkle.likelihood > minConfidence) ||
            (rightAnkle != null && rightAnkle.likelihood > minConfidence);

    if (!hasAnkle) {
      return {'hasMinimumParts': false, 'guidanceKey': 'show_feet'};
    }

    return {'hasMinimumParts': true, 'guidanceKey': 'ok'};
  }

  double _calculateBodyHeightRatio(Pose pose, double frameHeight) {
    // Calculate body height from shoulders to ankles
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    double? topY;
    double? bottomY;

    // Get highest shoulder point
    if (leftShoulder != null && rightShoulder != null) {
      topY = math.min(leftShoulder.y, rightShoulder.y);
    } else if (leftShoulder != null) {
      topY = leftShoulder.y;
    } else if (rightShoulder != null) {
      topY = rightShoulder.y;
    }

    // Get lowest ankle point
    if (leftAnkle != null && rightAnkle != null) {
      bottomY = math.max(leftAnkle.y, rightAnkle.y);
    } else if (leftAnkle != null) {
      bottomY = leftAnkle.y;
    } else if (rightAnkle != null) {
      bottomY = rightAnkle.y;
    }

    if (topY == null || bottomY == null) {
      return 0.0;
    }

    final bodyHeight = (bottomY - topY).abs();
    return bodyHeight / frameHeight;
  }

  bool _checkOrientation(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      return false;
    }

    if (isFrontMode) {
      // Front mode: shoulders and hips should be symmetric (facing camera)
      final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
      final hipWidth = (leftHip.x - rightHip.x).abs();

      // Check if body is roughly symmetric
      final widthRatio = shoulderWidth > 0
          ? (shoulderWidth - hipWidth).abs() / shoulderWidth
          : 0;

      // Also check depth (z-coordinate difference should be small for front pose)
      final shoulderDepthDiff = (leftShoulder.z - rightShoulder.z).abs();

      return widthRatio < frontSymmetryThreshold && shoulderDepthDiff < 100;
    } else {
      // Side mode: left and right landmarks should overlap more (90° turn)
      final shoulderOverlap = (leftShoulder.x - rightShoulder.x).abs();
      final hipOverlap = (leftHip.x - rightHip.x).abs();

      final frameWidth = math.max(leftShoulder.x, rightShoulder.x);
      final overlapRatio = frameWidth > 0
          ? (shoulderOverlap + hipOverlap) / (2 * frameWidth)
          : 1.0;

      return overlapRatio < sideOverlapThreshold;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      // Note: This is a simplified conversion
      // In production, you'd need proper rotation and format handling
      final BytesBuilder allBytes = BytesBuilder();
      for (final Plane plane in image.planes) {
        allBytes.add(plane.bytes);
      }
      final bytes = allBytes.toBytes();

      final imageRotation = InputImageRotation.rotation0deg;

      final inputImageData = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _poseDetector.close();
  }
}
