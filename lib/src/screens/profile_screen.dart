import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/profile_service.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final profile = profileService.profile;
    _nameCtrl.text = profile?.displayName ?? '';
    _ageCtrl.text = profile?.age?.toString() ?? '';
    _genderCtrl.text = profile?.gender ?? '';
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final profileService = Provider.of<ProfileService>(context, listen: false);

      final profile = UserProfile(
        uid: FirebaseAuth.instance.currentUser?.uid ?? 'offline_user',
        email: FirebaseAuth.instance.currentUser?.email ?? 'offline@example.com',
        displayName: _nameCtrl.text.trim(),
        age: _ageCtrl.text.trim().isEmpty ? null : _ageCtrl.text.trim(),
        gender: _genderCtrl.text.trim().isEmpty ? null : _genderCtrl.text.trim(),
      );

      await profileService.saveProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFEF0), Color(0xFFF5E6D3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                color: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(
                    color: const Color(0xFFB20000).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFB20000), width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFFB20000).withOpacity(0.1),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 60,
                            color: Color(0xFFB20000),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB20000).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.account_circle_outlined,
                              color: Color(0xFFB20000),
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Profile',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB20000),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFB20000).withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Live Firestore Data
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: user == null
                            ? const Stream.empty()
                            : FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .snapshots(),
                        builder: (context, snap) {
                          final data = snap.data?.data();
                          final email = data?['email'] ?? user?.email ?? '';
                          final name = data?['displayName'] ?? _nameCtrl.text;
                          final age = data?['age'] ?? _ageCtrl.text;
                          final gender = data?['gender'] ?? _genderCtrl.text;

                          return Column(
                            children: [
                              _profileRow('Email', email),
                              TextField(
                                controller: _nameCtrl,
                                decoration:
                                    const InputDecoration(labelText: 'Name'),
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _ageCtrl,
                                decoration:
                                    const InputDecoration(labelText: 'Age'),
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _genderCtrl,
                                decoration:
                                    const InputDecoration(labelText: 'Gender'),
                                textInputAction: TextInputAction.done,
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saving ? null : _save,
                                  child: Text(_saving ? 'Saving...' : 'Save'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _profileRow('Live Name', name),
                              _profileRow('Live Age', age),
                              _profileRow('Live Gender', gender),
                            ],
                          );
                        },
                      ),
                    ],
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF0).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB20000).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFB20000).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              label.contains('Email')
                  ? Icons.email_outlined
                  : label.contains('Name')
                      ? Icons.person_outline
                      : label.contains('Age')
                          ? Icons.cake_outlined
                          : Icons.info_outline,
              color: const Color(0xFFB20000),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFB20000).withOpacity(0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not set' : value,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
