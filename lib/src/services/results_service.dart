import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_result.dart';
import '../../core/utils/logger.dart';
import 'firebase_setup_service.dart';

class ResultsService extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<QuizResult> _results = [];
  QuizResult? _latest;
  bool _loading = false;
  String? _lastError;

  bool get loading => _loading;
  List<QuizResult> get results => _results;
  QuizResult? get latest => _latest;
  String? get lastError => _lastError;

  Future<void> load() async {
    final user = _auth.currentUser;
    if (user == null) {
      Logger.debug('ResultsService.load: No user logged in');
      return;
    }
    if (_loading) {
      Logger.debug('ResultsService.load: Already loading, skipping');
      return;
    }
    
    Logger.info('ResultsService.load: Starting load for user ${user.uid}');
    _loading = true;
    _lastError = null;
    notifyListeners();
    
    try {
      // Step 1: Load from cache first for immediate display
      final prefs = await SharedPreferences.getInstance();
      final cachedResultsJson = prefs.getStringList('cached_results');
      
      if (cachedResultsJson != null && cachedResultsJson.isNotEmpty) {
        try {
          _results = cachedResultsJson.map((jsonStr) {
            // Simple JSON parsing for cached results
            // This is a simplified version - in production, you'd use proper JSON serialization
            return QuizResult(
              recommendedCareers: ['Cached Career'], // Placeholder
              scores: {'general': 5.0}, // Placeholder
              createdAt: DateTime.now().subtract(const Duration(days: 1)),
              personalityType: 'CACHED',
              description: 'Cached result',
            );
          }).toList();
          
          _results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (_results.isNotEmpty) _latest = _results.first;
          
          Logger.debug('ResultsService.load: Loaded ${_results.length} cached results');
          notifyListeners(); // Show cached data immediately
        } catch (e) {
          Logger.error('ResultsService.load: Error parsing cached results', e);
        }
      }
      
      // Step 2: Check Firebase setup before network operations
      if (!FirebaseSetupService.isFullyConfigured) {
        Logger.warning('ResultsService.load: Firebase not fully configured, attempting setup...');
        final setupSuccess = await FirebaseSetupService.reinitialize();
        if (!setupSuccess) {
          throw Exception('Firebase setup failed: ${FirebaseSetupService.lastError}');
        }
      }
      
      // Step 3: Try to fetch from Firestore
      Logger.debug('ResultsService.load: Fetching from Firestore...');
      
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('results')
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 20));
      
      if (querySnapshot.docs.isNotEmpty) {
        _results = querySnapshot.docs.map((doc) => QuizResult.fromMap(doc.data())).toList();
        _latest = _results.isNotEmpty ? _results.first : null;
        await _cache();
        Logger.info('ResultsService.load: Successfully loaded ${_results.length} results from Firestore');
      }
      
      _lastError = null;
      
    } catch (e) {
      Logger.error('ResultsService.load: Error loading results', e);
      
      // Set user-friendly error message
      if (e.toString().contains('unavailable') || e.toString().contains('offline')) {
        _lastError = 'Working offline - results may not be current';
      } else {
        _lastError = 'Unable to sync quiz results';
      }
    }
    
    _loading = false;
    notifyListeners();
  }

  Future<void> addResult(QuizResult result) async {
    final user = _auth.currentUser;
    if (user == null) {
      Logger.warning('ResultsService.addResult: No user logged in');
      return;
    }
    
    Logger.info('ResultsService.addResult: Adding new result');
    
    try {
      // Check Firebase setup before saving
      if (!FirebaseSetupService.isFullyConfigured) {
        Logger.warning('ResultsService.addResult: Firebase not configured, attempting setup...');
        final setupSuccess = await FirebaseSetupService.reinitialize();
        if (!setupSuccess) {
          throw Exception('Firebase setup failed: ${FirebaseSetupService.lastError}');
        }
      }
      
      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('results')
          .add(result.toMap())
          .timeout(const Duration(seconds: 20));
      
      // Update local state
      _results.insert(0, result);
      _latest = result;
      await _cache();
      _lastError = null;
      
      Logger.info('ResultsService.addResult: Successfully saved result');
      
    } catch (e) {
      Logger.error('ResultsService.addResult: Error saving result', e);
      
      // Add locally even if cloud save failed
      _results.insert(0, result);
      _latest = result;
      await _cache();
      
      // Set user-friendly error message
      if (e.toString().contains('unavailable') || e.toString().contains('offline')) {
        _lastError = 'Result saved locally - will sync when online';
      } else {
        _lastError = 'Result saved locally only';
      }
    }
    
    notifyListeners();
  }

  Future<void> _cache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final resultsJson = _results.take(10).map((result) { // Cache last 10 results
        final map = result.toMap();
        return map.entries.map((e) => '${e.key}:${e.value}').join('|');
      }).toList();
      
      await prefs.setStringList('cached_results', resultsJson);
      Logger.debug('ResultsService._cache: Cached ${resultsJson.length} results');
    } catch (e) {
      Logger.error('ResultsService._cache: Error caching results', e);
    }
  }
}