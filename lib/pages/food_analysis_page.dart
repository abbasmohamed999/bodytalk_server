// lib/pages/food_analysis_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import 'package:bodytalk_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FoodAnalysisPage extends StatefulWidget {
  const FoodAnalysisPage({super.key});

  @override
  State<FoodAnalysisPage> createState() => _FoodAnalysisPageState();
}

class _FoodAnalysisPageState extends State<FoodAnalysisPage> {
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  bool _loading = false;
  Map<String, dynamic>? _result;
  String _selectedCuisine = 'general'; // Default cuisine

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() {
        _imageFile = File(picked.path);
        _result = null; // نعيد تعيين النتيجة
        _loading = false; // لا تحليل تلقائي
      });
    } catch (_) {}
  }

  /// 🔥 دالة التحليل بعد التعديل لتتعامل مع Map بدلاً من http.Response
  Future<void> _analyze() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            BodyTalkApp.tr(
              context,
              en: 'Pick a meal image first.',
              fr: "Choisissez d'abord une image du repas.",
              ar: 'اختر صورة للوجبة أولاً.',
            ),
            style: GoogleFonts.tajawal(),
          ),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      // الحصول على اللغة الحالية
      final currentLang = BodyTalkApp.getLocaleCode(context) ?? 'en';
      // الآن الدالة ترجع Map<String, dynamic>؟
      final data = await ApiService.analyzeFoodImage(
        _imageFile!,
        language: currentLang,
        cuisine: _selectedCuisine,
      );

      if (!mounted) return;

      if (data == null) {
        // فشل الاتصال أو خطأ في السيرفر
        setState(() {
          _loading = false;
          _result = {
            "success": false,
            "message": BodyTalkApp.tr(context,
                en: 'Failed to connect to server. Check your internet and server status.',
                fr: 'Échec de connexion au serveur. Vérifiez votre internet et l’état du serveur.',
                ar: 'فشل الاتصال بالسيرفر. تأكد من اتصال الإنترنت وأن السيرفر يعمل.'),
          };
        });
        return;
      }

      setState(() {
        _loading = false;
        // لو الـ API يرجع success: true سنستخدمه، وإذا ما رجعه نضيفه يدويًا
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
          "message": BodyTalkApp.tr(context,
              en: 'An error occurred while analyzing the meal. Please try again.',
              fr: "Une erreur s'est produite lors de l'analyse du repas. Veuillez réessayer.",
              ar: 'حدث خطأ أثناء تحليل الوجبة. حاول مرة أخرى.')
        };
      });
    }
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
          backgroundColor: const Color(0xFF020617),
          foregroundColor: Colors.white,
          title: Text(BodyTalkApp.tr(context,
              en: 'Food analysis from images',
              fr: 'Analyse des aliments à partir d’images',
              ar: 'تحليل الأكل بالصور')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [deepBlue, deepBlue, deepBlue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                children: [
                  _mealImageCard()
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.15),
                  const SizedBox(height: 18),
                  _infoCard(primaryBlue)
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 100.ms)
                      .slideY(begin: 0.2),
                  const SizedBox(height: 16),
                  _cuisineSelectorCard(primaryBlue)
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 110.ms)
                      .slideY(begin: 0.2),
                  const SizedBox(height: 16),
                  _buttonsSection(accentOrange)
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 150.ms)
                      .slideY(begin: 0.2),
                  const SizedBox(height: 18),
                  _buildResultSection(primaryBlue, accentOrange),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mealImageCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        color: Colors.white.withValues(alpha: 0.02),
      ),
      padding: const EdgeInsets.all(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            color: Colors.black.withValues(alpha: 0.3),
          ),
          child: _imageFile == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_rounded,
                        color: Colors.white.withValues(alpha: 0.7), size: 44),
                    const SizedBox(height: 10),
                    Text(
                      BodyTalkApp.tr(
                        context,
                        en: 'No meal image selected yet',
                        fr: 'Aucune image du repas sélectionnée pour le moment',
                        ar: 'لم يتم اختيار صورة للوجبة بعد',
                      ),
                      style: GoogleFonts.tajawal(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      BodyTalkApp.tr(
                        context,
                        en: 'Choose a clear photo of the dish so the AI can analyze it accurately.',
                        fr: "Choisissez une photo claire du plat pour que l'IA puisse l'analyser avec précision.",
                        ar: 'اختر صورة واضحة للطبق حتى يتمكن الذكاء الاصطناعي من تحليله بدقة.',
                      ),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.tajawal(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(
                    _imageFile!,
                    fit: BoxFit.cover,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _infoCard(Color primaryBlue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
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
            child: const Icon(Icons.info_outline, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  BodyTalkApp.tr(
                    context,
                    en: 'Food analysis from image',
                    fr: 'Analyse des aliments à partir d’une image',
                    ar: 'تحليل الأكل من الصورة',
                  ),
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  BodyTalkApp.tr(
                    context,
                    en: 'Recognize your meal from the image and estimate calories and macros (protein, carbs, fats) using AI.',
                    fr: "Reconnaître votre repas à partir de l'image et estimer les calories et macronutriments (protéines, glucides, lipides) à l'aide de l'IA.",
                    ar: 'التعرف على وجبتك من الصورة، وحساب السعرات وتوزيع العناصر الغذائية (بروتين، كارب، دهون) باستخدام الذكاء الاصطناعي.',
                  ),
                  style: GoogleFonts.tajawal(
                    color: Colors.white70,
                    fontSize: 12,
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

  Widget _cuisineSelectorCard(Color primaryBlue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            BodyTalkApp.tr(context,
                en: 'Cuisine type', fr: 'Type de cuisine', ar: 'نوع المطبخ'),
            style: GoogleFonts.tajawal(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedCuisine,
            dropdownColor: const Color(0xFF020617),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
            ),
            items: [
              DropdownMenuItem(
                value: 'general',
                child: Text(BodyTalkApp.tr(context,
                    en: 'General', fr: 'Général', ar: 'عام')),
              ),
              DropdownMenuItem(
                value: 'arabic',
                child: Text(BodyTalkApp.tr(context,
                    en: 'Arabic', fr: 'Arabe', ar: 'عربي')),
              ),
              DropdownMenuItem(
                value: 'italian',
                child: Text(BodyTalkApp.tr(context,
                    en: 'Italian', fr: 'Italien', ar: 'إيطالي')),
              ),
              DropdownMenuItem(
                value: 'asian',
                child: Text(BodyTalkApp.tr(context,
                    en: 'Asian', fr: 'Asiatique', ar: 'آسيوي')),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCuisine = value);
              }
            },
          ),
        ],
      ),
    );
  }

  /// قسم الأزرار: (اختر صورة للوجبة) + (ابدأ تحليل الوجبة)
  Widget _buttonsSection(Color accentOrange) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loading ? null : _pickImage,
            icon: const Icon(Icons.image_rounded),
            label: Text(
              BodyTalkApp.tr(
                context,
                en: 'Pick a meal image',
                fr: 'Choisir une image du repas',
                ar: 'اختر صورة للوجبة',
              ),
              style: GoogleFonts.tajawal(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading || _imageFile == null ? null : () => _analyze(),
            icon: const Icon(Icons.analytics_rounded),
            label: Text(
              _loading
                  ? BodyTalkApp.tr(context,
                      en: 'Analyzing meal...',
                      fr: 'Analyse du repas...',
                      ar: 'جاري تحليل الوجبة...')
                  : BodyTalkApp.tr(context,
                      en: 'Analyze meal',
                      fr: 'Analyser le repas',
                      ar: 'ابدأ تحليل الوجبة'),
              style: GoogleFonts.tajawal(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection(Color primaryBlue, Color accentOrange) {
    if (_loading) {
      return Column(
        children: [
          const SizedBox(height: 8),
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 10),
          Text(
            BodyTalkApp.tr(
              context,
              en: 'Analyzing the meal image...',
              fr: 'Analyse de l’image du repas...',
              ar: 'جاري تحليل صورة الوجبة...',
            ),
            style: GoogleFonts.tajawal(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    if (_result == null) {
      return Container();
    }

    if (_result!["success"] == false) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
          ),
          child: Text(
            _result!["message"] ??
                BodyTalkApp.tr(
                  context,
                  en: 'Meal analysis error.',
                  fr: "Erreur d'analyse du repas.",
                  ar: 'خطأ في تحليل الوجبة.',
                ),
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final mealName = (_result!["meal_name"] ?? "").toString();
    final calories = _num(_result!["calories"]);
    final protein = _num(_result!["protein"]);
    final carbs = _num(_result!["carbs"]);
    final fats = _num(_result!["fats"]);
    final advice = (_result!["advice"] ?? "").toString();

    return Column(
      children: [
        const SizedBox(height: 10),
        _mealSummaryCard(mealName, calories, primaryBlue, accentOrange),
        const SizedBox(height: 14),
        _macrosRow(protein, carbs, fats, primaryBlue, accentOrange),
        const SizedBox(height: 14),
        _foodAdviceCard(advice, primaryBlue),
        const SizedBox(height: 16),
        // 🔹 خطة الوجبات المقترحة بناءً على التحليل
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
                  en: 'Meal plan',
                  fr: 'Plan de repas',
                  ar: 'خطة الوجبات',
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
                  en: 'Calories target: ~${calories.round()} kcal',
                  fr: 'Objectif calories : ~${calories.round()} kcal',
                  ar: 'السعرات المستهدفة: ~${calories.round()} سعرة',
                ),
                style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              FutureBuilder<SharedPreferences>(
                future: SharedPreferences.getInstance(),
                builder: (context, snap) {
                  final auto = snap.hasData
                      ? (snap.data!.getBool('auto_sync_plan') ?? false)
                      : false;
                  final focus = snap.hasData
                      ? (snap.data!.getString('plan_focus') ?? '')
                      : '';
                  double p = protein, c = carbs, f = fats;
                  if (auto && focus.isNotEmpty) {
                    if (focus == 'cardio_deficit') {
                      p *= 1.05;
                      c *= 0.85;
                      f *= 0.90;
                    } else if (focus == 'balanced_strength_cardio') {
                      p *= 1.10;
                      c *= 1.00;
                      f *= 0.95;
                    } else if (focus == 'strength_mobility') {
                      p *= 1.20;
                      c *= 0.95;
                      f *= 0.90;
                    }
                  }
                  return Text(
                    BodyTalkApp.tr(
                      context,
                      en: 'Macros: P ${p.round()}g / C ${c.round()}g / F ${f.round()}g',
                      fr: 'Macros : P ${p.round()}g / G ${c.round()}g / L ${f.round()}g',
                      ar: 'المغذيات: بروتين ${p.round()}ج / كارب ${c.round()}ج / دهون ${f.round()}ج',
                    ),
                    style: GoogleFonts.tajawal(
                        color: Colors.white70, fontSize: 12),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                BodyTalkApp.tr(
                  context,
                  en: 'Suggested meals: High-protein breakfast (eggs, yogurt), balanced lunch (chicken + rice + salad), light dinner (fish + veggies).',
                  fr: 'Repas suggérés : Petit-déjeuner riche en protéines (œufs, yaourt), déjeuner équilibré (poulet + riz + salade), dîner léger (poisson + légumes).',
                  ar: 'وجبات مقترحة: فطور عالي البروتين (بيض، زبادي)، غداء متوازن (دجاج + رز + سلطة)، عشاء خفيف (سمك + خضار).',
                ),
                style: GoogleFonts.tajawal(
                    color: Colors.white70, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final res = await ApiService.saveMealPlan(
                calories: calories,
                protein: protein,
                carbs: carbs,
                fats: fats,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(BodyTalkApp.tr(
                    context,
                    en: res != null
                        ? 'Meal plan saved ✅'
                        : 'Failed to save meal plan',
                    fr: res != null
                        ? 'Plan de repas enregistré ✅'
                        : "Échec de l'enregistrement du plan",
                    ar: res != null
                        ? 'تم حفظ خطة الوجبات ✅'
                        : 'تعذّر حفظ خطة الوجبات',
                  )),
                  backgroundColor:
                      res != null ? Colors.green : Colors.redAccent,
                ),
              );
            },
            icon: const Icon(Icons.restaurant_menu),
            label: Text(BodyTalkApp.tr(context,
                en: 'Save meal plan',
                fr: 'Enregistrer le plan de repas',
                ar: 'حفظ خطة الوجبات')),
          ),
        ),
      ],
    );
  }

  Widget _mealSummaryCard(
      String mealName, double calories, Color primaryBlue, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.7)],
              ),
            ),
            child: const Icon(Icons.restaurant_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  BodyTalkApp.tr(
                    context,
                    en: 'Meal analysis',
                    fr: 'Analyse du repas',
                    ar: 'تحليل الوجبة',
                  ),
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  BodyTalkApp.tr(
                    context,
                    en: 'Approx. calories: ${calories.toStringAsFixed(0)} kcal',
                    fr: 'Calories approx. : ${calories.toStringAsFixed(0)} kcal',
                    ar: 'السعرات التقريبية: ${calories.toStringAsFixed(0)} سعرة',
                  ),
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
    );
  }

  Widget _macrosRow(double protein, double carbs, double fats,
      Color primaryBlue, Color accentOrange) {
    return Row(
      children: [
        Expanded(
          child: _macroCard(
            title: BodyTalkApp.tr(context,
                en: 'Protein', fr: 'Protéines', ar: 'بروتين'),
            value: BodyTalkApp.tr(context,
                en: '${protein.toStringAsFixed(0)} g',
                fr: '${protein.toStringAsFixed(0)} g',
                ar: '${protein.toStringAsFixed(0)} جم'),
            color: primaryBlue,
            icon: Icons.egg_alt_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _macroCard(
            title: BodyTalkApp.tr(context,
                en: 'Carbs', fr: 'Glucides', ar: 'كربوهيدرات'),
            value: BodyTalkApp.tr(context,
                en: '${carbs.toStringAsFixed(0)} g',
                fr: '${carbs.toStringAsFixed(0)} g',
                ar: '${carbs.toStringAsFixed(0)} جم'),
            color: accentOrange,
            icon: Icons.rice_bowl_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _macroCard(
            title:
                BodyTalkApp.tr(context, en: 'Fats', fr: 'Lipides', ar: 'دهون'),
            value: BodyTalkApp.tr(context,
                en: '${fats.toStringAsFixed(0)} g',
                fr: '${fats.toStringAsFixed(0)} g',
                ar: '${fats.toStringAsFixed(0)} جم'),
            color: Colors.pinkAccent,
            icon: Icons.oil_barrel_rounded,
          ),
        ),
      ],
    );
  }

  Widget _macroCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.tajawal(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.tajawal(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _foodAdviceCard(String advice, Color primaryBlue) {
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
            child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  BodyTalkApp.tr(
                    context,
                    en: 'AI nutrition advice',
                    fr: "Conseil nutritionnel de l'IA",
                    ar: 'نصيحة غذائية من الذكاء الاصطناعي',
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
