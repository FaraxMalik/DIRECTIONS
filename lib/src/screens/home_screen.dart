import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'career_counselor_screen.dart';
import 'dashboard_screen.dart';
import 'journaling_screen.dart';
import 'profile_screen.dart';
import 'quiz_screen.dart';
import 'results_screen.dart';

/// Tabs in the bottom nav.
enum HomeTab { home, quiz, counselor, journal, results, profile }

/// Provides a way for any descendant to switch the currently selected
/// home tab. Exposes [HomeNavigation.of].
class HomeNavigation extends InheritedWidget {
  final void Function(HomeTab tab) goTo;

  const HomeNavigation({
    super.key,
    required this.goTo,
    required super.child,
  });

  static HomeNavigation? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HomeNavigation>();
  }

  @override
  bool updateShouldNotify(HomeNavigation oldWidget) => false;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  HomeTab _selected = HomeTab.home;
  late final AnimationController _pulse;

  static const _items = <_NavItemData>[
    _NavItemData(HomeTab.home, Icons.home_rounded, 'Home'),
    _NavItemData(HomeTab.quiz, Icons.quiz_rounded, 'Quiz'),
    _NavItemData(HomeTab.counselor, Icons.auto_awesome_rounded, 'Counselor'),
    _NavItemData(HomeTab.journal, Icons.menu_book_rounded, 'Journal'),
    _NavItemData(HomeTab.results, Icons.emoji_events_rounded, 'Results'),
    _NavItemData(HomeTab.profile, Icons.person_rounded, 'Profile'),
  ];

  Widget _screenFor(HomeTab tab) {
    switch (tab) {
      case HomeTab.home:
        return const DashboardScreen();
      case HomeTab.quiz:
        return const QuizScreen();
      case HomeTab.counselor:
        return const CareerCounselorScreen();
      case HomeTab.journal:
        return const JournalingScreen();
      case HomeTab.results:
        return const ResultsScreen();
      case HomeTab.profile:
        return const ProfileScreen();
    }
  }

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _go(HomeTab tab) {
    if (_selected == tab) return;
    setState(() => _selected = tab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.beige,
      body: HomeNavigation(
        goTo: _go,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(
            key: ValueKey(_selected),
            child: _screenFor(_selected),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border:
                Border.all(color: AppColors.crimson.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: AppColors.crimson.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _items.map((it) {
              if (it.tab == HomeTab.counselor) {
                return _buildCounselorBtn(it);
              }
              return _buildItem(it);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(_NavItemData data) {
    final selected = _selected == data.tab;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () => _go(data.tab),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 12 : 0,
                vertical: selected ? 6 : 0,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.crimson.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Icon(
                data.icon,
                color: selected ? AppColors.crimson : AppColors.inkMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: selected ? AppColors.crimson : AppColors.inkMuted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounselorBtn(_NavItemData data) {
    final selected = _selected == data.tab;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () => _go(data.tab),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final glow = selected ? 0.55 : 0.30 + 0.25 * _pulse.value;
                return Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.crimsonGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.crimson.withValues(alpha: glow),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                    border: selected
                        ? Border.all(color: AppColors.cream, width: 2)
                        : null,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 22),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Faraz',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: selected ? AppColors.crimson : AppColors.inkMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final HomeTab tab;
  final IconData icon;
  final String label;
  const _NavItemData(this.tab, this.icon, this.label);
}
