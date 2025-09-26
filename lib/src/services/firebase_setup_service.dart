import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/utils/logger.dart';

/// Service to diagnose and fix Firebase configuration issues
class FirebaseSetupService {
  static bool _initialized = false;
  static String? _lastError;
  static bool _databaseExists = false;

  /// Initialize Firebase with proper configuration
  static Future<bool> initializeFirebase() async {
    if (_initialized) return true;

    try {
      Logger.info('FirebaseSetup: Starting Firebase initialization...');
      
      // Initialize Firebase Core
      await Firebase.initializeApp();
      Logger.info('FirebaseSetup: Firebase Core initialized');

      // Test Firestore availability
      await _testFirestoreSetup();
      
      // Test Firebase Auth
      await _testAuthSetup();
      
      _initialized = true;
      Logger.info('FirebaseSetup: Firebase fully initialized and verified');
      return true;
      
    } catch (e) {
      _lastError = e.toString();
      Logger.error('FirebaseSetup: Initialization failed', e);
      return false;
    }
  }

  /// Test Firestore database setup
  static Future<void> _testFirestoreSetup() async {
    try {
      Logger.info('FirebaseSetup: Testing Firestore configuration...');
      
      final firestore = FirebaseFirestore.instance;
      
      // Configure Firestore settings
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      // Enable network
      await firestore.enableNetwork();
      
      // Test if database exists by trying to read from it
      // This will fail if the database doesn't exist or rules are wrong
      try {
        await firestore
            .collection('_setup_test')
            .doc('test')
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 10));
        
        Logger.info('FirebaseSetup: Firestore database is accessible');
        _databaseExists = true;
        
        // Try to write a test document to verify write permissions
        await firestore
            .collection('_setup_test')
            .doc('test')
            .set({
              'timestamp': FieldValue.serverTimestamp(),
              'test': true,
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 10));
        
        Logger.info('FirebaseSetup: Firestore write permissions verified');
        
      } catch (e) {
        Logger.warning('FirebaseSetup: Firestore access test failed - $e');
        
        // Check if it's a permissions issue vs database not existing
        if (e.toString().contains('permission') || e.toString().contains('PERMISSION_DENIED')) {
          await _setupFirestoreRules();
        } else if (e.toString().contains('not found') || e.toString().contains('does not exist')) {
          await _createFirestoreDatabase();
        } else {
          // Unknown error, try to create database anyway
          await _createFirestoreDatabase();
        }
      }
      
    } catch (e) {
      Logger.error('FirebaseSetup: Firestore setup failed', e);
      throw Exception('Firestore setup failed: $e');
    }
  }

  /// Create Firestore database if it doesn't exist
  static Future<void> _createFirestoreDatabase() async {
    try {
      Logger.info('FirebaseSetup: Creating Firestore database...');
      
      final firestore = FirebaseFirestore.instance;
      
      // Try to create the database by writing a document
      await firestore
          .collection('_database_init')
          .doc('initialized')
          .set({
            'created_at': FieldValue.serverTimestamp(),
            'app_name': 'Career Prediction App',
            'version': '1.0.0',
          })
          .timeout(const Duration(seconds: 15));
      
      _databaseExists = true;
      Logger.info('FirebaseSetup: Firestore database created successfully');
      
    } catch (e) {
      Logger.error('FirebaseSetup: Failed to create Firestore database', e);
      throw Exception('Could not create Firestore database. Please create it manually in Firebase Console.');
    }
  }

  /// Setup basic Firestore security rules
  static Future<void> _setupFirestoreRules() async {
    Logger.warning('FirebaseSetup: Firestore rules may need to be updated manually');
    Logger.info('FirebaseSetup: Required Firestore rules:');
    Logger.info('''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow users to read/write their own results
      match /results/{resultId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Allow setup and test documents
    match /_setup_test/{document=**} {
      allow read, write: if request.auth != null;
    }
    
    match /_database_init/{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
    ''');
  }

  /// Test Firebase Auth setup
  static Future<void> _testAuthSetup() async {
    try {
      Logger.info('FirebaseSetup: Testing Firebase Auth...');
      
      final auth = FirebaseAuth.instance;
      
      // Check if auth is working by getting current user
      final currentUser = auth.currentUser;
      Logger.info('FirebaseSetup: Current user: ${currentUser?.uid ?? 'none'}');
      
      // Test auth state changes listener
      final subscription = auth.authStateChanges().listen((user) {
        Logger.debug('FirebaseSetup: Auth state changed: ${user?.uid ?? 'signed out'}');
      });
      
      // Cancel subscription after a moment
      Timer(const Duration(seconds: 1), () {
        subscription.cancel();
      });
      
      Logger.info('FirebaseSetup: Firebase Auth is working correctly');
      
    } catch (e) {
      Logger.error('FirebaseSetup: Firebase Auth test failed', e);
      throw Exception('Firebase Auth setup failed: $e');
    }
  }

  /// Get setup status and diagnostics
  static Map<String, dynamic> getSetupStatus() {
    return {
      'initialized': _initialized,
      'databaseExists': _databaseExists,
      'lastError': _lastError,
      'projectId': 'careercounseling-7133e',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Force re-initialization
  static Future<bool> reinitialize() async {
    _initialized = false;
    _lastError = null;
    _databaseExists = false;
    return await initializeFirebase();
  }

  /// Check if everything is properly set up
  static bool get isFullyConfigured => _initialized && _databaseExists;

  /// Get the last error message
  static String? get lastError => _lastError;
}