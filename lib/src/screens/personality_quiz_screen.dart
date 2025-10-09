import 'package:flutter/material.dart';
import '../models/personality_question.dart';
import '../models/personality_results.dart';
import '../services/personality_scoring_service.dart';
import '../services/personality_service.dart';
import 'personality_results_screen.dart';

class PersonalityQuizScreen extends StatefulWidget {
  const PersonalityQuizScreen({super.key});

  @override
  State<PersonalityQuizScreen> createState() => _PersonalityQuizScreenState();
}

class _PersonalityQuizScreenState extends State<PersonalityQuizScreen> {
  // Quiz state
  bool _isLoading = true;
  bool _isBigFivePhase = true; // Start with Big Five test
  int _currentPage = 0;
  
  List<PersonalityQuestion> _bigFiveQuestions = [];
  List<PersonalityQuestion> _jungianQuestions = [];
  
  Map<int, int> _bigFiveResponses = {};
  Map<int, int> _jungianResponses = {};
  
  final PersonalityService _personalityService = PersonalityService();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final bigFive = await PersonalityScoringService.loadIPIP50Questions();
      final jungian = await PersonalityScoringService.loadJungianQuestions();
      
      setState(() {
        _bigFiveQuestions = bigFive;
        _jungianQuestions = jungian;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading questions: $e')),
        );
      }
    }
  }

  List<PersonalityQuestion> get _currentQuestions {
    return _isBigFivePhase ? _bigFiveQuestions : _jungianQuestions;
  }

  Map<int, int> get _currentResponses {
    return _isBigFivePhase ? _bigFiveResponses : _jungianResponses;
  }

  int get _totalPages {
    return (_currentQuestions.length / 2).ceil();
  }

  List<PersonalityQuestion> get _currentPageQuestions {
    final startIdx = _currentPage * 2;
    final endIdx = (startIdx + 2).clamp(0, _currentQuestions.length);
    return _currentQuestions.sublist(startIdx, endIdx);
  }

  bool get _canProceed {
    return _currentPageQuestions.every(
      (q) => _currentResponses.containsKey(q.id)
    );
  }

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
      // End of current test
      if (_isBigFivePhase) {
        // Switch to Jungian test
        setState(() {
          _isBigFivePhase = false;
          _currentPage = 0;
        });
      } else {
        // Both tests complete - calculate and save results
        await _completeQuiz();
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    } else if (!_isBigFivePhase) {
      // Go back to Big Five test
      setState(() {
        _isBigFivePhase = true;
        _currentPage = (_bigFiveQuestions.length / 2).ceil() - 1;
      });
    }
  }

  Future<void> _completeQuiz() async {
    try {
      // Calculate scores
      final bigFiveScores = PersonalityScoringService.calculateBigFiveScores(
        _bigFiveQuestions,
        _bigFiveResponses,
      );
      
      final jungianType = PersonalityScoringService.calculateJungianType(
        _jungianQuestions,
        _jungianResponses,
      );

      final results = PersonalityResults(
        mbtiLikeType: jungianType,
        bigFive: bigFiveScores,
        timestamp: DateTime.now(),
      );

      // Save to Firestore
      await _personalityService.savePersonalityResults(results);

      // Navigate to results screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PersonalityResultsScreen(results: results),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving results: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFFEF0),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final progress = (_currentPage + 1) / _totalPages;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF0),
      appBar: AppBar(
        title: Text(_isBigFivePhase ? 'Big Five Test' : 'Jungian 16-Type Test'),
        backgroundColor: const Color(0xFFB20000),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress section
          Container(
            color: const Color(0xFFB20000),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Page ${_currentPage + 1} of $_totalPages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          // Questions section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _currentPageQuestions.asMap().entries.map((entry) {
                  final question = entry.value;
                  final questionNumber = _currentPage * 2 + entry.key + 1;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: _buildQuestionCard(question, questionNumber),
                  );
                }).toList(),
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentPage > 0 || !_isBigFivePhase)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFB20000)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Previous',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFB20000),
                        ),
                      ),
                    ),
                  ),
                if (_currentPage > 0 || !_isBigFivePhase) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canProceed ? _nextPage : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFB20000),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: Text(
                      _currentPage < _totalPages - 1 
                          ? 'Next' 
                          : (_isBigFivePhase ? 'Continue to Part 2' : 'Finish'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(PersonalityQuestion question, int questionNumber) {
    final currentAnswer = _currentResponses[question.id];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question number and text
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFB20000).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$questionNumber',
                    style: const TextStyle(
                      color: Color(0xFFB20000),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Likert scale options
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Expanded(
                    child: Text(
                      'Strongly\nDisagree',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Disagree',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Neutral',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Agree',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Strongly\nAgree',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  final isSelected = currentAnswer == value;
                  
                  return GestureDetector(
                    onTap: () => _setResponse(question.id, value),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFFB20000) 
                            : Colors.white,
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xFFB20000) 
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '$value',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

