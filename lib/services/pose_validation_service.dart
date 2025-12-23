// lib/services/pose_validation_service.dart
// STRICT BODY ANALYSIS GATE - NO FACE REQUIRED (Privacy-Safe)
// Phase C1: Validation Rules Implementation

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseValidationResult {
  final bool isValid;
  final String? errorMessageKey;
  final double? confidence;
  final bool shouldersVisible;
  final bool hipsVisible;
  final bool kneesVisible;
  final bool anklesVisible;
  final bool torsoComplete;
  final bool fullBodyVisible;
  final bool isSidePose;
  final bool isFrontPose;
  final bool multiplePersons;
  final String? debugInfo;

  PoseValidationResult({
    required this.isValid,
    this.errorMessageKey,
    this.confidence,
    this.shouldersVisible = false,
    this.hipsVisible = false,
    this.kneesVisible = false,
    this.anklesVisible = false,
    this.torsoComplete = false,
    this.fullBodyVisible = false,
    this.isSidePose = false,
    this.isFrontPose = false,
    this.multiplePersons = false,
    this.debugInfo,
  });

  factory PoseValidationResult.invalid(String errorKey, {String? debugInfo}) {
    return PoseValidationResult(
      isValid: false,
      errorMessageKey: errorKey,
      debugInfo: debugInfo,
    );
  }

  factory PoseValidationResult.valid({
    required double confidence,
    required bool isSidePose,
    required bool isFrontPose,
    required bool shouldersVisible,
    required bool hipsVisible,
    required bool kneesVisible,
    required bool anklesVisible,
    required bool torsoComplete,
    String? debugInfo,
  }) {
    return PoseValidationResult(
      isValid: true,
      confidence: confidence,
      shouldersVisible: shouldersVisible,
      hipsVisible: hipsVisible,
      kneesVisible: kneesVisible,
      anklesVisible: anklesVisible,
      torsoComplete: torsoComplete,
      fullBodyVisible: true,
      isSidePose: isSidePose,
      isFrontPose: isFrontPose,
      debugInfo: debugInfo,
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

  /// Validate a body photo for analysis - STRICT MODE
  /// Privacy-Safe: NO FACE REQUIRED
  /// Returns validation result with error message key if invalid
  Future<PoseValidationResult> validateBodyPhoto(
    File imageFile, {
    bool expectSidePose = false,
  }) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final poses = await poseDetector.processImage(inputImage);

      // RULE: Multiple persons detected
      if (poses.length > 1) {
        return PoseValidationResult.invalid(
          'multiple_persons',
          debugInfo: 'Detected ${poses.length} persons',
        );
      }

      // RULE: No person detected
      if (poses.isEmpty) {
        return PoseValidationResult.invalid(
          'no_person_detected',
          debugInfo: 'No pose detected by ML Kit',
        );
      }

      final pose = poses.first;
      final landmarks = pose.landmarks;

      // Extract key landmarks (NO FACE REQUIRED)
      final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
      final leftHip = landmarks[PoseLandmarkType.leftHip];
      final rightHip = landmarks[PoseLandmarkType.rightHip];
      final leftKnee = landmarks[PoseLandmarkType.leftKnee];
      final rightKnee = landmarks[PoseLandmarkType.rightKnee];
      final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
      final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];

      // STRICT VALIDATION - Each body part must be detected with high confidence
      const minConfidence = 0.5;

      // RULE 1: SHOULDERS must be visible
      final shouldersVisible = (leftShoulder != null &&
              leftShoulder.likelihood > minConfidence) ||
          (rightShoulder != null && rightShoulder.likelihood > minConfidence);

      if (!shouldersVisible) {
        return PoseValidationResult.invalid(
          'shoulders_not_detected',
          debugInfo: 'Shoulders confidence too low',
        );
      }

      // RULE 2: HIPS must be visible
      final hipsVisible =
          (leftHip != null && leftHip.likelihood > minConfidence) ||
              (rightHip != null && rightHip.likelihood > minConfidence);

      if (!hipsVisible) {
        return PoseValidationResult.invalid(
          'hips_not_detected',
          debugInfo: 'Hips confidence too low',
        );
      }

      // RULE 3: KNEES must be visible
      final kneesVisible =
          (leftKnee != null && leftKnee.likelihood > minConfidence) ||
              (rightKnee != null && rightKnee.likelihood > minConfidence);

      if (!kneesVisible) {
        return PoseValidationResult.invalid(
          'knees_not_detected',
          debugInfo: 'Knees confidence too low',
        );
      }

      // RULE 4: ANKLES must be visible (feet visible)
      final anklesVisible =
          (leftAnkle != null && leftAnkle.likelihood > minConfidence) ||
              (rightAnkle != null && rightAnkle.likelihood > minConfidence);

      if (!anklesVisible) {
        return PoseValidationResult.invalid(
          'ankles_not_detected',
          debugInfo: 'Ankles/feet confidence too low',
        );
      }

      // RULE 5: Torso must be complete (shoulders + hips)
      final torsoComplete = shouldersVisible && hipsVisible;

      if (!torsoComplete) {
        return PoseValidationResult.invalid(
          'torso_incomplete',
          debugInfo: 'Shoulders or hips missing',
        );
      }

      // RULE 6: Check body cropping - ensure full body is in frame
      // If ankles are too low confidence while rest is good, body might be cropped
      final avgUpperConfidence = [
            if (leftShoulder != null) leftShoulder.likelihood,
            if (rightShoulder != null) rightShoulder.likelihood,
            if (leftHip != null) leftHip.likelihood,
            if (rightHip != null) rightHip.likelihood,
          ].fold(0.0, (a, b) => a + b) /
          4;

      final avgLowerConfidence = [
            if (leftKnee != null) leftKnee.likelihood,
            if (rightKnee != null) rightKnee.likelihood,
            if (leftAnkle != null) leftAnkle.likelihood,
            if (rightAnkle != null) rightAnkle.likelihood,
          ].fold(0.0, (a, b) => a + b) /
          4;

      // If upper body is detected well but lower body is poor, likely cropped
      if (avgUpperConfidence > 0.7 && avgLowerConfidence < 0.3) {
        return PoseValidationResult.invalid(
          'body_cropped_lower',
          debugInfo: 'Lower body appears cropped',
        );
      }

      // RULE 7: Detect orientation (Front vs Side)
      bool isSidePose = false;
      bool isFrontPose = false;

      if (leftShoulder != null &&
          rightShoulder != null &&
          leftShoulder.likelihood > 0.6 &&
          rightShoulder.likelihood > 0.6) {
        // Both shoulders visible with good confidence = FRONT pose
        final shoulderDistance = (leftShoulder.x - rightShoulder.x).abs();
        final hipDistance = (leftHip != null && rightHip != null)
            ? (leftHip.x - rightHip.x).abs()
            : shoulderDistance;

        // Front pose: shoulders are wider apart relative to hips
        if (shoulderDistance > hipDistance * 0.5) {
          isFrontPose = true;
        } else {
          isSidePose = true;
        }
      } else {
        // Only one shoulder clearly visible = SIDE pose
        isSidePose = true;
      }

      // RULE 8: Validate expected orientation
      if (expectSidePose && isFrontPose) {
        return PoseValidationResult.invalid(
          'turn_for_side_photo',
          debugInfo: 'Expected side, got front',
        );
      }

      if (!expectSidePose && isSidePose) {
        return PoseValidationResult.invalid(
          'face_camera_front',
          debugInfo: 'Expected front, got side',
        );
      }

      // Calculate overall confidence for debug
      final allConfidences = [
        if (leftShoulder != null) leftShoulder.likelihood,
        if (rightShoulder != null) rightShoulder.likelihood,
        if (leftHip != null) leftHip.likelihood,
        if (rightHip != null) rightHip.likelihood,
        if (leftKnee != null) leftKnee.likelihood,
        if (rightKnee != null) rightKnee.likelihood,
        if (leftAnkle != null) leftAnkle.likelihood,
        if (rightAnkle != null) rightAnkle.likelihood,
      ];

      final avgConfidence = allConfidences.isNotEmpty
          ? allConfidences.reduce((a, b) => a + b) / allConfidences.length
          : 0.0;

      // ALL RULES PASSED - Photo is VALID
      return PoseValidationResult.valid(
        confidence: avgConfidence,
        isSidePose: isSidePose,
        isFrontPose: isFrontPose,
        shouldersVisible: shouldersVisible,
        hipsVisible: hipsVisible,
        kneesVisible: kneesVisible,
        anklesVisible: anklesVisible,
        torsoComplete: torsoComplete,
        debugInfo: kDebugMode
            ? 'Valid: conf=${avgConfidence.toStringAsFixed(2)} '
                '${isFrontPose ? "FRONT" : "SIDE"}'
            : null,
      );
    } catch (e) {
      debugPrint('❌ Pose validation error: $e');
      // STRICT MODE: On error, REJECT (don't allow)
      return PoseValidationResult.invalid(
        'validation_error',
        debugInfo: 'ML Kit error: $e',
      );
    }
  }

  /// Get localized error message based on error key
  /// Privacy-Safe: NO FACE REQUIRED messages
  static String getLocalizedError(String errorKey, String langCode) {
    final messages = {
      'no_person_detected': {
        'en': 'No person detected. Please ensure your full body is visible.',
        'fr':
            'Aucune personne détectée. Assurez-vous que votre corps entier est visible.',
        'ar': 'لم يتم اكتشاف أي شخص. تأكد من ظهور جسمك بالكامل.',
      },
      'multiple_persons': {
        'en': 'Multiple people detected. Only one person allowed per photo.',
        'fr':
            'Plusieurs personnes détectées. Une seule personne autorisée par photo.',
        'ar': 'تم اكتشاف عدة أشخاص. يسمح بشخص واحد فقط في كل صورة.',
      },
      'shoulders_not_detected': {
        'en':
            'Shoulders not detected. Please ensure your shoulders are visible.',
        'fr':
            'Épaules non détectées. Assurez-vous que vos épaules sont visibles.',
        'ar': 'لم يتم اكتشاف الكتفين. تأكد من ظهور كتفيك.',
      },
      'hips_not_detected': {
        'en': 'Hips not detected. Please ensure your torso is fully visible.',
        'fr':
            'Hanches non détectées. Assurez-vous que votre torse est entièrement visible.',
        'ar': 'لم يتم اكتشاف الوركين. تأكد من ظهور جذعك بالكامل.',
      },
      'knees_not_detected': {
        'en': 'Knees not detected. Please step back to show your full body.',
        'fr':
            'Genoux non détectés. Veuillez reculer pour montrer tout votre corps.',
        'ar': 'لم يتم اكتشاف الركبتين. اتراجع للخلف لإظهار جسمك بالكامل.',
      },
      'ankles_not_detected': {
        'en':
            'Feet not visible. Please step back so your full body (shoulders to feet) is visible.',
        'fr':
            'Pieds non visibles. Veuillez reculer pour que tout votre corps (épaules aux pieds) soit visible.',
        'ar':
            'القدمين غير ظاهرتين. اتراجع للخلف حتى يظهر جسمك بالكامل (من الكتفين إلى القدمين).',
      },
      'torso_incomplete': {
        'en': 'Your torso is not fully visible. Please adjust your position.',
        'fr':
            'Votre torse n\'est pas entièrement visible. Veuillez ajuster votre position.',
        'ar': 'جذعك غير ظاهر بالكامل. يرجى تعديل وضعيتك.',
      },
      'body_cropped_lower': {
        'en':
            'Lower body appears cropped. Please step back to include your feet.',
        'fr':
            'Le bas du corps semble coupé. Veuillez reculer pour inclure vos pieds.',
        'ar': 'يبدو الجزء السفلي من الجسم مقطوعاً. تراجع للخلف لتضمين قدميك.',
      },
      'turn_for_side_photo': {
        'en': 'Side photo required: Please turn 90° to show your profile.',
        'fr':
            'Photo de profil requise : Veuillez tourner de 90° pour montrer votre profil.',
        'ar': 'صورة جانبية مطلوبة: يرجى الاستدارة 90° لإظهار ملفك الشخصي.',
      },
      'face_camera_front': {
        'en': 'Front photo required: Please face the camera directly.',
        'fr':
            'Photo de face requise : Veuillez faire face à la caméra directement.',
        'ar': 'صورة أمامية مطلوبة: يرجى مواجهة الكاميرا مباشرة.',
      },
      'validation_error': {
        'en':
            'Unable to validate photo. Please try again with better lighting.',
        'fr':
            'Impossible de valider la photo. Veuillez réessayer avec un meilleur éclairage.',
        'ar': 'تعذر التحقق من الصورة. يرجى المحاولة مرة أخرى مع إضاءة أفضل.',
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
