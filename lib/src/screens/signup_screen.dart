
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../models/user_profile.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String gender = '';
  final TextEditingController passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  void _signup() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Create account
      final user = await _auth.signUp(emailController.text.trim(), passwordController.text.trim());
      if (user != null) {
        // Save profile information through ProfileService
        final profileService = Provider.of<ProfileService>(context, listen: false);
        final profile = UserProfile(
          uid: user.uid,
          email: emailController.text.trim(),
          displayName: nameController.text.trim(),
          age: ageController.text.trim(),
          gender: gender,
        );
        await profileService.saveProfile(profile);
        
        // Sign out after signup so user can login
        await _auth.signOut();
        
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Please login.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Navigate back to login screen
          Navigator.pop(context);
        }
      } else {
        setState(() => _error = 'Could not sign up');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFEF0),
      appBar: AppBar(
        title: Text('Create Account'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(0xFFB20000),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Join DIRECTIONS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB20000),
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Start your career journey',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 32),
                // Email
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFB20000)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                // Name
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline, color: Color(0xFFB20000)),
                  ),
                ),
                SizedBox(height: 16),
                // Age
                TextField(
                  controller: ageController,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake_outlined, color: Color(0xFFB20000)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                // Gender
                DropdownButtonFormField<String>(
                  value: gender.isNotEmpty ? gender : null,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.people_outline, color: Color(0xFFB20000)),
                  ),
                  items: ['Male', 'Female', 'Other']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (val) => setState(() => gender = val ?? ''),
                ),
                SizedBox(height: 16),
                // Password
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFB20000)),
                  ),
                  obscureText: true,
                ),
                if (_error != null) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red[800], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                SizedBox(height: 32),
                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signup,
                    child: _loading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Create Account',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}