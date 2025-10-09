
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../models/quiz_question.dart';
import '../models/quiz_result.dart';
import '../services/gemini_service.dart';
import '../services/results_service.dart';
import '../services/journal_service.dart';

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

  void _next() {
    if (_current < quizQuestions.length - 1) {
      setState(() {
        _current++;
      });
    } else {
      _submit();
    }
  }

  void _submit() async {
    setState(() { _loading = true; });
    final answers = List.generate(quizQuestions.length, (i) => {
      'question': quizQuestions[i].question,
      'answer': _custom[i]?.isNotEmpty == true ? _custom[i] : _selected[i] ?? '',
    });
    
    try {
      // Load journal insights for better career recommendations
      final journalService = Provider.of<JournalService>(context, listen: false);
      await journalService.loadEntries();
      final journalInsights = journalService.getJournalInsights();
      
      final gemini = GeminiService();
      // Use journal data if available, otherwise just quiz answers
      final response = journalInsights.isNotEmpty
          ? await gemini.getCareerSuggestionWithJournal(answers, journalInsights)
          : await gemini.getCareerSuggestion(answers);
      
      // Parse the response to create a QuizResult
      final lines = response.split('\n');
      String careerTitle = 'Career Suggestion';
      String description = response;
      
      // Try to extract title and description
      for (var line in lines) {
        if (line.toLowerCase().contains('title:')) {
          careerTitle = line.replaceAll(RegExp(r'title:', caseSensitive: false), '').trim();
        }
      }
      
      // Create QuizResult object
      final quizResult = QuizResult(
        recommendedCareers: [careerTitle],
        scores: {'general': 5.0},
        createdAt: DateTime.now(),
        description: response,
      );
      
      // Save the result using ResultsService
      final resultsService = Provider.of<ResultsService>(context, listen: false);
      await resultsService.addResult(quizResult);
      
      setState(() {
        _result = response;
        QuizResultStore.latestResult = response;
        _loading = false;
      });
    } catch (e) {
      print('Quiz submission error: $e');
      setState(() {
        _result = 'Error generating career suggestion. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Career Quiz'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFEF0), Color(0xFFF5E6D3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFB20000).withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: CircularProgressIndicator(
                  color: Color(0xFFB20000),
                  strokeWidth: 4,
                ),
              ),
              SizedBox(height: 40),
              Text(
                '✨ Analyzing your answers...',
                style: TextStyle(
                  color: Color(0xFFB20000), 
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Please wait while we process your responses',
                style: TextStyle(
                  color: Colors.grey[600], 
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_result != null) {
      final lines = _result!.split('\n');
      String title = lines.isNotEmpty ? lines[0] : 'Recommended Career';
      String description = lines.length > 1 ? lines.sublist(1).join(' ') : '';
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFEF0), Color(0xFFF5E6D3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Success animation area
                Container(
                  padding: EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFB20000).withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.celebration_rounded,
                    size: 80,
                    color: Color(0xFFB20000),
                  ),
                ),
                SizedBox(height: 32),
                
                // Title
                Text(
                  'Your Career Path',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB20000),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B0000),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                
                // Results card
                Container(
                  padding: EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.insights, color: Color(0xFFB20000), size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Your Analysis',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB20000),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFFEF0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),
                
                // Action button
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.home_rounded, size: 24),
                  label: Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB20000),
                    foregroundColor: Color(0xFFFFFEF0),
                    padding: EdgeInsets.symmetric(vertical: 20),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final q = quizQuestions[_current];
    if (_controllers[_current] == null) {
      _controllers[_current] = TextEditingController(text: _custom[_current] ?? '');
    }
    final textController = _controllers[_current]!;
    textController.value = textController.value.copyWith(text: _custom[_current] ?? '', selection: TextSelection.collapsed(offset: (_custom[_current] ?? '').length));
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFFEF0), Color(0xFFF5E6D3)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header with progress
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: Color(0xFFB20000)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          child: Text(
                            'Question ${_current + 1} of ${quizQuestions.length}',
                            key: ValueKey(_current),
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFFB20000),
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      SizedBox(width: 48),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (_current + 1) / quizQuestions.length,
                      backgroundColor: Color(0xFFB20000).withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB20000)),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            
            // Question content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Question text
                    Text(
                      q.question,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B0000),
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 32),
                    
                    // Options
                    ...List.generate(q.options.length, (i) => GestureDetector(
                      onTap: () {
                        setState(() {
                          _selected[_current] = q.options[i];
                          _custom[_current] = '';
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _selected[_current] == q.options[i]
                              ? Color(0xFFB20000)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selected[_current] == q.options[i]
                                ? Color(0xFFB20000)
                                : Color(0xFFB20000).withOpacity(0.2),
                            width: 2,
                          ),
                          boxShadow: _selected[_current] == q.options[i]
                              ? [
                                  BoxShadow(
                                    color: Color(0xFFB20000).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selected[_current] == q.options[i]
                                      ? Colors.white
                                      : Color(0xFFB20000),
                                  width: 2,
                                ),
                                color: _selected[_current] == q.options[i]
                                    ? Colors.white
                                    : Colors.transparent,
                              ),
                              child: _selected[_current] == q.options[i]
                                  ? Icon(Icons.check, size: 16, color: Color(0xFFB20000))
                                  : null,
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                q.options[i],
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: _selected[_current] == q.options[i]
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: _selected[_current] == q.options[i]
                                      ? Colors.white
                                      : Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                    
                    SizedBox(height: 24),
                    
                    // Custom answer field
                    TextField(
                      controller: textController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: '✍️ Or write your own answer',
                        labelStyle: TextStyle(color: Color(0xFFB20000).withOpacity(0.7)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Color(0xFFB20000).withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Color(0xFFB20000).withOpacity(0.3), width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Color(0xFFB20000), width: 2),
                        ),
                      ),
                      style: TextStyle(fontSize: 16),
                      onChanged: (val) {
                        setState(() {
                          _custom[_current] = val;
                          if (val.isNotEmpty) _selected[_current] = '';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom button
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFB20000),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Color(0xFFB20000).withOpacity(0.3),
                  disabledForegroundColor: Colors.white.withOpacity(0.5),
                  padding: EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: (_selected[_current]?.isNotEmpty == true || _custom[_current]?.isNotEmpty == true)
                    ? () {
                        if (_custom[_current]?.isNotEmpty == true) {
                          _custom[_current] = textController.text;
                          textController.clear();
                        }
                        _next();
                      }
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _current < quizQuestions.length - 1 ? 'Next Question' : 'Submit Quiz',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 12),
                    Icon(
                      _current < quizQuestions.length - 1
                          ? Icons.arrow_forward_rounded
                          : Icons.check_circle_outline,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}