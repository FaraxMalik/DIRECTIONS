import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.all(32.0),
          child: Card(
            elevation: 8,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: Color(0xFFB20000).withOpacity(0.2), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(36.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFFB20000).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.dashboard_rounded, size: 80, color: Color(0xFFB20000)),
                  ),
                  SizedBox(height: 28),
                  Text(
                    'Welcome to DIRECTIONS!', 
                    style: TextStyle(
                      fontSize: 30, 
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB20000),
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFFEF0).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Start your journey by taking the quiz or view your profile.', 
                      style: TextStyle(fontSize: 18, color: Colors.grey[700], height: 1.5), 
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 36),
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0xFFB20000).withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFB20000).withOpacity(0.05),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Color(0xFFB20000).withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.format_quote, color: Color(0xFFB20000).withOpacity(0.4), size: 32),
                        SizedBox(height: 12),
                        Text(
                          'Success is not the key to happiness. Happiness is the key to success. If you love what you are doing, you will be successful.',
                          style: TextStyle(
                            fontSize: 20, 
                            fontStyle: FontStyle.italic, 
                            color: Color(0xFF8B0000),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '- Albert Schweitzer', 
                          style: TextStyle(
                            fontSize: 16, 
                            color: Color(0xFFB20000).withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ), 
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
