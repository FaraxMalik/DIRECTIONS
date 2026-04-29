import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// One parsed career recommendation from the AI response.
class CareerSuggestion {
  final int rank;
  final String title;
  final String? whyItFits;
  final String? pakistanContext;

  const CareerSuggestion({
    required this.rank,
    required this.title,
    this.whyItFits,
    this.pakistanContext,
  });
}

/// Parses the structured AI response. Falls back gracefully when the model
/// returns Markdown headings, numbered lists, or unstructured prose.
class CareerSuggestionParser {
  static const List<String> _careerLineHeads = [
    'Career 1:',
    'Career 2:',
    'Career 3:',
  ];

  static const List<String> _whyHeads = [
    'Why it fits:',
    'Why it fits',
    'Why:',
  ];

  static const List<String> _pakistanHeads = [
    'Pakistan context:',
    'Pakistan context',
    'Context:',
  ];

  /// Splits the whole AI response into:
  ///   - `intro`: any prose at the top before the first "Career 1:"
  ///   - `suggestions`: parsed career list
  ///   - `outro`: anything after the last career block
  static ({
    String? intro,
    List<CareerSuggestion> suggestions,
    String? outro,
  }) parse(String raw) {
    if (raw.trim().isEmpty) {
      return (intro: null, suggestions: const [], outro: null);
    }

    final lines = raw.split('\n');

    final blockStarts = <int>[];
    for (var i = 0; i < lines.length; i++) {
      final t = lines[i].trim();
      for (final head in _careerLineHeads) {
        if (t.startsWith(head)) {
          blockStarts.add(i);
          break;
        }
      }
    }

    if (blockStarts.isEmpty) {
      return (intro: null, suggestions: const [], outro: raw.trim());
    }

    final intro = blockStarts.first == 0
        ? null
        : lines.sublist(0, blockStarts.first).join('\n').trim();

    final suggestions = <CareerSuggestion>[];
    for (var i = 0; i < blockStarts.length; i++) {
      final start = blockStarts[i];
      final end = (i + 1 < blockStarts.length)
          ? blockStarts[i + 1]
          : lines.length;
      final block = lines.sublist(start, end);
      suggestions.add(_parseBlock(block, i + 1));
    }

    return (
      intro: (intro?.isNotEmpty ?? false) ? intro : null,
      suggestions: suggestions,
      outro: null,
    );
  }

  static CareerSuggestion _parseBlock(List<String> block, int rank) {
    String title = '';
    final whyBuf = StringBuffer();
    final pakBuf = StringBuffer();

    String section = 'title';

    for (var raw in block) {
      var line = raw.trim();
      if (line.isEmpty) continue;

      if (_careerLineHeads.any(line.startsWith)) {
        title = line.replaceFirst(RegExp(r'^Career \d+:\s*'), '').trim();
        title = _stripMarkdown(title);
        section = 'title';
        continue;
      }
      final whyHead = _whyHeads.firstWhere(
        line.startsWith,
        orElse: () => '',
      );
      if (whyHead.isNotEmpty) {
        section = 'why';
        line = line.substring(whyHead.length).trim();
        if (line.isEmpty) continue;
      }
      final pakHead = _pakistanHeads.firstWhere(
        line.startsWith,
        orElse: () => '',
      );
      if (pakHead.isNotEmpty) {
        section = 'pak';
        line = line.substring(pakHead.length).trim();
        if (line.isEmpty) continue;
      }

      if (section == 'why') {
        if (whyBuf.isNotEmpty) whyBuf.write(' ');
        whyBuf.write(_stripMarkdown(line));
      } else if (section == 'pak') {
        if (pakBuf.isNotEmpty) pakBuf.write(' ');
        pakBuf.write(_stripMarkdown(line));
      }
    }

    return CareerSuggestion(
      rank: rank,
      title: title.isNotEmpty ? title : 'Recommended career',
      whyItFits: whyBuf.toString().trim().isEmpty ? null : whyBuf.toString().trim(),
      pakistanContext:
          pakBuf.toString().trim().isEmpty ? null : pakBuf.toString().trim(),
    );
  }

  static String _stripMarkdown(String s) {
    var out = s;
    out = out.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1');
    out = out.replaceAll(RegExp(r'\*(.+?)\*'), r'$1');
    out = out.replaceAll(RegExp(r'^[#>\-\*]+\s*'), '');
    return out.trim();
  }
}

