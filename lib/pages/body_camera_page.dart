// lib/pages/body_camera_page.dart
// Phase C2: Camera Page with Real-Time Overlay Guidance
// Privacy-Safe: NO FACE DETECTION

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:bodytalk_app/main.dart';
import 'package:bodytalk_app/widgets/body_capture_overlay.dart';

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
  bool _isAligned = false;
  String? _guidanceText;

  @override
  void initState() {
    super.initState();
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
          _updateGuidanceText();
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

  void _updateGuidanceText() {
    // Simulate alignment check (in real app, would use ML Kit pose detection)
    // For now, show helpful static guidance
    if (mounted) {
      setState(() {
        _guidanceText = BodyTalkApp.tr(context,
            en: 'Step back to show full body (shoulders to feet)',
            fr: 'Reculez pour montrer tout le corps (épaules aux pieds)',
            ar: 'اتراجع للخلف لإظهار الجسم بالكامل (من الكتفين للقدمين)');
        _isAligned = false;
      });
    }

    // Simulate alignment detection after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _guidanceText = BodyTalkApp.tr(context,
              en: 'Perfect! Align body with silhouette',
              fr: 'Parfait ! Alignez le corps avec la silhouette',
              ar: 'ممتاز! وازن جسمك مع الصورة الظلية');
          _isAligned = true;
        });
      }
    });
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
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
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const deepBlue = Color(0xFF020617);
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
                  isAligned: _isAligned,
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
                  onTap: _isAligned ? _capturePhoto : null,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isAligned
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      border: Border.all(
                        color: _isAligned
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
                      color: _isAligned ? primaryBlue : Colors.white54,
                    ),
                  ),
                ),
              ),
            ),

            // Capture hint
            if (!_isAligned)
              Positioned(
                bottom: 130,
                left: 0,
                right: 0,
                child: Text(
                  BodyTalkApp.tr(context,
                      en: 'Align body first to enable capture',
                      fr: 'Alignez le corps pour activer la capture',
                      ar: 'وازن الجسم أولاً لتفعيل الالتقاط'),
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
