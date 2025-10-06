import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../../core/utils/logger.dart';
import 'firebase_setup_service.dart';

class ProfileService extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  UserProfile? _profile;
  bool _loading = false;
  String? _lastError;
  bool get loading => _loading;
  UserProfile? get profile => _profile;
  String? get lastError => _lastError;

  Future<void> load() async {
    final user = _auth.currentUser;
    if (user == null) {
      Logger.debug('ProfileService.load: No user logged in');
      return;
    }
    
    if (_loading) {
      Logger.debug('ProfileService.load: Already loading, skipping');
      return;
    }
    
    Logger.info('ProfileService.load: Starting load for user ${user.uid}');
    _loading = true;
    _lastError = null;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Step 1: Load from cache first for immediate display
      final cachedEmail = prefs.getString('profile_email');
      if (cachedEmail != null) {
        _profile = UserProfile(
          uid: user.uid,
          email: cachedEmail,
          displayName: prefs.getString('profile_displayName'),
          age: prefs.getString('profile_age'),
          gender: prefs.getString('profile_gender'),
          preferences: null,
        );
        Logger.debug('ProfileService.load: Loaded cached profile for $cachedEmail');
        notifyListeners(); // Show cached data immediately
      }
      
      // Step 2: Check if Firebase is properly configured
      if (!FirebaseSetupService.isFullyConfigured) {
        Logger.warning('ProfileService.load: Firebase not fully configured, attempting setup...');
        final setupSuccess = await FirebaseSetupService.reinitialize();
        if (!setupSuccess) {
          throw Exception('Firebase setup failed: ${FirebaseSetupService.lastError}');
        }
      }
      
      // Step 3: Try to fetch from Firestore
      Logger.debug('ProfileService.load: Fetching from Firestore...');
      
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 20));
      
      if (doc.exists && doc.data() != null) {
        // Update profile with Firestore data
        _profile = UserProfile.fromMap(user.uid, doc.data()!);
        await _cache(_profile!);
        Logger.info('ProfileService.load: Successfully loaded profile from Firestore');
      } else {
        // Create new profile if none exists
        Logger.debug('ProfileService.load: No profile found, creating new one');
        _profile = UserProfile(
          uid: user.uid, 
          email: user.email ?? '',
          displayName: user.displayName,
        );
        
        // Save new profile to Firestore
        await save(_profile!);
        Logger.info('ProfileService.load: Created and saved new profile');
      }
      
      _lastError = null;
      
    } catch (e) {
      Logger.error('ProfileService.load: Error loading profile', e);
      
      // If we have cached data, continue using it
      _profile ??= UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
      );
      
      // Set user-friendly error message
      if (e.toString().contains('unavailable') || e.toString().contains('offline')) {
        _lastError = 'Working offline - profile data may not be current';
      } else {
        _lastError = 'Unable to sync profile data';
      }
    }
    
    _loading = false;
    notifyListeners();
  }

  Future<void> save(UserProfile profile) async {
    Logger.info('ProfileService.save: Saving profile');
    
    try {
      // Always save locally first
      _profile = profile;
      await _cache(profile);
      _lastError = null;
      
      Logger.info('ProfileService.save: Profile saved locally');
      
      // Try to save to Firebase if user is logged in
      final user = _auth.currentUser;
      if (user != null && FirebaseSetupService.isFullyConfigured) {
        try {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(profile.toMap(), SetOptions(merge: true))
              .timeout(const Duration(seconds: 20));
          
          Logger.info('ProfileService.save: Profile synced to cloud');
        } catch (e) {
          Logger.warning('ProfileService.save: Cloud sync failed, but profile is saved locally', e);
          // Continue - local save succeeded
        }
      } else {
        Logger.info('ProfileService.save: Working offline - profile saved locally only');
      }
      
    } catch (e) {
      Logger.error('ProfileService.save: Error saving profile', e);
      _lastError = 'Failed to save profile';
      rethrow;
    }
    
    notifyListeners();
  }

  Future<void> _cache(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_email', profile.email);
      
      if (profile.displayName != null) {
        await prefs.setString('profile_displayName', profile.displayName!);
      } else {
        await prefs.remove('profile_displayName');
      }
      
      if (profile.age != null) {
        await prefs.setString('profile_age', profile.age!);
      } else {
        await prefs.remove('profile_age');
      }
      
      if (profile.gender != null) {
        await prefs.setString('profile_gender', profile.gender!);
      } else {
        await prefs.remove('profile_gender');
      }
      
      Logger.debug('ProfileService._cache: Cached profile data');
    } catch (e) {
      Logger.error('ProfileService._cache: Error caching profile', e);
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    Logger.info('ProfileService.saveProfile: Saving profile');
    
    try {
      _loading = true;
      notifyListeners();
      
      // Always save locally first
      _profile = profile;
      await _cache(profile);
      _lastError = null;
      
      Logger.info('ProfileService.saveProfile: Profile saved locally');
      
      // Try to save to Firebase if user is logged in
      final user = _auth.currentUser;
      if (user != null && FirebaseSetupService.isFullyConfigured) {
        try {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(profile.toMap(), SetOptions(merge: true))
              .timeout(const Duration(seconds: 20));
          
          Logger.info('ProfileService.saveProfile: Profile synced to cloud');
        } catch (e) {
          Logger.warning('ProfileService.saveProfile: Cloud sync failed, but profile is saved locally', e);
          // Continue - local save succeeded
        }
      } else {
        Logger.info('ProfileService.saveProfile: Working offline - profile saved locally only');
      }

      notifyListeners();
    } catch (e) {
      Logger.error('ProfileService.saveProfile: Error saving profile', e);
      _lastError = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}