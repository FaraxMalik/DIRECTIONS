
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
        backgroundColor: Colors.indigo,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade400, Colors.blueAccent.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 24),
              Text(
                'Analyzing your answers...',
                style: TextStyle(color: Colors.white, fontSize: 18),
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
            colors: [Colors.indigo.shade400, Colors.blueAccent.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.work, size: 64, color: Colors.indigo),
                      SizedBox(height: 24),
                      Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      Text(description, style: TextStyle(fontSize: 18)),
                      SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.home),
                        label: Text('Back to Home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
          colors: [Colors.indigo.shade400, Colors.blueAccent.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Card(
                color: Colors.white.withValues(alpha: 0.85),
                elevation: 12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 350),
                          child: Text('Question ${_current + 1} of ${quizQuestions.length}', key: ValueKey(_current), style: TextStyle(fontSize: 16, color: Colors.indigo, fontWeight: FontWeight.w600)),
                        ),
                        SizedBox(height: 16),
                        Text(q.question, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo.shade700)),
                        SizedBox(height: 24),
                        ...List.generate(q.options.length, (i) => RadioListTile<String>(
                          title: Text(q.options[i], style: TextStyle(fontSize: 18)),
                          value: q.options[i],
                          groupValue: _selected[_current],
                          activeColor: Colors.indigo,
                          onChanged: (val) {
                            setState(() {
                              _selected[_current] = val!;
                              _custom[_current] = '';
                            });
                          },
                        )),
                        TextField(
                          controller: textController,
                          decoration: InputDecoration(
                            labelText: 'Or write your own answer',
                            filled: true,
                            fillColor: Colors.indigo.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          style: TextStyle(fontSize: 18),
                          onChanged: (val) {
                            setState(() {
                              _custom[_current] = val;
                              if (val.isNotEmpty) _selected[_current] = '';
                            });
                          },
                        ),
                        SizedBox(height: 32),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            elevation: 4,
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
                          child: Text(_current < quizQuestions.length - 1 ? 'Next' : 'Submit'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}