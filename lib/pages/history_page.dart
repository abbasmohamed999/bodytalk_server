// lib/pages/history_page.dart

import 'package:flutter/material.dart';
import 'package:bodytalk_app/main.dart';
import '../services/api_service.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

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
              en: 'History',
              fr: 'Historique',
              ar: 'السجل',
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
            child: FutureBuilder<Map<String, List<dynamic>>>(
              future: _fetchHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF8A00),
                    ),
                  );
                }

                final bodyHistory = snapshot.data?['body'] ?? [];
                final foodHistory = snapshot.data?['food'] ?? [];

                if (bodyHistory.isEmpty && foodHistory.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          BodyTalkApp.tr(
                            context,
                            en: 'No history yet',
                            fr: 'Pas d\'historique',
                            ar: 'لا يوجد سجل حتى الآن',
                          ),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (bodyHistory.isNotEmpty) ...[
                        Text(
                          BodyTalkApp.tr(
                            context,
                            en: 'Body analyses',
                            fr: 'Analyses du corps',
                            ar: 'تحليلات الجسم',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...bodyHistory.map((item) => _buildBodyHistoryItem(
                              context,
                              item,
                              blue,
                            )),
                        const SizedBox(height: 24),
                      ],
                      if (foodHistory.isNotEmpty) ...[
                        Text(
                          BodyTalkApp.tr(
                            context,
                            en: 'Food analyses',
                            fr: 'Analyses des repas',
                            ar: 'تحليلات الوجبات',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...foodHistory.map((item) => _buildFoodHistoryItem(
                              context,
                              item,
                              orange,
                            )),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, List<dynamic>>> _fetchHistory() async {
    final body = await ApiService.getBodyHistory() ?? [];
    final food = await ApiService.getFoodHistory() ?? [];
    return {'body': body, 'food': food};
  }

  Widget _buildBodyHistoryItem(
      BuildContext context, Map<String, dynamic> item, Color blue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: blue.withValues(alpha: 0.2),
            ),
            child: Icon(
              Icons.monitor_weight_outlined,
              color: blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['shape'] ?? 'Full'} • BF ${item['body_fat'] ?? '24.4'}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'BMI ${item['bmi'] ?? '27.8'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withValues(alpha: 0.5),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildFoodHistoryItem(
      BuildContext context, Map<String, dynamic> item, Color orange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: orange.withValues(alpha: 0.2),
            ),
            child: Icon(
              Icons.restaurant_rounded,
              color: orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['meal_name'] ?? 'Moderate-calorie meal',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'kcal • P ${item['protein'] ?? '25.0'}g ${item['calories'] ?? '550.0'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withValues(alpha: 0.5),
            size: 24,
          ),
        ],
      ),
    );
  }
}
