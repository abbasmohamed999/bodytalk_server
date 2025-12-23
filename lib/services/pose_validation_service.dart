// lib/services/pose_validation_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseValidationResult {
  final bool isValid;
  final String? errorMessageKey;
  final double? confidence;
  final bool headVisible;
  final bool anklesVisible;
  final bool fullBodyVisible;
  final bool isSidePose;
  final bool isFrontPose;

  PoseValidationResult({
    required this.isValid,
    this.errorMessageKey,
    this.confidence,
    this.headVisible = false,
    this.anklesVisible = false,
    this.fullBodyVisible = false,
    this.isSidePose = false,
    this.isFrontPose = false,
  });

  factory PoseValidationResult.invalid(String errorKey) {
    return PoseValidationResult(isValid: false, errorMessageKey: errorKey);
  }

  factory PoseValidationResult.valid({
    double? confidence,
    bool isSidePose = false,
    bool isFrontPose = false,
  }) {
    return PoseValidationResult(
      isValid: true,
      confidence: confidence,
      headVisible: true,
      anklesVisible: true,
      fullBodyVisible: true,
      isSidePose: isSidePose,
      isFrontPose: isFrontPose,
    );
  }
}

class PoseValidationService {
  static final PoseValidationService instance = PoseValidationService._();
  PoseValidationService._();

  PoseDetector? _poseDetector;

