// lib/pages/body_analysis_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

// ✅ نستخدم ApiService الجديد بدل BodyTalkApiService
import 'package:bodytalk_app/services/api_service.dart';
import 'package:bodytalk_app/main.dart';

class BodyAnalysisPage extends StatefulWidget {
  final File imageFile;

  const BodyAnalysisPage({super.key, required this.imageFile});

  @override
  State<BodyAnalysisPage> createState() => _BodyAnalysisPageState();
}

class _BodyAnalysisPageState extends State<BodyAnalysisPage> {
  bool _loading = true;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  /// 🔥 استدعاء /analysis/body عبر ApiService الجديد
  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      // الحصول على اللغة الحالية
      final currentLang = BodyTalkApp.getLocaleCode(context) ?? 'en';
      final data = await ApiService.analyzeBodyImage(widget.imageFile,
          language: currentLang);

      if (!mounted) return;

      if (data == null) {
        setState(() {
          _loading = false;
          _result = {
            "success": false,
            "message": BodyTalkApp.tr(
              context,
              en: 'Failed to connect to server. Check your internet and server status.',
              fr: 'Échec de connexion au serveur. Vérifiez votre internet et l’état du serveur.',
              ar: 'فشل الاتصال بالسيرفر. تأكد من اتصال الإنترنت وأن السيرفر يعمل بشكل صحيح.',
            )
          };
        });
        return;
      }

