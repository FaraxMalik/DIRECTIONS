import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/personality_results.dart';
import '../services/personality_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'manual_personality_entry_screen.dart';
import 'personality_quiz_screen.dart';
import 'personality_results_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PersonalityService _personalityService = PersonalityService();
  PersonalityResults? _personality;
  bool _loadingPersonality = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileService>(context, listen: false).load();
    });
    _loadPersonality();
  }

  Future<void> _loadPersonality() async {
    try {
      final p = await _personalityService.getPersonalityResults();
      if (mounted) {
        setState(() {
          _personality = p;
          _loadingPersonality = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPersonality = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final profile = context.watch<ProfileService>().profile;
    final name = profile?.displayName ?? user?.displayName ?? 'Friend';

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.crimson,
        onRefresh: () async {
          await Future.wait([
            _loadPersonality(),
            Provider.of<ProfileService>(context, listen: false).load(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(name),
              const SizedBox(height: 24),
              _buildHeroCard(),
              const SizedBox(height: 28),
              _sectionTitle('Discover yourself'),
              const SizedBox(height: 12),
              _buildPersonalityCards(),
              const SizedBox(height: 28),
              _sectionTitle('Take the next step'),
              const SizedBox(height: 12),
              _buildCareerCard(context),
              const SizedBox(height: 14),
              _buildCounselorCard(context),
              const SizedBox(height: 28),
              _quoteCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: GoogleFonts.inter(
                  color: AppColors.inkMuted,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.crimsonGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.crimson.withValues(alpha: 0.30),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        gradient: AppColors.crimsonGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -10,
            child: Icon(
              Icons.explore_rounded,
              color: Colors.white.withValues(alpha: 0.10),
              size: 130,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  _personality != null ? 'Your blueprint' : 'Get started',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _personality != null
                    ? 'You are an ${_personality!.mbtiLikeType}.'
                    : 'Find the career\nthat fits you.',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _personality != null
                    ? 'Tap to view your full personality profile and tailored career insights.'
                    : 'Take two short personality tests to unlock AI-driven career guidance built around you.',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _heroButton(
                    label: _personality != null
                        ? 'View results'
                        : 'Start MBTI test',
                    icon: _personality != null
                        ? Icons.arrow_forward_rounded
                        : Icons.play_arrow_rounded,
                    onTap: () {
                      if (_personality != null) {
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                          builder: (_) => PersonalityResultsScreen(
                              results: _personality!),
                        ))
                            .then((_) => _loadPersonality());
                      } else {
                        _openPersonalityTest('jungian');
                      }
                    },
                  ),
                  if (_personality == null)
                    _heroButton(
                      label: 'Enter manually',
                      icon: Icons.edit_outlined,
                      filled: false,
                      onTap: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                          builder: (_) =>
                              const ManualPersonalityEntryScreen(),
                        ))
                            .then((_) => _loadPersonality());
                      },
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool filled = true,
  }) {
    return Material(
      color: filled ? Colors.white : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        side: filled
            ? BorderSide.none
            : BorderSide(color: Colors.white.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18,
                  color: filled ? AppColors.crimson : Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: filled ? AppColors.crimson : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.playfairDisplay(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPersonalityCards() {
    return Row(
      children: [
        Expanded(
          child: _testCard(
            title: 'MBTI',
            subtitle: '16 personalities',
            description: '70 questions • ~8 min',
            icon: Icons.psychology_alt_rounded,
            done: _personality != null,
            onTap: () => _openPersonalityTest('jungian'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _testCard(
            title: 'OCEAN',
            subtitle: 'Big Five traits',
            description: '50 questions • ~7 min',
            icon: Icons.bubble_chart_rounded,
            done: _personality != null,
            onTap: () => _openPersonalityTest('bigfive'),
          ),
        ),
      ],
    );
  }

  Widget _testCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required bool done,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.crimson.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.crimson.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Icon(icon, color: AppColors.crimson, size: 22),
                  ),
                  if (done)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Done',
                            style: GoogleFonts.inter(
                              color: AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: AppColors.crimson,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.inter(
                  color: AppColors.inkSoft,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCareerCard(BuildContext context) {
    return _actionCard(
      icon: Icons.work_outline_rounded,
      title: 'Career quiz',
      subtitle:
          'Answer 10 lifestyle questions and let AI cross-reference everything we know about you.',
      cta: 'Start quiz',
      onTap: () => HomeNavigation.of(context)?.goTo(HomeTab.quiz),
    );
  }

  Widget _buildCounselorCard(BuildContext context) {
    return _actionCard(
      icon: Icons.auto_awesome_rounded,
      title: 'Talk to Faraz',
      subtitle:
          'Your personal AI counselor — discuss doubts, study abroad, freelancing, CSS, and more.',
      cta: 'Open chat',
      onTap: () => HomeNavigation.of(context)?.goTo(HomeTab.counselor),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String cta,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.crimson.withValues(alpha: 0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  gradient: AppColors.crimsonGradient,
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.playfairDisplay(
                        color: AppColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: AppColors.inkSoft,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          cta,
                          style: GoogleFonts.inter(
                            color: AppColors.crimson,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 16, color: AppColors.crimson),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quoteCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.beigeWarm,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded,
              color: AppColors.crimson.withValues(alpha: 0.6), size: 28),
          const SizedBox(height: 8),
          Text(
            'Your work is going to fill a large part of your life — '
            'the only way to be truly satisfied is to do what you believe is great work.',
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: AppColors.ink,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '— Steve Jobs',
            style: GoogleFonts.inter(
              color: AppColors.inkMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  void _openPersonalityTest(String type) {
    if (_loadingPersonality) return;
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => PersonalityQuizScreen(testType: type),
    ))
        .then((_) => _loadPersonality());
  }
}
