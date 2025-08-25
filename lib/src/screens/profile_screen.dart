

import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/user_profile.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFB3E5FC),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Card(
                  color: Colors.white.withOpacity(0.95),
                  elevation: 12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.person, size: 48, color: Colors.white),
                        ),
                        SizedBox(height: 24),
                        Text('Profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue)),
                        SizedBox(height: 24),
                        Divider(thickness: 1.5),
                        SizedBox(height: 16),
                        _profileRow('Email', UserProfile.email),
                        _profileRow('Name', UserProfile.name),
                        _profileRow('Age', UserProfile.age),
                        _profileRow('Gender', UserProfile.gender),
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

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('$label:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.indigo)),
          SizedBox(width: 12),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}