  PoseDetector get poseDetector {
    _poseDetector ??= PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.single,
        model: PoseDetectionModel.accurate,
      ),
    );
    return _poseDetector!;
  }

  /// Validate a body photo for analysis
  /// Returns validation result with error message key if invalid
  Future<PoseValidationResult> validateBodyPhoto(
    File imageFile, {
    bool expectSidePose = false,
  }) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final poses = await poseDetector.processImage(inputImage);

      if (poses.isEmpty) {
        return PoseValidationResult.invalid('no_person_detected');
      }

      final pose = poses.first;
      final landmarks = pose.landmarks;

      // Check if key body parts are visible
      final nose = landmarks[PoseLandmarkType.nose];
      final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
      final leftHip = landmarks[PoseLandmarkType.leftHip];
      final rightHip = landmarks[PoseLandmarkType.rightHip];
      final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
      final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
      final leftEar = landmarks[PoseLandmarkType.leftEar];
      final rightEar = landmarks[PoseLandmarkType.rightEar];

      // Check head visibility (nose or ears detected)
      final headVisible = nose != null ||
          (leftEar != null && leftEar.likelihood > 0.5) ||
          (rightEar != null && rightEar.likelihood > 0.5);

      if (!headVisible) {
        return PoseValidationResult.invalid('head_not_visible');
      }

      // Check ankles visibility (at least one ankle detected)
      final anklesVisible = (leftAnkle != null && leftAnkle.likelihood > 0.4) ||
          (rightAnkle != null && rightAnkle.likelihood > 0.4);

      if (!anklesVisible) {
        return PoseValidationResult.invalid('step_back_full_body');
      }

      // Check shoulders and hips for body detection
      final shouldersVisible =
          (leftShoulder != null && leftShoulder.likelihood > 0.5) ||
              (rightShoulder != null && rightShoulder.likelihood > 0.5);

      final hipsVisible = (leftHip != null && leftHip.likelihood > 0.5) ||
          (rightHip != null && rightHip.likelihood > 0.5);

      if (!shouldersVisible || !hipsVisible) {
        return PoseValidationResult.invalid('body_not_visible');
      }

      // Detect if it's a side or front pose based on shoulder/ear positions
      bool isSidePose = false;
      bool isFrontPose = false;

      if (leftShoulder != null && rightShoulder != null) {
        // If both shoulders are visible with good confidence, it's likely front
        if (leftShoulder.likelihood > 0.7 && rightShoulder.likelihood > 0.7) {
          final shoulderWidthRatio = (leftShoulder.x - rightShoulder.x).abs() /
              (leftHip != null && rightHip != null
                  ? (leftHip.x - rightHip.x).abs()
                  : 100);
          isFrontPose = shoulderWidthRatio > 0.5;
          isSidePose = !isFrontPose;
        } else if (leftShoulder.likelihood > 0.6 ||
            rightShoulder.likelihood > 0.6) {
          // Only one shoulder clearly visible - likely side
          isSidePose = true;
        }
      } else {
        // Only one shoulder visible - side pose
        isSidePose = true;
      }

      // If we expect a side pose but got front (or vice versa), provide hint
      if (expectSidePose && isFrontPose) {
        return PoseValidationResult.invalid('turn_for_side_photo');
      } else if (!expectSidePose && isSidePose) {
        return PoseValidationResult.invalid('face_camera_front');
      }

      // Calculate overall confidence
      final confidences = [
        if (nose != null) nose.likelihood,
        if (leftShoulder != null) leftShoulder.likelihood,
        if (rightShoulder != null) rightShoulder.likelihood,
        if (leftHip != null) leftHip.likelihood,
        if (rightHip != null) rightHip.likelihood,
        if (leftAnkle != null) leftAnkle.likelihood,
        if (rightAnkle != null) rightAnkle.likelihood,
      ];

      final avgConfidence = confidences.isNotEmpty
          ? confidences.reduce((a, b) => a + b) / confidences.length
          : 0.0;

      return PoseValidationResult.valid(
        confidence: avgConfidence,
        isSidePose: isSidePose,
        isFrontPose: isFrontPose,
      );
    } catch (e) {
      debugPrint('Pose validation error: $e');
      // On error, allow the image (don't block user completely)
      return PoseValidationResult.valid(confidence: 0.5);
    }
  }

  /// Get localized error message based on error key
  static String getLocalizedError(String errorKey, String langCode) {
    final messages = {
      'no_person_detected': {
        'en': 'No person detected in the photo. Please ensure you are visible.',
        'fr':
            'Aucune personne détectée sur la photo. Assurez-vous d\'être visible.',
        'ar': 'لم يتم اكتشاف أي شخص في الصورة. تأكد من أنك ظاهر في الصورة.',
      },
      'head_not_visible': {
        'en': 'Your head is not visible. Please include your full body.',
        'fr':
            'Votre tête n\'est pas visible. Veuillez inclure votre corps entier.',
        'ar': 'رأسك غير ظاهر. يرجى تضمين جسمك بالكامل.',
      },
      'step_back_full_body': {
        'en': 'Please step back so your full body (head to feet) is visible.',
        'fr':
            'Veuillez reculer pour que tout votre corps (de la tête aux pieds) soit visible.',
        'ar':
            'يرجى التراجع للخلف حتى يظهر جسمك بالكامل (من الرأس إلى القدمين).',
      },
      'body_not_visible': {
        'en': 'Your body is not fully visible. Please adjust your position.',
        'fr':
            'Votre corps n\'est pas entièrement visible. Veuillez ajuster votre position.',
        'ar': 'جسمك غير ظاهر بالكامل. يرجى تعديل وضعيتك.',
      },
      'turn_for_side_photo': {
        'en': 'Side photo required: turn 90° to show your profile.',
        'fr':
            'Photo de profil requise : tournez-vous de 90° pour montrer votre profil.',
        'ar': 'صورة جانبية مطلوبة: استدر 90 درجة لإظهار الملف الشخصي.',
      },
      'face_camera_front': {
        'en': 'Front photo required: please face the camera directly.',
        'fr':
            'Photo de face requise : veuillez faire face à la caméra directement.',
        'ar': 'صورة أمامية مطلوبة: يرجى مواجهة الكاميرا مباشرة.',
      },
    };

    return messages[errorKey]?[langCode] ??
        messages[errorKey]?['en'] ??
        'Photo validation failed. Please try again.';
  }

  void dispose() {
    _poseDetector?.close();
    _poseDetector = null;
  }
}
