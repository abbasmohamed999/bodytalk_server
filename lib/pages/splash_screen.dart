import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'onboarding_page.dart';
import 'login_page.dart';
import 'main_navigation.dart';
import 'package:bodytalk_app/main.dart';
import 'package:bodytalk_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 🎬 إعداد الحركة المتحركة
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    _controller.forward();

    // Navigate after 3 seconds - check for session resume
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();

      // Check if language was selected before
      final savedLang = prefs.getString('app_language');
      if (savedLang == null) {
        await _showLanguagePicker();
      }

      if (!mounted) return;

      // Check if onboarding was completed
      final onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;

      // Check if user has valid token (try to resume session)
      if (ApiService.isLoggedIn) {
        // Verify token is still valid
        final me = await ApiService.getAuthMe();
        if (me != null && mounted) {
          // Valid session - go directly to home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
          return;
        }
      }

      if (!mounted) return;

      // No valid session - check if we should show onboarding
      if (!onboardingCompleted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingPage()),
        );
      } else {
        // Onboarding done but not logged in - go to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    });
  }

  Future<void> _showLanguagePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose your language',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
                  title: const Text('English'),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('app_language', 'en');
                    if (!ctx.mounted) return;
                    BodyTalkApp.setLocaleStatic(ctx, 'en');
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Text('🇫🇷', style: TextStyle(fontSize: 22)),
                  title: const Text('Français'),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('app_language', 'fr');
                    if (!ctx.mounted) return;
                    BodyTalkApp.setLocaleStatic(ctx, 'fr');
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Text('🇸🇦', style: TextStyle(fontSize: 22)),
                  title: const Text('العربية'),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('app_language', 'ar');
                    if (!ctx.mounted) return;
                    BodyTalkApp.setLocaleStatic(ctx, 'ar');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2563EB);
    const black = Color(0xFF0B0F19);
    const orange = Color(0xFFFF6B00);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔹 الأيقونة داخل دائرة متدرجة الألوان
              Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [black, blue, orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  size: 70,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: 600.ms),
              const SizedBox(height: 28),

              // 🔹 النصوص
              Text(
                BodyTalkApp.tr(
                  context,
                  en: 'BodyTalk AI',
                  fr: 'BodyTalk AI',
                  ar: 'BodyTalk AI',
                ),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: black,
                ),
              ).animate().fadeIn(duration: 800.ms, delay: 400.ms),
              const SizedBox(height: 8),
              Text(
                BodyTalkApp.tr(
                  context,
                  en: 'AI to analyze your body',
                  fr: 'IA pour analyser votre corps',
                  ar: 'ذكاء اصطناعي لتحليل جسمك',
                ),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ).animate().fadeIn(duration: 1000.ms, delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