/// Pretty, structured renderer for a Gemini career response.
class CareerSuggestionView extends StatelessWidget {
  final String rawResponse;
  final bool showHero;

  const CareerSuggestionView({
    super.key,
    required this.rawResponse,
    this.showHero = true,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = CareerSuggestionParser.parse(rawResponse);

    if (parsed.suggestions.isEmpty) {
      return _fallbackProseCard(parsed.outro ?? rawResponse);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHero) ...[
          _heroCard(parsed.suggestions),
          const SizedBox(height: 18),
        ],
        if (parsed.intro != null) ...[
          _introCard(parsed.intro!),
          const SizedBox(height: 14),
        ],
        ...List.generate(parsed.suggestions.length, (i) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: i == parsed.suggestions.length - 1 ? 0 : 14),
            child: _CareerCard(suggestion: parsed.suggestions[i]),
          );
        }),
      ],
    );
  }

  Widget _heroCard(List<CareerSuggestion> careers) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(Icons.work_outline_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top ${careers.length} for you',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Recommended careers',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.28), height: 1),
          const SizedBox(height: 14),
          ...careers.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${c.rank}',
                      style: GoogleFonts.playfairDisplay(
                        color: AppColors.crimson,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        c.title,
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _introCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.beigeWarm,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.10)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: AppColors.inkSoft,
          fontSize: 13.5,
          height: 1.55,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _fallbackProseCard(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.10)),
      ),
      child: SelectableText(
        text,
        style: GoogleFonts.inter(
          fontSize: 14.5,
          height: 1.65,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _CareerCard extends StatelessWidget {
  final CareerSuggestion suggestion;
  const _CareerCard({required this.suggestion});

  IconData get _icon {
    final t = suggestion.title.toLowerCase();
    if (t.contains('engineer') || t.contains('software') || t.contains('developer')) {
      return Icons.code_rounded;
    }
    if (t.contains('design') || t.contains('art')) return Icons.palette_rounded;
    if (t.contains('teacher') || t.contains('professor') || t.contains('educator')) {
      return Icons.school_rounded;
    }
    if (t.contains('doctor') || t.contains('medic') || t.contains('nurse')) {
      return Icons.medical_services_rounded;
    }
    if (t.contains('writer') || t.contains('journalist') || t.contains('content')) {
      return Icons.edit_note_rounded;
    }
    if (t.contains('account') || t.contains('finance') || t.contains('cfa') || t.contains('icap')) {
      return Icons.account_balance_rounded;
    }
    if (t.contains('market') || t.contains('digital')) {
      return Icons.campaign_rounded;
    }
    if (t.contains('manager') || t.contains('leader') || t.contains('executive')) {
      return Icons.workspace_premium_rounded;
    }
    if (t.contains('css') || t.contains('officer') || t.contains('government')) {
      return Icons.account_balance_rounded;
    }
    if (t.contains('research') || t.contains('scientist')) {
      return Icons.science_rounded;
    }
    if (t.contains('entrepreneur') || t.contains('startup') || t.contains('business')) {
      return Icons.rocket_launch_rounded;
    }
    if (t.contains('consult')) return Icons.business_center_rounded;
    if (t.contains('freelan')) return Icons.laptop_mac_rounded;
    return Icons.work_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RankBadge(rank: suggestion.rank),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    suggestion.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                alignment: Alignment.center,
                child: Icon(_icon, color: AppColors.crimson, size: 20),
              ),
            ],
          ),
          if (suggestion.whyItFits != null) ...[
            const SizedBox(height: 14),
            _Section(
              icon: Icons.favorite_rounded,
              label: 'Why it fits you',
              body: suggestion.whyItFits!,
            ),
          ],
          if (suggestion.pakistanContext != null) ...[
            const SizedBox(height: 12),
            _Section(
              icon: Icons.location_on_rounded,
              label: 'In Pakistan',
              body: suggestion.pakistanContext!,
              accentBg: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: AppColors.crimsonGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: GoogleFonts.playfairDisplay(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String label;
  final String body;
  final bool accentBg;

  const _Section({
    required this.icon,
    required this.label,
    required this.body,
    this.accentBg = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color:
            accentBg ? AppColors.beigeWarm : AppColors.beige.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: AppColors.crimson.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.crimson, size: 14),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  color: AppColors.crimson,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.inter(
              color: AppColors.ink,
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
