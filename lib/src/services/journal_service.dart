import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/journal_entry.dart';
import '../../core/utils/logger.dart';
import 'firebase_setup_service.dart';

class JournalService extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<JournalEntry> _entries = [];
  bool _loading = false;
  String? _lastError;
  JournalEntry? _currentEntry;

  bool get loading => _loading;
  List<JournalEntry> get entries => _entries;
  String? get lastError => _lastError;
  JournalEntry? get currentEntry => _currentEntry;

  /// Load all journal entries for the current user
  Future<void> loadEntries() async {
    final user = _auth.currentUser;
    if (user == null) {
      Logger.debug('JournalService.loadEntries: No user logged in');
      return;
    }
    
    if (_loading) {
      Logger.debug('JournalService.loadEntries: Already loading, skipping');
      return;
    }
    
    Logger.info('JournalService.loadEntries: Starting load for user ${user.uid}');
    _loading = true;
    _lastError = null;
    notifyListeners();
    
    try {
      // Step 1: Load from cache first for immediate display
      await _loadFromCache();
      if (_entries.isNotEmpty) {
        notifyListeners(); // Show cached data immediately
      }
      
      // Step 2: Check Firebase setup
      if (!FirebaseSetupService.isFullyConfigured) {
        Logger.warning('JournalService.loadEntries: Firebase not configured, attempting setup...');
        final setupSuccess = await FirebaseSetupService.reinitialize();
        if (!setupSuccess) {
          throw Exception('Firebase setup failed: ${FirebaseSetupService.lastError}');
        }
      }
      
      // Step 3: Fetch from Firestore
      Logger.debug('JournalService.loadEntries: Fetching from Firestore...');
      
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('journal_entries')
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 20));
      
      if (querySnapshot.docs.isNotEmpty) {
        _entries = querySnapshot.docs.map((doc) => JournalEntry.fromMap(doc.data())).toList();
        await _saveToCache();
        Logger.info('JournalService.loadEntries: Successfully loaded ${_entries.length} entries from Firestore');
      }
      
      _lastError = null;
      
    } catch (e) {
      Logger.error('JournalService.loadEntries: Error loading entries', e);
      
      if (e.toString().contains('unavailable') || e.toString().contains('offline')) {
        _lastError = 'Working offline - journal may not be current';
      } else {
        _lastError = 'Unable to sync journal entries';
      }
    }
    
    _loading = false;
    notifyListeners();
  }

  /// Save or update a journal entry
  Future<void> saveEntry(JournalEntry entry) async {
    Logger.info('JournalService.saveEntry: Saving entry "${entry.title}"');
    
    try {
      // Always save locally first
      final existingIndex = _entries.indexWhere((e) => e.id == entry.id);
      if (existingIndex != -1) {
        _entries[existingIndex] = entry;
      } else {
        _entries.insert(0, entry);
      }
      
      // Sort by creation date
      _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      await _saveToCache();
      _lastError = null;
      
      Logger.info('JournalService.saveEntry: Entry saved locally');
      
      // Try to save to Firebase if user is logged in
      final user = _auth.currentUser;
      if (user != null && FirebaseSetupService.isFullyConfigured) {
        try {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('journal_entries')
              .doc(entry.id)
              .set(entry.toMap(), SetOptions(merge: true))
              .timeout(const Duration(seconds: 20));
          
          Logger.info('JournalService.saveEntry: Entry synced to cloud');
        } catch (e) {
          Logger.warning('JournalService.saveEntry: Cloud sync failed, but entry is saved locally', e);
          // Continue - local save succeeded
        }
      } else {
        Logger.info('JournalService.saveEntry: Working offline - entry saved locally only');
      }
      
    } catch (e) {
      Logger.error('JournalService.saveEntry: Error saving entry', e);
      _lastError = 'Failed to save entry';
      rethrow;
    }
    
    notifyListeners();
  }

  /// Delete a journal entry
  Future<void> deleteEntry(String entryId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      if (FirebaseSetupService.isFullyConfigured) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('journal_entries')
            .doc(entryId)
            .delete()
            .timeout(const Duration(seconds: 20));
      }
      
      _entries.removeWhere((entry) => entry.id == entryId);
      await _saveToCache();
      _lastError = null;
      
      Logger.info('JournalService.deleteEntry: Successfully deleted entry $entryId');
      
    } catch (e) {
      Logger.error('JournalService.deleteEntry: Error deleting entry', e);
      _lastError = 'Error deleting entry';
    }
    
    notifyListeners();
  }

  /// Get all journal text for AI analysis (for career guidance)
  String getAllJournalText() {
    if (_entries.isEmpty) return '';
    
    final allText = _entries
        .map((entry) => '${entry.title}\n${entry.content}')
        .join('\n\n---\n\n');
    
    Logger.debug('JournalService.getAllJournalText: Extracted ${allText.length} characters from ${_entries.length} entries');
    return allText;
  }

  /// Get journal insights for AI analysis
  Map<String, dynamic> getJournalInsights() {
    if (_entries.isEmpty) return {};
    
    final totalWords = _entries.fold<int>(0, (total, entry) => total + entry.wordCount);
    final avgWordsPerEntry = totalWords / _entries.length;
    final moodCounts = <String, int>{};
    final tagCounts = <String, int>{};
    
    for (final entry in _entries) {
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
      for (final tag in entry.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    
    return {
      'totalEntries': _entries.length,
      'totalWords': totalWords,
      'averageWordsPerEntry': avgWordsPerEntry.round(),
      'writingFrequency': _entries.length / (DateTime.now().difference(_entries.last.createdAt).inDays.clamp(1, 365)),
      'dominantMood': moodCounts.entries.isNotEmpty ? moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key : 'neutral',
      'commonTags': tagCounts.entries.take(5).map((e) => e.key).toList(),
      'moodDistribution': moodCounts,
      'allText': getAllJournalText(),
    };
  }

  /// Cache management
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedEntriesJson = prefs.getString('cached_journal_entries');
      
      if (cachedEntriesJson != null) {
        final List<dynamic> entriesList = json.decode(cachedEntriesJson);
        _entries = entriesList.map((data) => JournalEntry.fromMap(data)).toList();
        _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        Logger.debug('JournalService._loadFromCache: Loaded ${_entries.length} cached entries');
      }
    } catch (e) {
      Logger.error('JournalService._loadFromCache: Error loading cached entries', e);
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = json.encode(_entries.map((entry) => entry.toMap()).toList());
      await prefs.setString('cached_journal_entries', entriesJson);
      
      Logger.debug('JournalService._saveToCache: Cached ${_entries.length} entries');
    } catch (e) {
      Logger.error('JournalService._saveToCache: Error caching entries', e);
    }
  }

  /// Set current entry for editing
  void setCurrentEntry(JournalEntry? entry) {
    _currentEntry = entry;
    notifyListeners();
  }
}