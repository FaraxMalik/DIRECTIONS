import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/quiz_result.dart';
import '../services/results_service.dart';
import '../theme/app_theme.dart';
import '../widgets/career_suggestion_view.dart';
import 'home_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResultsService>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<ResultsService>(
        builder: (context, service, _) {
          final results = service.results;
          return RefreshIndicator(
            color: AppColors.crimson,
            onRefresh: service.load,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(child: _header()),
                ),
                if (results.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _emptyState(context),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                    sliver: SliverList.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 14),
                      itemBuilder: (_, i) =>
                          _resultCard(context, results[i]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your results',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.ink,
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'A history of every AI-driven career analysis built around you.',
          style: GoogleFonts.inter(
            color: AppColors.inkSoft,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.crimson.withValues(alpha: 0.08),
              ),
              child: const Icon(Icons.emoji_events_rounded,
                  color: AppColors.crimson, size: 48),
            ),
            const SizedBox(height: 22),
            Text(
              'No results yet.',
              style: GoogleFonts.playfairDisplay(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take the career quiz once to see AI-curated career recommendations here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.inkSoft,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () =>
                  HomeNavigation.of(context)?.goTo(HomeTab.quiz),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start the quiz'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(BuildContext context, QuizResult r) {
    final dateText = '${r.createdAt.day.toString().padLeft(2, '0')}'
        '/${r.createdAt.month.toString().padLeft(2, '0')}'
        '/${r.createdAt.year}';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () => _openDetail(context, r),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border:
                Border.all(color: AppColors.crimson.withValues(alpha: 0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.crimson.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      r.personalityType ?? 'Career',
                      style: GoogleFonts.inter(
                        color: AppColors.crimson,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateText,
                    style: GoogleFonts.inter(
                      color: AppColors.inkMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (r.recommendedCareers.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Top recommendations',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.inkMuted,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...r.recommendedCareers.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.crimsonGradient,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${entry.key + 1}',
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              entry.value,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 15,
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'View full breakdown',
                    style: GoogleFonts.inter(
                      color: AppColors.crimson,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 14, color: AppColors.crimson),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, QuizResult r) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _ResultDetailScreen(result: r)),
    );
  }
}

class _ResultDetailScreen extends StatelessWidget {
  final QuizResult result;
  const _ResultDetailScreen({required this.result});

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${_monthName(result.createdAt.month)} ${result.createdAt.day}, '
        '${result.createdAt.year}';

    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Career analysis',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_rounded,
                    size: 14, color: AppColors.inkMuted),
                const SizedBox(width: 6),
                Text(
                  dateText,
                  style: GoogleFonts.inter(
                    color: AppColors.inkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                if (result.personalityType != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.crimson.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      result.personalityType!,
                      style: GoogleFonts.inter(
                        color: AppColors.crimson,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            CareerSuggestionView(rawResponse: result.description ?? ''),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return names[(m - 1).clamp(0, 11)];
  }
}
