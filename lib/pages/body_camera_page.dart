// lib/pages/body_camera_page.dart
// Phase C2.1: Camera Page with LIVE Pose Detection and Strict Gating
// Privacy-Safe: NO FACE REQUIRED - uses shoulders, hips, knees, ankles only

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:bodytalk_app/main.dart';
import 'package:bodytalk_app/widgets/body_capture_overlay.dart';
import 'package:bodytalk_app/services/live_pose_validator.dart';

class BodyCameraPage extends StatefulWidget {
  final bool isFrontMode; // true = front pose, false = side pose

  const BodyCameraPage({
    super.key,
    required this.isFrontMode,
  });

  @override
  State<BodyCameraPage> createState() => _BodyCameraPageState();
}

class _BodyCameraPageState extends State<BodyCameraPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  LiveValidationState _validationState = LiveValidationState.NO_PERSON;
  String? _guidanceText;
  LivePoseValidator? _poseValidator;
  Timer? _validationTimer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _poseValidator = LivePoseValidator(isFrontMode: widget.isFrontMode);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          setState(() {
            _guidanceText = 'No camera available';
          });
        }
        return;
      }

      // Use back camera for body photos
      final camera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Start image stream for live pose detection
        _controller!.startImageStream((CameraImage image) {
          if (!_isProcessing) {
            _processFrameForValidation(image);
          }
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _guidanceText = 'Camera error: $e';
        });
      }
    }
  }

  Future<void> _processFrameForValidation(CameraImage image) async {
    _isProcessing = true;
    try {
      final result = await _poseValidator!.validateFrame(image);

      if (mounted) {
        setState(() {
          _validationState = result.state;
          _guidanceText = _getLocalizedGuidance(result.guidanceKey);
        });
      }
    } catch (e) {
      // Silently handle errors during live detection
    } finally {
      // Add delay to throttle to ~3-5 FPS
      await Future.delayed(const Duration(milliseconds: 250));
      _isProcessing = false;
    }
  }

  String _getLocalizedGuidance(String key) {
    switch (key) {
      case 'no_person_detected':
      case 'step_into_frame':
        return BodyTalkApp.tr(context,
            en: 'Step into frame',
            fr: 'Entrez dans le cadre',
            ar: 'ادخل إلى الإطار');
      case 'multiple_persons_detected':
        return BodyTalkApp.tr(context,
            en: 'Only one person allowed',
            fr: 'Une seule personne autorisée',
            ar: 'شخص واحد فقط مسموح');
      case 'show_shoulders':
        return BodyTalkApp.tr(context,
            en: 'Show both shoulders',
            fr: 'Montrez les deux épaules',
            ar: 'أظهر كلا الكتفين');
      case 'show_full_body_hips':
        return BodyTalkApp.tr(context,
            en: 'Show full body including hips',
            fr: 'Montrez tout le corps y compris les hanches',
            ar: 'أظهر الجسم كاملاً بما في ذلك الوركين');
      case 'show_legs':
        return BodyTalkApp.tr(context,
            en: 'Show legs and knees',
            fr: 'Montrez les jambes et les genoux',
            ar: 'أظهر الساقين والركبتين');
      case 'show_feet':
        return BodyTalkApp.tr(context,
            en: 'Show feet - full body required',
            fr: 'Montrez les pieds - corps entier requis',
            ar: 'أظهر القدمين - الجسم الكامل مطلوب');
      case 'step_closer_full_body':
        return BodyTalkApp.tr(context,
            en: 'Step closer - body too small',
            fr: 'Approchez-vous - corps trop petit',
            ar: 'اقترب - الجسم صغير جداً');
      case 'step_back_full_body':
        return BodyTalkApp.tr(context,
            en: 'Step back - show full body',
            fr: 'Reculez - montrez tout le corps',
            ar: 'ابتعد - أظهر الجسم كاملاً');
      case 'face_camera_directly':
        return BodyTalkApp.tr(context,
            en: 'Face camera directly',
            fr: 'Faites face à la caméra',
            ar: 'واجه الكاميرا مباشرة');
      case 'turn_sideways_90':
        return BodyTalkApp.tr(context,
            en: 'Turn sideways 90°',
            fr: 'Tournez-vous de 90°',
            ar: 'استدر 90 درجة');
      case 'ready_to_capture':
        return BodyTalkApp.tr(context,
            en: 'Ready! Tap to capture',
            fr: 'Prêt ! Appuyez pour capturer',
            ar: 'جاهز! اضغط للالتقاط');
      default:
        return BodyTalkApp.tr(context,
            en: 'Position your body',
            fr: 'Positionnez votre corps',
            ar: 'ضع جسمك في الموضع');
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      // Stop image stream before capturing
      await _controller!.stopImageStream();

      final image = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, File(image.path));
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Restart image stream
        _controller!.startImageStream((image) {
          if (!_isProcessing) {
            _processFrameForValidation(image);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _validationTimer?.cancel();
    _poseValidator?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview
            if (_isInitialized && _controller != null)
              Positioned.fill(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: CameraPreview(_controller!),
                ),
              ),

            // Loading indicator
            if (!_isInitialized)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Overlay guidance
            if (_isInitialized)
              Positioned.fill(
                child: BodyCaptureOverlay(
                  isFrontMode: widget.isFrontMode,
                  validationState: _validationState,
                  guidanceText: _guidanceText,
                ),
              ),

            // Top bar with back button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
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

            // Bottom capture button
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _validationState == LiveValidationState.OK_READY
                      ? _capturePhoto
                      : null,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _validationState == LiveValidationState.OK_READY
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      border: Border.all(
                        color: _validationState == LiveValidationState.OK_READY
                            ? Colors.green
                            : Colors.white.withValues(alpha: 0.5),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 40,
                      color: _validationState == LiveValidationState.OK_READY
                          ? primaryBlue
                          : Colors.white54,
                    ),
                  ),
                ),
              ),
            ),

            // Capture hint
            if (_validationState != LiveValidationState.OK_READY)
              Positioned(
                bottom: 130,
                left: 0,
                right: 0,
                child: Text(
                  BodyTalkApp.tr(context,
                      en: 'Align full body to enable capture',
                      fr: 'Alignez le corps entier pour activer',
                      ar: 'وازن الجسم كاملاً لتفعيل الالتقاط'),
                  style: GoogleFonts.tajawal(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
