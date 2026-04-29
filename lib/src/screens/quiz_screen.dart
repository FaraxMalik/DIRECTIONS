import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/personality_results.dart';
import '../models/quiz_question.dart';
import '../models/quiz_result.dart';
import '../services/gemini_service.dart';
import '../services/journal_service.dart';
import '../services/personality_service.dart';
import '../services/results_service.dart';
import '../theme/app_theme.dart';
import '../widgets/career_suggestion_view.dart';
import 'home_screen.dart';

class QuizResultStore {
  static String latestResult = '';
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _current = 0;
  final Map<int, String> _selected = {};
  final Map<int, String> _custom = {};
  final Map<int, TextEditingController> _controllers = {};
  bool _loading = false;
  String? _result;
  String? _statusMessage;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (_current < quizQuestions.length - 1) {
      setState(() => _current++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_current > 0) setState(() => _current--);
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _statusMessage = 'Gathering your data...';
    });

    final answers = List.generate(quizQuestions.length, (i) {
      return {
        'question': quizQuestions[i].question,
        'answer': _custom[i]?.isNotEmpty == true
            ? _custom[i]
            : _selected[i] ?? '',
      };
    });

    try {
      setState(() => _statusMessage = 'Analyzing your journal entries...');
      final journalService =
          Provider.of<JournalService>(context, listen: false);
      await journalService.loadEntries();
      final journalInsights = journalService.getJournalInsights();

      setState(() => _statusMessage = 'Loading personality results...');
      PersonalityResults? personalityResults;
      try {
        personalityResults =
            await PersonalityService().getPersonalityResults();
      } catch (_) {}

      setState(() => _statusMessage = 'AI is analyzing your profile...');
      final response = await GeminiService().getCareerSuggestionFull(
        answers: answers,
        journalInsights: journalInsights.isNotEmpty ? journalInsights : null,
        personalityResults: personalityResults,
      );

      final result = QuizResult(
        recommendedCareers: _extractCareers(response),
        scores: _buildScoresMap(personalityResults),
        createdAt: DateTime.now(),
        personalityType: personalityResults?.mbtiLikeType,
        description: response,
      );
      if (!mounted) return;
      await Provider.of<ResultsService>(context, listen: false)
          .addResult(result);

      if (!mounted) return;
      setState(() {
        _result = response;
        QuizResultStore.latestResult = response;
        _loading = false;
        _statusMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _result =
            'Error generating career suggestion. Please try again.\n\nDetails: $e';
        _loading = false;
        _statusMessage = null;
      });
    }
  }

  List<String> _extractCareers(String response) {
    final careers = <String>[];
    final lines = response.split('\n');
    for (final line in lines) {
      if (line.startsWith('Career 1:') ||
          line.startsWith('Career 2:') ||
          line.startsWith('Career 3:')) {
        careers.add(line.replaceFirst(RegExp(r'Career \d+:\s*'), '').trim());
      }
    }
    if (careers.isEmpty && lines.isNotEmpty) {
      careers.add(lines.first.trim());
    }
    return careers;
  }

  Map<String, double> _buildScoresMap(PersonalityResults? p) {
    if (p == null) return {'overall': 0.0};
    return {
      'openness': p.bigFive.openness,
      'conscientiousness': p.bigFive.conscientiousness,
      'extraversion': p.bigFive.extraversion,
      'agreeableness': p.bigFive.agreeableness,
      'neuroticism': p.bigFive.neuroticism,
    };
  }

  void _resetQuiz() {
    setState(() {
      _result = null;
      _current = 0;
      _selected.clear();
      _custom.clear();
      for (final c in _controllers.values) {
        c.dispose();
      }
      _controllers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _loadingView();
    if (_result != null) return _resultView();
    return _questionView();
  }

  Widget _loadingView() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: AppColors.crimson,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _statusMessage ?? 'Working...',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.inkSoft,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultView() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CareerSuggestionView(rawResponse: _result!),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetQuiz,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        HomeNavigation.of(context)?.goTo(HomeTab.results),
                    icon:
                        const Icon(Icons.emoji_events_rounded, size: 18),
                    label: const Text('Results'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionView() {
    final q = quizQuestions[_current];
    final controller = _controllers.putIfAbsent(
      _current,
      () => TextEditingController(text: _custom[_current] ?? ''),
    );

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.question,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ...List.generate(q.options.length, (i) {
                    final opt = q.options[i];
                    final selected = _selected[_current] == opt;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _optionTile(
                        opt,
                        selected: selected,
                        onTap: () {
                          setState(() {
                            _selected[_current] = opt;
                            _custom[_current] = '';
                            controller.text = '';
                          });
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  Text(
                    'Or write your own answer',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.inkMuted,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Type here...',
                      prefixIcon: Icon(Icons.edit_outlined,
                          color: AppColors.crimson),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _custom[_current] = val;
                        if (val.isNotEmpty) _selected[_current] = '';
                      });
                    },
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      if (_current > 0)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _back,
                            icon: const Icon(Icons.arrow_back_rounded,
                                size: 18),
                            label: const Text('Back'),
                          ),
                        ),
                      if (_current > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _canProceed() ? _next : null,
                          child: Text(_current < quizQuestions.length - 1
                              ? 'Next'
                              : 'Submit'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    return (_selected[_current]?.isNotEmpty ?? false) ||
        (_custom[_current]?.isNotEmpty ?? false);
  }

  Widget _buildHeader() {
    final progress = (_current + 1) / quizQuestions.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Career quiz',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                'Question ${_current + 1} of ${quizQuestions.length}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 350),
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
        ],
      ),
    );
  }

  Widget _optionTile(String label,
      {required bool selected, required VoidCallback onTap}) {
    return Material(
      color: selected
          ? AppColors.crimson.withValues(alpha: 0.08)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: selected
                  ? AppColors.crimson
                  : AppColors.crimson.withValues(alpha: 0.15),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.crimson : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.crimson : AppColors.inkMuted,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.ink,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
