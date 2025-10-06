
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
            colors: [Color(0xFFB20000), Color(0xFF8B0000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFFFFEF0)),
              SizedBox(height: 24),
              Text(
                '✨ Analyzing your answers...',
                style: TextStyle(
                  color: Color(0xFFFFFEF0), 
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(color: Color(0xFFB20000).withOpacity(0.2), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(36.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFFB20000).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.work_outline, size: 64, color: Color(0xFFB20000)),
                      ),
                      SizedBox(height: 28),
                      Text(
                        title, 
                        style: TextStyle(
                          fontSize: 26, 
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB20000),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
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
                            fontSize: 17,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 36),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.home_rounded),
                        label: Text('Back to Home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFB20000),
                          foregroundColor: Color(0xFFFFFEF0),
                          padding: EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: Color(0xFFB20000).withOpacity(0.2), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Progress indicator
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Color(0xFFB20000).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 350),
                        child: Row(
                          key: ValueKey(_current),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.quiz_outlined, color: Color(0xFFB20000), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Question ${_current + 1} of ${quizQuestions.length}', 
                              style: TextStyle(
                                fontSize: 16, 
                                color: Color(0xFFB20000), 
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    // Question text
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFFEF0), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        q.question, 
                        style: TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.bold, 
                          color: Color(0xFF8B0000),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 28),
                    // Options
                    ...List.generate(q.options.length, (i) => Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selected[_current] == q.options[i] 
                            ? Color(0xFFB20000) 
                            : Color(0xFFB20000).withOpacity(0.2),
                          width: _selected[_current] == q.options[i] ? 2 : 1,
                        ),
                        color: _selected[_current] == q.options[i]
                          ? Color(0xFFB20000).withOpacity(0.05)
                          : Colors.transparent,
                      ),
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        title: Text(
                          q.options[i], 
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: _selected[_current] == q.options[i] 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                            color: _selected[_current] == q.options[i]
                              ? Color(0xFFB20000)
                              : Colors.black87,
                          ),
                        ),
                        value: q.options[i],
                        groupValue: _selected[_current],
                        activeColor: Color(0xFFB20000),
                        onChanged: (val) {
                          setState(() {
                            _selected[_current] = val!;
                            _custom[_current] = '';
                          });
                        },
                      ),
                    )),
                    SizedBox(height: 16),
                    // Custom answer field
                    TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        labelText: '✍️ Or write your own answer',
                        labelStyle: TextStyle(color: Color(0xFFB20000).withOpacity(0.7)),
                        filled: true,
                        fillColor: Color(0xFFFFFEF0).withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Color(0xFFB20000).withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Color(0xFFB20000).withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Color(0xFFB20000), width: 2),
                        ),
                      ),
                      style: TextStyle(fontSize: 17),
                      onChanged: (val) {
                        setState(() {
                          _custom[_current] = val;
                          if (val.isNotEmpty) _selected[_current] = '';
                        });
                      },
                    ),
                    SizedBox(height: 32),
                    // Next/Submit button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFB20000),
                        foregroundColor: Color(0xFFFFFEF0),
                        disabledBackgroundColor: Color(0xFFB20000).withOpacity(0.3),
                        disabledForegroundColor: Color(0xFFFFFEF0).withOpacity(0.5),
                        padding: EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        textStyle: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
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
                          Text(_current < quizQuestions.length - 1 ? 'Next Question' : 'Submit Quiz'),
                          SizedBox(width: 8),
                          Icon(_current < quizQuestions.length - 1 ? Icons.arrow_forward_rounded : Icons.check_circle_outline, size: 22),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}