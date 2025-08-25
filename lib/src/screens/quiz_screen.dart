
import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/quiz_question.dart';
import '../services/gemini_service.dart';

class QuizResultStore {
  static String latestResult = '';
}

class QuizScreen extends StatefulWidget {
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
    final gemini = GeminiService();
    final response = await gemini.getCareerSuggestion(answers);
    setState(() {
      _result = response;
      QuizResultStore.latestResult = response;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_result != null) {
      final lines = _result!.split('\n');
      String title = lines.isNotEmpty ? lines[0] : 'Recommended Career';
      String description = lines.length > 1 ? lines.sublist(1).join(' ') : '';
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.work, size: 64, color: Colors.indigo),
                SizedBox(height: 24),
                Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Text(description, style: TextStyle(fontSize: 18)),
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
                color: Colors.white.withOpacity(0.85),
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