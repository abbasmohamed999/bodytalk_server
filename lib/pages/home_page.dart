import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import 'profile_page.dart';
import 'body_analysis_page.dart';
import 'food_analysis_page.dart';

import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'package:bodytalk_app/main.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/home';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  File? _image;
  bool _loading = false;
  bool _isPicking = false;

  // 📸 اختيار صورة الجسم
  Future<void> _pickImage() async {
    if (_isPicking || _loading) return;
    _isPicking = true;

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked != null && mounted) {
        setState(() => _image = File(picked.path));
      }
    } catch (e) {
      debugPrint("❌ خطأ في اختيار الصورة: $e");
    } finally {
      _isPicking = false;
    }
  }

  // 🔍 فتح صفحة تحليل الجسم
  Future<void> _analyzeImage() async {
    if (_image == null || _loading) return;

    // تحقق الاشتراك قبل التحليل
    if (ApiService.isLoggedIn) {
      final sub = await ApiService.getSubscriptionStatus();
      if (sub != null && sub['is_active'] != true) {
        // محاولة تفعيل اشتراك اختبار
        final activated = await ApiService.activateTestSubscription();
        if (activated == null || activated['is_active'] != true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(BodyTalkApp.tr(
                context,
                en: 'Subscription inactive. Please subscribe or try test activation.',
                fr: 'Abonnement inactif. Veuillez vous abonner ou essayer l’activation de test.',
                ar: 'الاشتراك غير مفعّل. الرجاء الاشتراك أو جرّب التفعيل التجريبي.',
              )),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }
    }

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BodyAnalysisPage(imageFile: _image!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF020617);
    const orange = Color(0xFFFF8A00);
    const blue = Color(0xFF2563EB);

    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: darkBg,
        body: SafeArea(
          child: Container(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              child: Column(
                children: [
                  _buildHeader(orange, blue),
                  const SizedBox(height: 22),
                  _buildImageCard()
                      .animate()
                      .fadeIn(duration: 450.ms)
                      .slideY(begin: 0.08),
                  const SizedBox(height: 18),
                  _buildHintCard()
                      .animate()
                      .fadeIn(duration: 450.ms, delay: 80.ms)
                      .slideY(begin: 0.08),
                  const SizedBox(height: 18),
                  _buildButtons(orange)
                      .animate()
                      .fadeIn(duration: 450.ms, delay: 120.ms)
                      .slideY(begin: 0.08),
                  const SizedBox(height: 22),
                  _buildUpcomingFoodCard(orange)
                      .animate()
                      .fadeIn(duration: 450.ms, delay: 160.ms)
                      .slideY(begin: 0.08),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showHistory() async {
    final body = await ApiService.getBodyHistory();
    final food = await ApiService.getFoodHistory();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF020617),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: Directionality.of(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BodyTalkApp.tr(
                      context,
                      en: 'History',
                      fr: 'Historique',
                      ar: 'السجل',
                    ),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    BodyTalkApp.tr(context,
                        en: 'Body analyses',
                        fr: 'Analyses du corps',
                        ar: 'تحليلات الجسم'),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  ...(body ?? []).take(10).map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.monitor_weight_outlined,
                                color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${e['shape'] ?? ''} • BF ${e['body_fat'] ?? ''}% • BMI ${e['bmi'] ?? ''}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),
                  Text(
                    BodyTalkApp.tr(context,
                        en: 'Food analyses',
                        fr: 'Analyses des repas',
                        ar: 'تحليلات الوجبات'),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  ...(food ?? []).take(10).map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.restaurant_rounded,
                                color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${e['meal_name'] ?? ''} • ${e['calories'] ?? ''} kcal • P ${e['protein'] ?? ''}g',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color orange, Color blue) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            orange,
            orange.withValues(alpha: 0.85),
            blue,
          ],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                BodyTalkApp.tr(
                  context,
                  en: 'BodyTalk AI',
                  fr: 'BodyTalk AI',
                  ar: 'BodyTalk AI',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                BodyTalkApp.tr(
                  context,
                  en: 'Analyze your body with AI precision',
                  fr: 'Analysez votre corps avec la précision de l’IA',
                  ar: 'حلل جسمك بدقة الذكاء الاصطناعي',
                ),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              InkWell(
                onTap: _showHistory,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: _image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                _image!,
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.photo_size_select_large_outlined,
                  size: 70,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(height: 10),
                Text(
                  BodyTalkApp.tr(
                    context,
                    en: 'No image yet',
                    fr: 'Aucune image pour l’instant',
                    ar: 'لا توجد صورة حتى الآن',
                  ),
                  style: const TextStyle(
                    color: Color(0xFFE5E7EB),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  BodyTalkApp.tr(
                    context,
                    en: 'Pick a full front body image with good lighting for best analysis.',
                    fr: 'Choisissez une image du corps de face avec une bonne luminosité pour une meilleure analyse.',
                    ar: 'اختر صورة أمامية كاملة للجسم بإضاءة جيدة لتحليل أدق.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHintCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
              ),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'نصيحة للحصول على تحليل أدق',
                  style: TextStyle(
                    color: Color(0xFFF9FAFB),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'قف أمام الكاميرا بوضعية مستقيمة، وإضاءة جيدة، ويفضّل أن تكون الخلفية بسيطة بدون تشويش.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(Color orange) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.35),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _loading ? null : _pickImage,
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text(
              'اختر صورة للجسم',
              style: TextStyle(fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              backgroundColor: (_image == null || _loading)
                  ? const Color(0xFF4B5563)
                  : orange,
              foregroundColor: Colors.white,
              elevation: (_image == null || _loading) ? 0 : 4,
              shadowColor: orange.withValues(alpha: 0.5),
            ),
            onPressed: (_image == null || _loading) ? null : _analyzeImage,
            icon: const Icon(Icons.analytics_outlined),
            label: Text(
              _loading ? 'جاري التحضير للتحليل...' : 'ابدأ تحليل الجسم',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  // ⭐ كارد في الأسفل لميزة تحليل الأكل (مع زر تجريبي)
  Widget _buildUpcomingFoodCard(Color orange) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 24,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      orange,
                      orange.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحليل الأكل من الصورة',
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'التعرّف على وجبتك من الصورة، وحساب السعرات والعناصر الغذائية باستخدام الذكاء الاصطناعي.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FoodAnalysisPage(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: orange,
              ),
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
              label: const Text(
                'جرّب تحليل الأكل بالصور',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
