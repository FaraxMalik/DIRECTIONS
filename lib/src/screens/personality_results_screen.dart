import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/personality_results.dart';
import '../services/personality_scoring_service.dart';
import '../theme/app_theme.dart';

class PersonalityResultsScreen extends StatelessWidget {
  final PersonalityResults results;

  const PersonalityResultsScreen({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Your results',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(),
            const SizedBox(height: 22),
            _buildTypeCard(),
            const SizedBox(height: 22),
            Text(
              'Big Five (OCEAN)',
              style: GoogleFonts.playfairDisplay(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _bigFiveCard('Openness', results.bigFive.openness),
            const SizedBox(height: 10),
            _bigFiveCard(
                'Conscientiousness', results.bigFive.conscientiousness),
            const SizedBox(height: 10),
            _bigFiveCard('Extraversion', results.bigFive.extraversion),
            const SizedBox(height: 10),
            _bigFiveCard('Agreeableness', results.bigFive.agreeableness),
            const SizedBox(height: 10),
            _bigFiveCard('Neuroticism', results.bigFive.neuroticism),
            const SizedBox(height: 22),
            _disclaimerCard(),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.crimsonGradient,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
            ),
            child: const Icon(Icons.psychology_alt_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis complete',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your personality blueprint is ready.',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard() {
    final description =
        PersonalityScoringService.getTypeDescription(results.mbtiLikeType);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MBTI · Jungian 16-type',
            style: GoogleFonts.inter(
              color: AppColors.inkMuted,
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            results.mbtiLikeType,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.crimson,
              fontSize: 56,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.inter(
              color: AppColors.inkSoft,
              fontSize: 14.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigFiveCard(String trait, double score) {
    final description =
        PersonalityScoringService.getTraitDescription(trait, score);
    final pct = score.toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trait,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  '$pct%',
                  style: GoogleFonts.inter(
                    color: AppColors.crimson,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (score / 100).clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: AppColors.beigeDeep,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.crimson),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.inter(
              color: AppColors.inkSoft,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _disclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.beigeWarm,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border:
            Border.all(color: AppColors.crimson.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.inkSoft, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This test uses open-source Jungian 16-type and IPIP-50 Big Five markers. It is not affiliated with The Myers-Briggs Company.',
              style: GoogleFonts.inter(
                color: AppColors.inkSoft,
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
