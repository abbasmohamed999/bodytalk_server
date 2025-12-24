import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bodytalk_app/main.dart';
import 'package:bodytalk_app/services/api_service.dart';
import 'package:bodytalk_app/services/pose_validation_service.dart';
import 'package:bodytalk_app/pages/body_camera_page.dart';

class BodyAnalysisCapturePage extends StatefulWidget {
  const BodyAnalysisCapturePage({super.key});

  @override
  State<BodyAnalysisCapturePage> createState() =>
      _BodyAnalysisCapturePageState();
}

class _BodyAnalysisCapturePageState extends State<BodyAnalysisCapturePage> {
  final ImagePicker _picker = ImagePicker();
  final PoseValidationService _poseService = PoseValidationService.instance;

  File? _frontImage;
  File? _sideImage;
  bool _loading = false;
  bool _validatingFront = false;
  bool _validatingSide = false;
  Map<String, dynamic>? _result;
  bool _showTip = false;

  bool get _canAnalyze =>
      _frontImage != null && _sideImage != null && !_loading;

  Future<void> _pickFrontImage(ImageSource source) async {
    try {
      File? file;

      if (source == ImageSource.camera) {
        // Use guided camera for front pose
        final capturedFile = await Navigator.push<File>(
          context,
          MaterialPageRoute(
            builder: (context) => const BodyCameraPage(isFrontMode: true),
          ),
        );
        if (capturedFile == null) return;
        file = capturedFile;
      } else {
        // Use image picker for gallery
        final picked =
            await _picker.pickImage(source: source, imageQuality: 85);
        if (picked == null) return;
        file = File(picked.path);
      }

      if (!mounted) return;

      // Validate the photo with ML Kit (C1 validation)
      setState(() => _validatingFront = true);
      final validation = await _poseService.validateBodyPhoto(
        file,
        expectSidePose: false,
      );

      if (!mounted) return;
      setState(() => _validatingFront = false);

      if (!validation.isValid) {
        final lang = BodyTalkApp.getLocaleCode(context) ?? 'en';
        final errorMsg = PoseValidationService.getLocalizedError(
          validation.errorMessageKey!,
          lang,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      setState(() {
        _frontImage = file;
        _result = null;
      });
    } catch (e) {
      debugPrint('Error picking front image: $e');
      if (mounted) setState(() => _validatingFront = false);
    }
  }

  Future<void> _pickSideImage(ImageSource source) async {
    try {
      File? file;

      if (source == ImageSource.camera) {
        // Use guided camera for side pose
        final capturedFile = await Navigator.push<File>(
          context,
          MaterialPageRoute(
            builder: (context) => const BodyCameraPage(isFrontMode: false),
          ),
        );
        if (capturedFile == null) return;
        file = capturedFile;
      } else {
        // Use image picker for gallery
        final picked =
            await _picker.pickImage(source: source, imageQuality: 85);
        if (picked == null) return;
        file = File(picked.path);
      }

      if (!mounted) return;

      // Validate the photo with ML Kit (C1 validation)
      setState(() => _validatingSide = true);
      final validation = await _poseService.validateBodyPhoto(
        file,
        expectSidePose: true,
      );

      if (!mounted) return;
      setState(() => _validatingSide = false);

      if (!validation.isValid) {
        final lang = BodyTalkApp.getLocaleCode(context) ?? 'en';
        final errorMsg = PoseValidationService.getLocalizedError(
          validation.errorMessageKey!,
          lang,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      setState(() {
        _sideImage = file;
        _result = null;
      });
    } catch (e) {
      debugPrint('Error picking side image: $e');
      if (mounted) setState(() => _validatingSide = false);
    }
  }

  Future<void> _analyze() async {
    if (!_canAnalyze) return;

    // Check subscription
    if (ApiService.isLoggedIn) {
      final sub = await ApiService.getSubscriptionStatus();
      if (sub != null && sub['is_active'] != true) {
        final activated = await ApiService.activateTestSubscription();
        if (activated == null || activated['is_active'] != true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(BodyTalkApp.tr(context,
                  en: 'Subscription inactive. Please subscribe first.',
                  fr: 'Abonnement inactif. Veuillez vous abonner.',
                  ar: 'الاشتراك غير مفعّل. الرجاء الاشتراك أولاً.')),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }
    }

    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      // ignore: use_build_context_synchronously
      final currentLang = BodyTalkApp.getLocaleCode(context) ?? 'en';
      final data = await ApiService.analyzeBodyTwoImages(
        _frontImage!,
        _sideImage!,
        language: currentLang,
      );

      if (!mounted) return;

      if (data == null) {
        setState(() {
          _loading = false;
          _result = {
            "success": false,
            "message": BodyTalkApp.tr(context,
                en: 'Failed to connect to server.',
                fr: 'Échec de connexion au serveur.',
                ar: 'فشل الاتصال بالسيرفر.')
          };
        });
        return;
      }

      setState(() {
        _loading = false;
        _result = {"success": data["success"] ?? true, ...data};
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _result = {
          "success": false,
          "message": BodyTalkApp.tr(context,
              en: 'An error occurred during analysis.',
              fr: "Une erreur s'est produite lors de l'analyse.",
              ar: 'حدث خطأ أثناء التحليل.')
        };
      });
    }
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    const deepBlue = Color(0xFF020617);
    const primaryBlue = Color(0xFF2563EB);
    const accentOrange = Color(0xFFFF8A00);

    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: deepBlue,
        appBar: AppBar(
          backgroundColor: deepBlue,
          foregroundColor: Colors.white,
          title: Text(BodyTalkApp.tr(context,
              en: 'Body Analysis', fr: 'Analyse du Corps', ar: 'تحليل الجسم')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              children: [
                // Collapsible Tip
                _buildTipSection(primaryBlue),
                const SizedBox(height: 16),

                // Photo Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildPhotoCard(
                        title: BodyTalkApp.tr(context,
                            en: 'Front Photo',
                            fr: 'Photo de Face',
                            ar: 'صورة أمامية'),
                        image: _frontImage,
                        onCamera: () => _pickFrontImage(ImageSource.camera),
                        onGallery: () => _pickFrontImage(ImageSource.gallery),
                        primaryBlue: primaryBlue,
                        isValidating: _validatingFront,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPhotoCard(
                        title: BodyTalkApp.tr(context,
                            en: 'Side Photo',
                            fr: 'Photo de Profil',
                            ar: 'صورة جانبية'),
                        image: _sideImage,
                        onCamera: () => _pickSideImage(ImageSource.camera),
                        onGallery: () => _pickSideImage(ImageSource.gallery),
                        primaryBlue: primaryBlue,
                        isValidating: _validatingSide,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                // Analyze Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _canAnalyze ? _analyze : null,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.analytics_rounded),
                    label: Text(
                      _loading
                          ? BodyTalkApp.tr(context,
                              en: 'Analyzing...',
                              fr: 'Analyse en cours...',
                              ar: 'جاري التحليل...')
                          : BodyTalkApp.tr(context,
                              en: 'Analyze Body',
                              fr: 'Analyser le Corps',
                              ar: 'تحليل الجسم'),
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canAnalyze ? accentOrange : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                const SizedBox(height: 20),

                // Results Section
                if (_result != null)
                  _buildResultSection(primaryBlue, accentOrange),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipSection(Color primaryBlue) {
    return GestureDetector(
      onTap: () => setState(() => _showTip = !_showTip),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primaryBlue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryBlue.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    BodyTalkApp.tr(context,
                        en: 'Tip for better results',
                        fr: 'Conseil pour de meilleurs résultats',
                        ar: 'نصيحة للحصول على نتائج أفضل'),
                    style: GoogleFonts.tajawal(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _showTip ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70,
                ),
              ],
            ),
            if (_showTip) ...[
              const SizedBox(height: 8),
              Text(
                BodyTalkApp.tr(context,
                    en: 'Full body required: shoulders, hips, knees, and feet visible. Face NOT required (privacy-safe). Good lighting, simple background, fitted clothing.',
                    fr: 'Corps entier requis : épaules, hanches, genoux et pieds visibles. Visage NON requis (respect de la vie privée). Bon éclairage, fond simple, vêtements ajustés.',
                    ar: 'جسم كامل مطلوب: كتفين، وركين، ركبتين وقدمين ظاهرة. الوجه غير مطلوب (حفظ الخصوصية). إضاءة جيدة، خلفية بسيطة، ملابس محددة.'),
                style: GoogleFonts.tajawal(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard({
    required String title,
    required File? image,
    required VoidCallback onCamera,
    required VoidCallback onGallery,
    required Color primaryBlue,
    bool isValidating = false,
  }) {
    final isValid = image != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValid
              ? Colors.green.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.12),
          width: isValid ? 2.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isValid)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withValues(alpha: 0.3),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: isValidating
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 10),
                          Text(
                            BodyTalkApp.tr(context,
                                en: 'Validating...',
                                fr: 'Validation...',
                                ar: 'جاري التحقق...'),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(image, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_outline,
                                color: Colors.white38, size: 40),
                            const SizedBox(height: 6),
                            Text(
                              BodyTalkApp.tr(context,
                                  en: 'Required', fr: 'Requis', ar: 'مطلوب'),
                              style: GoogleFonts.tajawal(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _miniButton(
                  icon: Icons.camera_alt,
                  label: BodyTalkApp.tr(context,
                      en: 'Camera', fr: 'Caméra', ar: 'كاميرا'),
                  onTap: (_loading || isValidating) ? null : onCamera,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _miniButton(
                  icon: Icons.photo_library,
                  label: BodyTalkApp.tr(context,
                      en: 'Gallery', fr: 'Galerie', ar: 'معرض'),
                  onTap: (_loading || isValidating) ? null : onGallery,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(Color primaryBlue, Color accentOrange) {
    if (_result!["success"] == false) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _result!["message"] ?? 'Error',
                style: GoogleFonts.tajawal(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms);
    }

    final shape = (_result!["shape"] ?? "").toString();
    final bodyFat = _num(_result!["body_fat"]);
    final muscle = _num(_result!["muscle_mass"]);
    final bmi = _num(_result!["bmi"]);
    final advice = (_result!["advice"] ?? "").toString();

    return Column(
      children: [
        // Shape & BMI Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.green.withValues(alpha: 0.6)],
                  ),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shape,
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'BMI: ${bmi.toStringAsFixed(1)}',
                      style: GoogleFonts.tajawal(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 12),

        // Metrics Row
        Row(
          children: [
            Expanded(
              child: _metricCard(
                title: BodyTalkApp.tr(context,
                    en: 'Body Fat', fr: 'Masse Grasse', ar: 'نسبة الدهون'),
                value: '${bodyFat.toStringAsFixed(1)}%',
                icon: Icons.monitor_weight_outlined,
                color: accentOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                title: BodyTalkApp.tr(context,
                    en: 'Muscle', fr: 'Muscle', ar: 'العضلات'),
                value: '${muscle.toStringAsFixed(1)}%',
                icon: Icons.fitness_center_rounded,
                color: primaryBlue,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

        const SizedBox(height: 12),

        // Advice Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [primaryBlue, primaryBlue.withValues(alpha: 0.5)],
                  ),
                ),
                child: const Icon(Icons.smart_toy_outlined,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      BodyTalkApp.tr(context,
                          en: 'AI Advice',
                          fr: "Conseil de l'IA",
                          ar: 'نصيحة الذكاء الاصطناعي'),
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      advice,
                      style: GoogleFonts.tajawal(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

        const SizedBox(height: 12),

        // Save Plan Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final durationWeeks = (bodyFat > 26)
                  ? 8
                  : (bodyFat > 22)
                      ? 6
                      : 4;
              final focus = bodyFat > 26
                  ? 'cardio_deficit'
                  : (bodyFat > 22)
                      ? 'balanced_strength_cardio'
                      : 'strength_mobility';

              final res = await ApiService.saveWorkoutPlan(
                durationWeeks: durationWeeks,
                focus: focus,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(BodyTalkApp.tr(context,
                      en: res != null
                          ? 'Workout plan saved!'
                          : 'Failed to save plan',
                      fr: res != null
                          ? 'Plan enregistré!'
                          : "Échec de l'enregistrement",
                      ar: res != null ? 'تم حفظ الخطة!' : 'فشل الحفظ')),
                  backgroundColor: res != null ? Colors.green : Colors.red,
                ),
              );
            },
            icon: const Icon(Icons.flag_rounded),
            label: Text(BodyTalkApp.tr(context,
                en: 'Start Workout Plan',
                fr: "Démarrer le Plan d'Entraînement",
                ar: 'بدء خطة التمارين')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.tajawal(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.tajawal(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
