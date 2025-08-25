
import 'package:flutter/material.dart';
import 'dart:ui';
import 'quiz_screen.dart';

class ResultsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final result = QuizResultStore.latestResult;
    if (result.isEmpty) {
      return Center(child: Text('No quiz results yet.', style: TextStyle(fontSize: 18)));
    }
    final lines = result.split('\n');
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
                        Icon(Icons.emoji_events, size: 64, color: Colors.indigo),
                        SizedBox(height: 24),
                        Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        SizedBox(height: 16),
                        Text(description,
                          style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.left,
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