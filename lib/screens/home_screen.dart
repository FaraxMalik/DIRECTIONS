import 'package:flutter/material.dart';
import 'quiz_screen.dart';
import 'results_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Career Guidance')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen()));
              },
              child: Text('Take Quiz'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ResultsScreen()));
              },
              child: Text('View Results'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
              },
              child: Text('Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
