import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/personality_question.dart';
import '../models/personality_results.dart';
import '../services/gemini_service.dart';
import '../services/personality_scoring_service.dart';
import '../services/personality_service.dart';
import '../theme/app_theme.dart';
import 'personality_results_screen.dart';

class PersonalityQuizScreen extends StatefulWidget {
  /// 'bigfive' | 'jungian' | null (both)
  final String? testType;
  const PersonalityQuizScreen({super.key, this.testType});

  @override
  State<PersonalityQuizScreen> createState() => _PersonalityQuizScreenState();
}

class _PersonalityQuizScreenState extends State<PersonalityQuizScreen> {
  bool _isLoading = true;
  bool _isBigFivePhase = true;
  int _currentPage = 0;

  List<PersonalityQuestion> _bigFiveQuestions = [];
  List<PersonalityQuestion> _jungianQuestions = [];

  final Map<int, int> _bigFiveResponses = {};
  final Map<int, int> _jungianResponses = {};

  final PersonalityService _personalityService = PersonalityService();

  bool get _isSingleTest => widget.testType != null;
  bool get _isBigFiveOnly => widget.testType == 'bigfive';
  bool get _isJungianOnly => widget.testType == 'jungian';

  @override
  void initState() {
    super.initState();
    _isBigFivePhase = !_isJungianOnly;
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      if (!_isJungianOnly) {
        _bigFiveQuestions =
            await PersonalityScoringService.loadIPIP50Questions();
      }
      if (!_isBigFiveOnly) {
        _jungianQuestions =
            await PersonalityScoringService.loadJungianQuestions();
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading questions: $e')),
        );
      }
    }
  }

  List<PersonalityQuestion> get _currentQuestions =>
      _isBigFivePhase ? _bigFiveQuestions : _jungianQuestions;

  Map<int, int> get _currentResponses =>
      _isBigFivePhase ? _bigFiveResponses : _jungianResponses;

  int get _totalPages => (_currentQuestions.length / 2).ceil();

  List<PersonalityQuestion> get _currentPageQuestions {
    final startIdx = _currentPage * 2;
    final endIdx = (startIdx + 2).clamp(0, _currentQuestions.length);
    return _currentQuestions.sublist(startIdx, endIdx);
  }

  bool get _canProceed =>
      _currentPageQuestions.every((q) => _currentResponses.containsKey(q.id));

  void _setResponse(int questionId, int value) {
    setState(() {
      if (_isBigFivePhase) {
        _bigFiveResponses[questionId] = value;
      } else {
        _jungianResponses[questionId] = value;
      }
    });
  }

  Future<void> _nextPage() async {
    if (_currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
    } else {
      if (_isBigFivePhase && !_isSingleTest) {
        setState(() {
          _isBigFivePhase = false;
          _currentPage = 0;
        });
      } else {
        await _completeQuiz();
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    } else if (!_isBigFivePhase && !_isSingleTest) {
      setState(() {
        _isBigFivePhase = true;
        _currentPage = (_bigFiveQuestions.length / 2).ceil() - 1;
      });
    }
  }

  Future<void> _completeQuiz() async {
    try {
      PersonalityResults? existingResults;
      if (_isSingleTest) {
        existingResults = await _personalityService.getPersonalityResults();
      }

      final aiResults = await GeminiService().inferPersonalityFromAnswers(
        bigFiveQuestions: _bigFiveQuestions,
        bigFiveResponses: _bigFiveResponses,
        jungianQuestions: _jungianQuestions,
        jungianResponses: _jungianResponses,
      );

      final localBigFive = PersonalityScoringService.calculateBigFiveScores(
        _bigFiveQuestions,
        _bigFiveResponses,
      );
      final localType = PersonalityScoringService.calculateJungianType(
        _jungianQuestions,
        _jungianResponses,
      );

      PersonalityResults finalResults;
      if (_isBigFiveOnly && existingResults != null) {
        finalResults = PersonalityResults(
          mbtiLikeType:
              aiResults?.mbtiLikeType ?? existingResults.mbtiLikeType,
          bigFive: aiResults?.bigFive ?? localBigFive,
          timestamp: DateTime.now(),
        );
      } else if (_isJungianOnly && existingResults != null) {
        finalResults = PersonalityResults(
          mbtiLikeType: aiResults?.mbtiLikeType ?? localType,
          bigFive: aiResults?.bigFive ?? existingResults.bigFive,
          timestamp: DateTime.now(),
        );
      } else {
        finalResults = PersonalityResults(
          mbtiLikeType: aiResults?.mbtiLikeType ?? localType,
          bigFive: aiResults?.bigFive ?? localBigFive,
          timestamp: DateTime.now(),
        );
      }

      await _personalityService.savePersonalityResults(finalResults);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PersonalityResultsScreen(results: finalResults),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving results: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.beige,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.crimson),
        ),
      );
    }

    final progress = (_currentPage + 1) / _totalPages;
    final isMbti = !_isBigFivePhase;
    final title = isMbti ? 'MBTI · Jungian 16-type' : 'OCEAN · Big Five';

    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildProgressHeader(progress),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _currentPageQuestions.asMap().entries.map((entry) {
                  final question = entry.value;
                  final qNum = _currentPage * 2 + entry.key + 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _buildQuestionCard(question, qNum),
                  );
                }).toList(),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page ${_currentPage + 1} of $_totalPages',
                style: GoogleFonts.inter(
                  color: AppColors.inkMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  color: AppColors.crimson,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: AppColors.beige,
          border:
              Border(top: BorderSide(color: AppColors.beigeDeep, width: 1)),
        ),
        child: Row(
          children: [
            if (_currentPage > 0 || !_isBigFivePhase)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousPage,
                  child: const Text('Previous'),
                ),
              ),
            if (_currentPage > 0 || !_isBigFivePhase)
              const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _canProceed ? _nextPage : null,
                child: Text(
                  _currentPage < _totalPages - 1
                      ? 'Next'
                      : (_isBigFivePhase && !_isSingleTest
                          ? 'Continue to MBTI'
                          : 'Finish'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(PersonalityQuestion question, int questionNumber) {
    final currentAnswer = _currentResponses[question.id];

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$questionNumber',
                  style: GoogleFonts.inter(
                    color: AppColors.crimson,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.text,
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _LikertLabel('Strongly\nDisagree'),
              _LikertLabel('Disagree'),
              _LikertLabel('Neutral'),
              _LikertLabel('Agree'),
              _LikertLabel('Strongly\nAgree'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final value = i + 1;
              final isSelected = currentAnswer == value;
              return GestureDetector(
                onTap: () => _setResponse(question.id, value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.crimson
                        : AppColors.beige,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.crimson
                          : AppColors.crimson.withValues(alpha: 0.18),
                      width: 1.6,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.crimson.withValues(alpha: 0.32),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$value',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color:
                          isSelected ? Colors.white : AppColors.inkMuted,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _LikertLabel extends StatelessWidget {
  final String text;
  const _LikertLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 10,
          color: AppColors.inkMuted,
          height: 1.2,
        ),
      ),
    );
  }
}
