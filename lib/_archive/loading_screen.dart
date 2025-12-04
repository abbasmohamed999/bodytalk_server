import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bodytalk_app/main.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2563EB);
    const orange = Color(0xFFFF8A00);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.35),
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // دائرة أيقونة
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.40),
                          width: 3),
                      gradient: LinearGradient(
                        colors: [
                          blue.withValues(alpha: 0.85),
                          orange.withValues(alpha: 0.85)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.analytics_outlined,
                          color: Colors.white, size: 40),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .scaleXY(begin: 0.95, end: 1.05, duration: 900.ms)
                      .then()
                      .scaleXY(begin: 1.05, end: 0.95, duration: 900.ms),

                  const SizedBox(height: 18),
                  Text(
                    BodyTalkApp.tr(
                      context,
                      en: 'Analyzing image...',
                      fr: 'Analyse de l’image...',
                      ar: 'جارٍ تحليل الصورة...',
                    ),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      minHeight: 8,
                      color: orange,
                      backgroundColor: Color(0x22FFFFFF),
                    ),
                  ).animate().shimmer(duration: 1200.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
