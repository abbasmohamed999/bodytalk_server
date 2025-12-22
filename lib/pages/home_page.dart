import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'profile_page.dart';
import 'body_analysis_capture_page.dart';
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
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await ApiService.getProfile();
    if (mounted && profile != null) {
      setState(() => _userProfile = profile);
    }
  }

  void _openBodyAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BodyAnalysisCapturePage(),
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
                  _buildBodyAnalysisCard(orange, blue)
                      .animate()
                      .fadeIn(duration: 450.ms)
                      .slideY(begin: 0.08),
                  const SizedBox(height: 18),
                  _buildTipCard()
                      .animate()
                      .fadeIn(duration: 450.ms, delay: 80.ms)
                      .slideY(begin: 0.08),
                  const SizedBox(height: 22),
                  _buildFoodAnalysisCard(orange)
                      .animate()
                      .fadeIn(duration: 450.ms, delay: 120.ms)
                      .slideY(begin: 0.08),
                ],
              ),
            ),
          ),
        ),
      ),
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
          // User Avatar instead of Settings
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 2,
                ),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                ),
              ),
              child: Center(
                child: Text(
                  _userProfile?['name']
                          ?.toString()
                          .substring(0, 1)
                          .toUpperCase() ??
                      'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyAnalysisCard(Color orange, Color blue) {
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
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [blue, blue.withValues(alpha: 0.7)],
                  ),
                ),
                child: const Icon(Icons.accessibility_new_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      BodyTalkApp.tr(context,
                          en: 'Body Analysis',
                          fr: 'Analyse du Corps',
                          ar: 'تحليل الجسم'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      BodyTalkApp.tr(context,
                          en: 'Requires front + side photos',
                          fr: 'Nécessite photos face + profil',
                          ar: 'يتطلب صورة أمامية + جانبية'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openBodyAnalysis,
              icon: const Icon(Icons.analytics_rounded),
              label: Text(
                BodyTalkApp.tr(context,
                    en: 'Start Body Analysis',
                    fr: 'Démarrer l\'Analyse',
                    ar: 'بدء تحليل الجسم'),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard() {
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
                Text(
                  BodyTalkApp.tr(context,
                      en: 'Tip for better analysis',
                      fr: 'Conseil pour une meilleure analyse',
                      ar: 'نصيحة للحصول على تحليل أدق'),
                  style: const TextStyle(
                    color: Color(0xFFF9FAFB),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  BodyTalkApp.tr(context,
                      en: 'Stand straight with good lighting and a simple background for best results.',
                      fr: 'Tenez-vous droit avec un bon éclairage et un fond simple pour de meilleurs résultats.',
                      ar: 'قف بوضعية مستقيمة مع إضاءة جيدة وخلفية بسيطة للحصول على أفضل النتائج.'),
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

  Widget _buildFoodAnalysisCard(Color orange) {
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
                      BodyTalkApp.tr(context,
                          en: 'Food Analysis',
                          fr: 'Analyse Alimentaire',
                          ar: 'تحليل الأكل من الصورة'),
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      BodyTalkApp.tr(context,
                          en: 'Identify your meal from photo, calculate calories and macros using AI.',
                          fr: 'Identifiez votre repas, calculez calories et macros avec l\'IA.',
                          ar: 'التعرّف على وجبتك من الصورة، وحساب السعرات والعناصر الغذائية باستخدام الذكاء الاصطناعي.'),
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
              label: Text(
                BodyTalkApp.tr(context,
                    en: 'Try Food Analysis',
                    fr: 'Essayer l\'Analyse',
                    ar: 'جرّب تحليل الأكل بالصور'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
