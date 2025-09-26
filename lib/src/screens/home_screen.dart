

import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'quiz_screen.dart';
import 'results_screen.dart';
import 'profile_screen.dart';
import 'journaling_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    DashboardScreen(),
    QuizScreen(),
    ResultsScreen(),
    JournalingScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFB3E5FC), // sky blue
      appBar: AppBar(
        title: Text('Career Guidance'),
        backgroundColor: Colors.blue,
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 350),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        color: Colors.blue,
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard, color: Colors.white),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.quiz, color: Colors.white),
              label: 'Quiz',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events, color: Colors.white),
              label: 'Results',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book, color: Colors.white),
              label: 'Journal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, color: Colors.white),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          backgroundColor: Colors.blue,
          onTap: _onItemTapped,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}