import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFB3E5FC), // sky blue
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dashboard, size: 80, color: Colors.indigo),
                  SizedBox(height: 24),
                  Text('Welcome to DIRECTIONS!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Text('Start your journey by taking the quiz or view your profile.', style: TextStyle(fontSize: 18, color: Colors.grey[700]), textAlign: TextAlign.center),
                  SizedBox(height: 32),
                  Divider(thickness: 1.5),
                  SizedBox(height: 24),
                  Text(
                    '"Success is not the key to happiness. Happiness is the key to success. If you love what you are doing, you will be successful."',
                    style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic, color: Colors.indigo.shade700),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text('- Albert Schweitzer', style: TextStyle(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
