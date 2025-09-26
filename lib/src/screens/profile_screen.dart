
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/profile_service.dart';

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    final firestore = FirebaseFirestore.instance;

    Future<void> attempt() async {
      await firestore.collection('users').doc(user.uid).set({
        'email': user.email ?? '',
        'displayName': _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        'age': _ageCtrl.text.trim(),
        'gender': _genderCtrl.text.trim(),
      }, SetOptions(merge: true));
    }

    try {
      await attempt();
    } catch (e) {
      if (e.toString().contains('unavailable') || e.toString().contains('network') || e.toString().contains('deadline')) {
        await Future.delayed(const Duration(milliseconds: 800));
        await attempt();
      } else {
        rethrow;
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
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
                  color: Colors.white.withValues(alpha: 0.95),
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
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: user == null
                              ? const Stream.empty()
                              : FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
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
                                  decoration: InputDecoration(labelText: 'Name'),
                                  textInputAction: TextInputAction.next,
                                ),
                                SizedBox(height: 12),
                                TextField(
                                  controller: _ageCtrl,
                                  decoration: InputDecoration(labelText: 'Age'),
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                ),
                                SizedBox(height: 12),
                                TextField(
                                  controller: _genderCtrl,
                                  decoration: InputDecoration(labelText: 'Gender'),
                                  textInputAction: TextInputAction.done,
                                ),
                                SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _saving ? null : _save,
                                    child: Text(_saving ? 'Saving...' : 'Save'),
                                  ),
                                ),
                                SizedBox(height: 16),
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