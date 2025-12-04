import 'package:flutter/material.dart';
import 'home_page.dart';
import 'history_page.dart';
import 'plans_progress_page.dart';
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
    const HistoryPage(),
    const PlansProgressPage(),
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
            icon: const Icon(Icons.analytics_outlined),
            label:
                BodyTalkApp.tr(context, en: 'Plans', fr: 'Plans', ar: 'الخطط'),
          ),
        ],
      ),
    );
  }
}
