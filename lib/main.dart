// lib/main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
//
import 'package:shared_preferences/shared_preferences.dart';

// استيراد ApiService
import 'services/api_service.dart';

// شاشات التطبيق
import 'pages/splash_screen.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/result_page.dart';

Future<void> main() async {
  // تهيئة Flutter قبل أي شيء (ضروري مع async)
  WidgetsFlutterBinding.ensureInitialized();

  await ApiService.initServer();

  final prefs = await SharedPreferences.getInstance();
  final langCode = prefs.getString('app_language') ?? 'en';

  runApp(BodyTalkApp(localeCode: langCode));
}

class BodyTalkApp extends StatefulWidget {
  const BodyTalkApp({super.key, required this.localeCode});
  final String localeCode;

  static _BodyTalkAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_BodyTalkAppState>();

  static String tr(BuildContext context,
      {required String en, required String fr, required String ar}) {
    final code = of(context)?.localeCode ?? 'en';
    return code == 'ar' ? ar : (code == 'fr' ? fr : en);
  }

  @override
  State<BodyTalkApp> createState() => _BodyTalkAppState();
}

class _BodyTalkAppState extends State<BodyTalkApp> {
  late String _localeCode;
  String get localeCode => _localeCode;

  @override
  void initState() {
    super.initState();
    _localeCode = widget.localeCode;
  }

  Future<void> setLocale(String code) async {
    setState(() => _localeCode = code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', code);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB), // أزرق
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BodyTalk AI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        textTheme: GoogleFonts.tajawalTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B0F19), // أسود داكن
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF2563EB), // أزرق
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      locale: Locale(_localeCode),
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('fr'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection:
            (_localeCode == 'ar' ? TextDirection.rtl : TextDirection.ltr),
        child: child!,
      ),
      // ترتيب التنقل:
      // Splash -> Login -> Home
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        LoginPage.routeName: (_) => const LoginPage(),
        HomePage.routeName: (_) => const HomePage(),
        ResultPage.routeName: (_) => const ResultPage(result: {}),
      },
    );
  }
}
