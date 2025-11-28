// lib/pages/onboarding_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'login_page.dart';
import 'package:bodytalk_app/main.dart';

class OnboardingPage extends StatefulWidget {
  static const routeName = '/onboarding';
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  static const Color _bg = Color(0xFF020617);
  static const Color _orange = Color(0xFFFF9800);
  static const Color _blue = Color(0xFF2563EB);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(int i) {
    final active = _index == i;
    return AnimatedContainer(
      duration: 220.ms,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 18 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? _orange : Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildPage({
    required String image,
    required String title,
    required String subtitle,
  }) {
    return Stack(
      children: [
        // الخلفية: الصورة فل سكرين
        Positioned.fill(
          child: Image.asset(
            image,
            fit: BoxFit.cover,
          ),
        ),
        // تدرّج خفيف من الأسفل فقط
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.82),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        // المحتوى
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              children: [
                // شريط أعلى الشاشة
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [_blue, _orange],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        BodyTalkApp.tr(
                          context,
                          en: 'BodyTalk AI',
                          fr: 'BodyTalk AI',
                          ar: 'BodyTalk AI',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        BodyTalkApp.tr(
                          context,
                          en: 'Smart analysis of your body',
                          fr: 'Analyse intelligente de votre corps',
                          ar: 'تحليل ذكي لجسمك',
                        ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // كارت النص والأزرار (زجاجي)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: _bg.withValues(alpha: 0.92),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 20,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 450.ms)
                          .slideY(begin: 0.12, end: 0),
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ).animate().fadeIn(duration: 520.ms, delay: 60.ms),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [_dot(0), _dot(1), _dot(2)],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () {
                            if (_index < 2) {
                              _controller.nextPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOut,
                              );
                            } else {
                              Navigator.pushReplacementNamed(
                                  context, LoginPage.routeName);
                            }
                          },
                          child: Text(_index < 2
                              ? BodyTalkApp.tr(context,
                                  en: 'Next', fr: 'Suivant', ar: 'التالي')
                              : BodyTalkApp.tr(context,
                                  en: 'Start now',
                                  fr: 'Commencer',
                                  ar: 'ابدأ الآن')),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                              context, LoginPage.routeName);
                        },
                        child: Text(
                          BodyTalkApp.tr(
                            context,
                            en: 'Skip',
                            fr: 'Passer',
                            ar: 'تخطي',
                          ),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildPage(
        image: 'assets/images/onb1.png',
        title: BodyTalkApp.tr(
          context,
          en: 'Welcome to BodyTalk AI',
          fr: 'Bienvenue sur BodyTalk AI',
          ar: 'مرحبًا بك في BodyTalk AI',
        ),
        subtitle: BodyTalkApp.tr(
          context,
          en: 'An AI-powered solution to analyze your body from a photo and find strengths and improvements.',
          fr: "Une solution basée sur l’IA pour analyser votre corps à partir d’une photo et trouver des points forts et d’amélioration.",
          ar: 'حل ذكي يعتمد على الذكاء الاصطناعي لتحليل جسمك من الصورة واكتشاف نقاط القوة والتحسين.',
        ),
      ),
      _buildPage(
        image: 'assets/images/onb2.png',
        title: BodyTalkApp.tr(
          context,
          en: 'Smart measurements and estimates',
          fr: 'Mesures et estimations intelligentes',
          ar: 'قياسات وتقديرات ذكية',
        ),
        subtitle: BodyTalkApp.tr(
          context,
          en: 'Approximate analysis of body fat, muscle mass and BMI with personalized tips for your lifestyle.',
          fr: 'Analyse approximative de la masse grasse, musculaire et IMC avec des conseils personnalisés pour votre mode de vie.',
          ar: 'تحليل تقريبي لنسبة الدهون والعضلات و الـ BMI مع نصائح مخصصة تناسب نمط حياتك.',
        ),
      ),
      _buildPage(
        image: 'assets/images/onb3.png',
        title: BodyTalkApp.tr(
          context,
          en: 'Track your progress step by step',
          fr: 'Suivez vos progrès étape par étape',
          ar: 'تابع تقدمك خطوة بخطوة',
        ),
        subtitle: BodyTalkApp.tr(
          context,
          en: 'Save your analyses over time and compare photos to see the impact of training and diet.',
          fr: 'Enregistrez vos analyses au fil du temps et comparez les photos pour voir l’impact de l’entraînement et de l’alimentation.',
          ar: 'احفظ تحليلاتك مع الزمن، وقارن بين صورك لتشاهد تأثير التمرين والنظام الغذائي.',
        ),
      ),
    ];

    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: PageView.builder(
          controller: _controller,
          itemCount: pages.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => pages[i],
        ),
      ),
    );
  }
}