      setState(() {
        _loading = false;
        // لو الـ API ما أرسل success نضيفه true افتراضيًا
        _result = {
          "success": data["success"] ?? true,
          ...data,
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _result = {
          "success": false,
          "message": BodyTalkApp.tr(
            context,
            en: 'Failed to connect to server. Check your internet and server status.',
            fr: 'Échec de connexion au serveur. Vérifiez votre internet et l’état du serveur.',
            ar: 'فشل الاتصال بالسيرفر. تأكد من اتصال الإنترنت وأن السيرفر يعمل بشكل صحيح.',
          )
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    const deepBlue = Color(0xFF020617);
    const accentOrange = Color(0xFFFF8A00);

    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: deepBlue,
        appBar: AppBar(
          backgroundColor: const Color(0xFF020617),
          foregroundColor: Colors.white,
          title: Text(BodyTalkApp.tr(context,
              en: 'Body analysis', fr: 'Analyse du corps', ar: 'تحليل الجسم')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF020617),
                Color(0xFF020617),
                Color(0xFF020617),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: _buildBody(primaryBlue, accentOrange),
        ),
      ),
    );
  }

  Widget _buildBody(Color primaryBlue, Color accentOrange) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              BodyTalkApp.tr(
                context,
                en: 'Analyzing the image with AI...',
                fr: 'Analyse de l’image avec l’IA...',
                ar: 'جاري تحليل الصورة بالذكاء الاصطناعي...',
              ),
              style: GoogleFonts.tajawal(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms),
      );
    }

    if (_result == null) {
      return Center(
        child: Text(
          BodyTalkApp.tr(
            context,
            en: 'An unexpected error occurred',
            fr: 'Une erreur inattendue s’est produite',
            ar: 'حدث خطأ غير متوقع',
          ),
          style: GoogleFonts.tajawal(color: Colors.white),
        ),
      );
    }

    if (_result!["success"] == false) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _result!["message"] ??
                BodyTalkApp.tr(
                  context,
                  en: 'Analysis error',
                  fr: 'Erreur d’analyse',
                  ar: 'خطأ في التحليل',
                ),
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    final shape = (_result!["shape"] ?? "").toString();
    final bodyFat = _num(_result!["body_fat"]);
    final muscle = _num(_result!["muscle_mass"]);
    final bmi = _num(_result!["bmi"]);
    final aspect = _num(_result!["aspect_ratio"]);
    final advice = (_result!["advice"] ?? "").toString();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          children: [
            _imageCard().animate().fadeIn(duration: 500.ms).slideY(begin: 0.15),
            const SizedBox(height: 18),
            _shapeCard(shape, primaryBlue, bmi)
                .animate()
                .fadeIn(duration: 500.ms, delay: 100.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 14),
            _statsCircles(bodyFat, muscle, primaryBlue, accentOrange)
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 14),
            _extraStats(bmi, aspect)
                .animate()
                .fadeIn(duration: 500.ms, delay: 250.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 16),
            _adviceBubble(advice, primaryBlue)
                .animate()
                .fadeIn(duration: 600.ms, delay: 300.ms)
                .slideY(begin: 0.25),
            const SizedBox(height: 16),
            // 🔹 خطة التمارين المقترحة بناءً على التحليل
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BodyTalkApp.tr(
                      context,
                      en: 'Workout plan',
                      fr: 'Plan d’entraînement',
                      ar: 'خطة التمارين',
                    ),
                    style: GoogleFonts.tajawal(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    BodyTalkApp.tr(
                      context,
                      en: 'Duration: ${((bodyFat > 26) ? 8 : (bodyFat > 22) ? 6 : 4)} weeks',
                      fr: 'Durée : ${((bodyFat > 26) ? 8 : (bodyFat > 22) ? 6 : 4)} semaines',
                      ar: 'المدة: ${((bodyFat > 26) ? 8 : (bodyFat > 22) ? 6 : 4)} أسابيع',
                    ),
                    style: GoogleFonts.tajawal(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    BodyTalkApp.tr(
                      context,
                      en: 'Focus: ${bodyFat > 26 ? 'Cardio + Calorie deficit' : bodyFat > 22 ? 'Balanced strength + cardio' : 'Strength + mobility'}',
                      fr: 'Focus : ${bodyFat > 26 ? 'Cardio + déficit calorique' : bodyFat > 22 ? 'Force équilibrée + cardio' : 'Force + mobilité'}',
                      ar: 'التركيز: ${bodyFat > 26 ? 'كارديو + عجز سعرات' : bodyFat > 22 ? 'قوة متوازنة + كارديو' : 'قوة + مرونة'}',
                    ),
                    style: GoogleFonts.tajawal(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    BodyTalkApp.tr(
                      context,
                      en: 'Weekly schedule: 3–5 days training (2–3 strength, 1–2 cardio) + daily steps 8–10k.',
                      fr: 'Programme hebdomadaire : 3–5 jours (2–3 force, 1–2 cardio) + 8–10k pas/jour.',
                      ar: 'الجدول الأسبوعي: 3–5 أيام تدريب (2–3 قوة، 1–2 كارديو) + 8–10 آلاف خطوة يومياً.',
                    ),
                    style: GoogleFonts.tajawal(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                            content: Text(BodyTalkApp.tr(
                              context,
                              en: res != null
                                  ? 'Workout plan started ✅'
                                  : 'Failed to start plan',
                              fr: res != null
                                  ? "Plan d’entraînement démarré ✅"
                                  : 'Échec du démarrage du plan',
                              ar: res != null
                                  ? 'تم بدء خطة التمارين ✅'
                                  : 'تعذّر بدء الخطة',
                            )),
                            backgroundColor:
                                res != null ? Colors.green : Colors.redAccent,
                          ),
                        );
                      },
                      icon: const Icon(Icons.flag),
                      label: Text(BodyTalkApp.tr(context,
                          en: 'Start plan',
                          fr: 'Démarrer le plan',
                          ar: 'بدء الخطة')),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 360.ms)
                .slideY(begin: 0.25),
          ],
        ),
      ),
    );
  }

  Widget _imageCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1D4ED8),
            Color(0xFF0EA5E9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(
          widget.imageFile,
          width: double.infinity,
          height: 260,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _shapeCard(String shape, Color primaryBlue, double bmi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child:
                const Icon(Icons.bolt_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  BodyTalkApp.tr(
                    context,
                    en: 'Body shape analysis',
                    fr: 'Analyse de la silhouette',
                    ar: 'تحليل شكل الجسم',
                  ),
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        shape,
                        style: GoogleFonts.tajawal(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      BodyTalkApp.tr(
                        context,
                        en: "BMI: ${bmi.toStringAsFixed(1)}",
                        fr: "IMC: ${bmi.toStringAsFixed(1)}",
                        ar: "BMI: ${bmi.toStringAsFixed(1)}",
                      ),
                      style: GoogleFonts.tajawal(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsCircles(
      double bodyFat, double muscle, Color primaryBlue, Color accent) {
    final fatPercent = (bodyFat / 50).clamp(0.0, 1.0);
    final musclePercent = (muscle / 60).clamp(0.0, 1.0);

    return Row(
      children: [
        Expanded(
          child: _circleStat(
            title: BodyTalkApp.tr(context,
                en: "Body fat", fr: "Masse grasse", ar: "نسبة الدهون"),
            valueLabel: "${bodyFat.toStringAsFixed(1)}%",
            percent: fatPercent,
            color: accent,
            icon: Icons.monitor_weight_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _circleStat(
            title: BodyTalkApp.tr(context,
                en: "Muscle mass", fr: "Masse musculaire", ar: "نسبة العضلات"),
            valueLabel: "${muscle.toStringAsFixed(1)}%",
            percent: musclePercent,
            color: primaryBlue,
            icon: Icons.fitness_center_rounded,
          ),
        ),
      ],
    );
  }

  Widget _circleStat({
    required String title,
    required String valueLabel,
    required double percent,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: percent),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 7,
                      color: color,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                    );
                  },
                ),
              ),
              Icon(icon, color: color, size: 30),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.tajawal(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valueLabel,
            style: GoogleFonts.tajawal(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _extraStats(double bmi, double aspect) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          _extraItem(
            label: BodyTalkApp.tr(context,
                en: 'Height / Width',
                fr: 'Hauteur / Largeur',
                ar: 'الطول / العرض'),
            value: aspect.toStringAsFixed(3),
          ),
        ],
      ),
    );
  }

  Widget _extraItem({required String label, required String value}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.tajawal(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.tajawal(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _adviceBubble(String advice, Color primaryBlue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [primaryBlue, primaryBlue.withValues(alpha: 0.5)],
              ),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  BodyTalkApp.tr(
                    context,
                    en: 'AI advice',
                    fr: "Conseil de l'IA",
                    ar: 'نصيحة من الذكاء الاصطناعي',
                  ),
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  advice,
                  style: GoogleFonts.tajawal(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
