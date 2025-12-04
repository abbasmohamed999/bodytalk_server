// lib/pages/plans_progress_page.dart

import 'package:flutter/material.dart';
import 'package:bodytalk_app/main.dart';

class PlansProgressPage extends StatelessWidget {
  const PlansProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF020617);
    const orange = Color(0xFFFF8A00);
    const blue = Color(0xFF2563EB);

    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: darkBg,
        appBar: AppBar(
          backgroundColor: darkBg,
          title: Text(
            BodyTalkApp.tr(
              context,
              en: 'Plans & Progress',
              fr: 'Plans et progression',
              ar: 'الخطط والتقدم',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        colors: [
                          blue,
                          blue.withValues(alpha: 0.85),
                          orange,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          child: const Icon(
                            Icons.analytics_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            BodyTalkApp.tr(
                              context,
                              en: 'Your Progress Overview',
                              fr: 'Aperçu de votre progression',
                              ar: 'نظرة عامة على تقدمك',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Progress Rings
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ProgressRing(
                        value: 0.6,
                        labelEn: 'Calories',
                        labelFr: 'Calories',
                        labelAr: 'السعرات',
                        valueLabel: '60%',
                        color: Color(0xFFFF8A00),
                      ),
                      _ProgressRing(
                        value: 0.4,
                        labelEn: 'Workout',
                        labelFr: 'Entraînement',
                        labelAr: 'التمارين',
                        valueLabel: '40%',
                        color: Color(0xFF2563EB),
                      ),
                      _ProgressRing(
                        value: 0.8,
                        labelEn: 'Protein',
                        labelFr: 'Protéines',
                        labelAr: 'البروتين',
                        valueLabel: '80%',
                        color: Color(0xFF22C55E),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Active Workout Plan
                  _PlanCard(
                    titleEn: 'Active workout plan',
                    titleFr: 'Plan d\'entraînement actif',
                    titleAr: 'خطة التمرين الحالية',
                    descriptionEn:
                        '4-week strength & cardio program based on your last body analysis.',
                    descriptionFr:
                        'Programme de 4 semaines de musculation et cardio basé sur votre dernière analyse corporelle.',
                    descriptionAr:
                        'برنامج قوة وكارديو لمدة ٤ أسابيع مبني على آخر تحليل لجسمك.',
                    icon: Icons.fitness_center_rounded,
                    color: blue,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(BodyTalkApp.tr(
                            context,
                            en: 'Workout plan details coming soon!',
                            fr: 'Détails du plan d\'entraînement bientôt disponibles!',
                            ar: 'تفاصيل خطة التمرين قريبًا!',
                          )),
                          backgroundColor: Colors.black87,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Active Meal Plan
                  _PlanCard(
                    titleEn: 'Active meal plan',
                    titleFr: 'Plan alimentaire actif',
                    titleAr: 'الخطة الغذائية الحالية',
                    descriptionEn:
                        'Balanced meal plan adjusted to your calorie and protein targets.',
                    descriptionFr:
                        'Plan alimentaire équilibré ajusté à vos objectifs de calories et de protéines.',
                    descriptionAr:
                        'خطة غذائية متوازنة حسب هدف السعرات والبروتين الخاص بك.',
                    icon: Icons.restaurant_menu_rounded,
                    color: orange,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(BodyTalkApp.tr(
                            context,
                            en: 'Meal plan details coming soon!',
                            fr: 'Détails du plan de repas bientôt disponibles!',
                            ar: 'تفاصيل خطة الوجبات قريبًا!',
                          )),
                          backgroundColor: Colors.black87,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Past Plans Section
                  Text(
                    BodyTalkApp.tr(
                      context,
                      en: 'Past plans',
                      fr: 'Plans terminés',
                      ar: 'الخطط السابقة',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: Text(
                      BodyTalkApp.tr(
                        context,
                        en: 'You don\'t have any finished plans yet.',
                        fr: 'Vous n\'avez pas encore de plans terminés.',
                        ar: 'لا توجد أي خطط منتهية حتى الآن.',
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double value;
  final String labelEn;
  final String labelFr;
  final String labelAr;
  final String valueLabel;
  final Color color;

  const _ProgressRing({
    required this.value,
    required this.labelEn,
    required this.labelFr,
    required this.labelAr,
    required this.valueLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final localizedLabel = BodyTalkApp.tr(
      context,
      en: labelEn,
      fr: labelFr,
      ar: labelAr,
    );

    return Column(
      children: [
        SizedBox(
          height: 80,
          width: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value.clamp(0, 1),
                strokeWidth: 7,
                color: color,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
              Center(
                child: Text(
                  valueLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          localizedLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String titleEn;
  final String titleFr;
  final String titleAr;
  final String descriptionEn;
  final String descriptionFr;
  final String descriptionAr;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PlanCard({
    required this.titleEn,
    required this.titleFr,
    required this.titleAr,
    required this.descriptionEn,
    required this.descriptionFr,
    required this.descriptionAr,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = BodyTalkApp.tr(
      context,
      en: titleEn,
      fr: titleFr,
      ar: titleAr,
    );

    final description = BodyTalkApp.tr(
      context,
      en: descriptionEn,
      fr: descriptionFr,
      ar: descriptionAr,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
