import 'package:flutter/material.dart';
import '../services/firebase_setup_service.dart';
import '../../core/utils/logger.dart';

class FirebaseConnectionDialog extends StatefulWidget {
  const FirebaseConnectionDialog({super.key});

  @override
  State<FirebaseConnectionDialog> createState() => _FirebaseConnectionDialogState();
}

class _FirebaseConnectionDialogState extends State<FirebaseConnectionDialog> {
  Map<String, dynamic>? _connectionStatus;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isChecking = true;
    });

    try {
      await FirebaseSetupService.initializeFirebase();
      final status = FirebaseSetupService.getSetupStatus();
      
      setState(() {
        _connectionStatus = status;
        _isChecking = false;
      });
    } catch (e) {
      Logger.error('FirebaseConnectionDialog: Error checking connection', e);
      setState(() {
        _connectionStatus = {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Firebase Connection Status'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isChecking)
              const Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Checking connection...'),
                ],
              )
            else if (_connectionStatus != null) ...[
              _buildStatusRow('Firebase Initialized', _connectionStatus!['isInitialized'] ?? false),
              const SizedBox(height: 8),
              _buildStatusRow('Database Setup', _connectionStatus!['isDatabaseSetup'] ?? false),
              const SizedBox(height: 8),
              _buildStatusRow('Permissions Valid', _connectionStatus!['hasPermissions'] ?? false),
              const SizedBox(height: 8),
              if (_connectionStatus!['lastError'] != null) ...[
                const Text('Last Error:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  _connectionStatus!['lastError'],
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
              ],
              const Text('Timestamp:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                _connectionStatus!['timestamp'] ?? 'Unknown',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _checkConnection,
          child: const Text('Refresh'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Row(
      children: [
        Icon(
          status ? Icons.check_circle : Icons.error,
          color: status ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text(
          status ? 'OK' : 'Failed',
          style: TextStyle(
            color: status ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}