import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/personality_results.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/personality_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _gender = '';
  bool _saving = false;
  PersonalityResults? _personality;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProfileService>().load();
      _hydrateFields();
      await _loadPersonality();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _hydrateFields() {
    final p = context.read<ProfileService>().profile;
    if (p != null && mounted) {
      setState(() {
        _nameCtrl.text = p.displayName ?? '';
        _ageCtrl.text = p.age ?? '';
        _gender = p.gender ?? '';
      });
    }
  }

  Future<void> _loadPersonality() async {
    try {
      final p = await PersonalityService().getPersonalityResults();
      if (mounted) setState(() => _personality = p);
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _toast('Please enter your name.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final profile = UserProfile(
        uid: user?.uid ?? 'offline_user',
        email: user?.email ?? 'offline@example.com',
        displayName: _nameCtrl.text.trim(),
        age: _ageCtrl.text.trim().isEmpty ? null : _ageCtrl.text.trim(),
        gender: _gender.isEmpty ? null : _gender,
      );
      await context.read<ProfileService>().saveProfile(profile);
      _toast('Profile saved.');
    } catch (e) {
      _toast('Failed to save: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final profileService = context.watch<ProfileService>();

    final initial = (_nameCtrl.text.isNotEmpty)
        ? _nameCtrl.text[0].toUpperCase()
        : (user?.email?.isNotEmpty ?? false)
            ? user!.email![0].toUpperCase()
            : '?';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(),
            const SizedBox(height: 20),
            _avatarSection(initial, user?.email ?? ''),
            const SizedBox(height: 24),
            if (_personality != null) ...[
              _personalitySnapshot(),
              const SizedBox(height: 22),
            ],
            _sectionTitle('Your details'),
            const SizedBox(height: 12),
            _formCard(),
            const SizedBox(height: 22),
            _signOutButton(),
            if (profileService.lastError != null) ...[
              const SizedBox(height: 16),
              Text(
                profileService.lastError!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Profile',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.ink,
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _avatarSection(String initial, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.crimsonGradient,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Your name',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email.isNotEmpty ? email : 'No email available',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _personalitySnapshot() {
    final p = _personality!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_alt_rounded,
                  color: AppColors.crimson, size: 20),
              const SizedBox(width: 8),
              Text(
                'Personality snapshot',
                style: GoogleFonts.inter(
                  color: AppColors.inkSoft,
                  fontSize: 12,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            p.mbtiLikeType,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.crimson,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 6),
          _miniBar('Openness', p.bigFive.openness),
          _miniBar('Conscientiousness', p.bigFive.conscientiousness),
          _miniBar('Extraversion', p.bigFive.extraversion),
          _miniBar('Agreeableness', p.bigFive.agreeableness),
          _miniBar('Neuroticism', p.bigFive.neuroticism),
        ],
      ),
    );
  }

  Widget _miniBar(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${value.toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.crimson,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppColors.beigeDeep,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.crimson),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.playfairDisplay(
        color: AppColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon:
                  Icon(Icons.person_outline, color: AppColors.crimson),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake_outlined,
                        color: AppColors.crimson),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _gender.isEmpty ? null : _gender,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon:
                        Icon(Icons.wc_outlined, color: AppColors.crimson),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(
                        value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _gender = v ?? ''),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(_saving ? 'Saving...' : 'Save changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signOutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        onPressed: _signOut,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Sign out'),
      ),
    );
  }
}
