import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'quiz_screen.dart';
import 'results_screen.dart';
import 'profile_screen.dart';
import 'journaling_screen.dart';
import 'login_screen.dart';
import '../services/profile_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load profile data when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileService = Provider.of<ProfileService>(context, listen: false);
      profileService.load();
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final profileService = Provider.of<ProfileService>(context);
    final userName = profileService.profile?.displayName ?? user?.email?.split('@')[0] ?? 'User';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFB20000), // Deep red
              Color(0xFFD32F2F), // Lighter red
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with App Name
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DIRECTIONS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Find Your Path',
                              style: TextStyle(
                                color: Color(0xFFFFFEF0),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.logout_rounded, color: Colors.white),
                            onPressed: _logout,
                            tooltip: 'Logout',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color(0xFFFFFEF0).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.waving_hand_rounded, color: Color(0xFFFFFEF0), size: 20),
                          SizedBox(width: 12),
                          Text(
                            'Welcome back, $userName',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Cards
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFEF0), // Light beige background
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildOptionCard(
                          context,
                          'Take Quiz',
                          Icons.lightbulb_rounded,
                          Color(0xFFB20000),
                          Color(0xFFD32F2F),
                        ),
                        _buildOptionCard(
                          context,
                          'Results',
                          Icons.auto_graph_rounded,
                          Color(0xFF8B4513),
                          Color(0xFFA0522D),
                        ),
                        _buildOptionCard(
                          context,
                          'Profile',
                          Icons.account_circle_rounded,
                          Color(0xFFB20000),
                          Color(0xFFD32F2F),
                        ),
                        _buildOptionCard(
                          context,
                          'Journal',
                          Icons.menu_book_rounded,
                          Color(0xFF8B4513),
                          Color(0xFFA0522D),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color startColor,
    Color endColor,
  ) {
    return GestureDetector(
      onTap: () {
        if (title == 'Take Quiz') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen()));
        } else if (title == 'Results') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultsScreen()));
        } else if (title == 'Profile') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        } else if (title == 'Journal') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const JournalingScreen()));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: startColor.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}