import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bodytalk_app/main.dart';

class ResultPage extends StatelessWidget {
  static const routeName = '/result';

  final Map<String, dynamic> result;

  const ResultPage({super.key, required this.result});

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final muscle = _num(result['muscle_percent']);
    final fat = _num(result['fat_percent']);
    final advice = (result['advice'] ??
            BodyTalkApp.tr(context,
                en: 'Keep going, results are coming!',
                fr: 'Continuez, les résultats arrivent !',
                ar: 'استمر، النتائج قادمة!'))
        .toString();

    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        appBar: AppBar(
            title: Text(BodyTalkApp.tr(context,
                en: 'Analysis result',
                fr: "Résultat de l'analyse",
                ar: 'نتيجة التحليل'))),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            children: [
              _statCard(
                title: BodyTalkApp.tr(context,
                    en: 'Muscle mass',
                    fr: 'Masse musculaire',
                    ar: 'نسبة العضلات'),
                percent: (muscle / 100).clamp(0.0, 1.0),
                valueLabel: '${muscle.toStringAsFixed(1)}%',
                color: const Color(0xFF2563EB),
                icon: Icons.fitness_center,
              ),
              const SizedBox(height: 12),
              _statCard(
                title: BodyTalkApp.tr(context,
                    en: 'Body fat', fr: 'Masse grasse', ar: 'نسبة الدهون'),
                percent: (fat / 100).clamp(0.0, 1.0),
                valueLabel: '${fat.toStringAsFixed(1)}%',
                color: const Color(0xFFFF8A00),
                icon: Icons.monitor_weight_outlined,
              ),
              const SizedBox(height: 16),
              _adviceCard(advice),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.refresh),
                  label: Text(BodyTalkApp.tr(context,
                      en: 'Re-analyze',
                      fr: 'Relancer l’analyse',
                      ar: 'إعادة التحليل')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required double percent, // 0..1
    required String valueLabel,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0x11000000)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 66,
                height: 66,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 8,
                  color: color,
                  backgroundColor: const Color(0xFFE5E7EB),
                ),
              ),
              Icon(icon, color: color, size: 26),
            ],
          )
              .animate()
              .fadeIn(duration: 450.ms)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                Text(valueLabel,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _adviceCard(String advice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFFFF8A00)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              advice,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                  height: 1.5),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.15, end: 0);
  }
}
