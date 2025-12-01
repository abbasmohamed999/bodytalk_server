import 'package:flutter/material.dart';
import 'home_page.dart';
import 'profile_page.dart';
import '../services/api_service.dart';
import '../main.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const _HistoryPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF8A00);

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: const Color(0xFF0B0F19),
        selectedItemColor: orange,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: BodyTalkApp.tr(context,
                en: 'Home', fr: 'Accueil', ar: 'الرئيسية'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_rounded),
            label: BodyTalkApp.tr(context,
                en: 'History', fr: 'Historique', ar: 'السجل'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded),
            label: BodyTalkApp.tr(context,
                en: 'Profile', fr: 'Profil', ar: 'الملف'),
          ),
        ],
      ),
    );
  }
}

// صفحة السجل
class _HistoryPage extends StatelessWidget {
  const _HistoryPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        title: Text(BodyTalkApp.tr(context,
            en: 'History', fr: 'Historique', ar: 'السجل')),
        backgroundColor: const Color(0xFF0B0F19),
      ),
      body: FutureBuilder(
        future: Future.wait([
          ApiService.getBodyHistory(),
          ApiService.getFoodHistory(),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final body = snapshot.data![0] as List?;
          final food = snapshot.data![1] as List?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  BodyTalkApp.tr(context,
                      en: 'Body analyses',
                      fr: 'Analyses du corps',
                      ar: 'تحليلات الجسم'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...(body ?? []).map((e) => Card(
                      color: const Color(0xFF1E293B),
                      child: ListTile(
                        leading: const Icon(Icons.monitor_weight_outlined,
                            color: Colors.white70),
                        title: Text(
                          '${e['shape'] ?? ''} • BF ${e['body_fat'] ?? ''}%',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'BMI ${e['bmi'] ?? ''}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    )),
                const SizedBox(height: 24),
                Text(
                  BodyTalkApp.tr(context,
                      en: 'Food analyses',
                      fr: 'Analyses des repas',
                      ar: 'تحليلات الوجبات'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...(food ?? []).map((e) => Card(
                      color: const Color(0xFF1E293B),
                      child: ListTile(
                        leading: const Icon(Icons.restaurant_rounded,
                            color: Colors.white70),
                        title: Text(
                          '${e['meal_name'] ?? ''}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${e['calories'] ?? ''} kcal • P ${e['protein'] ?? ''}g',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}
