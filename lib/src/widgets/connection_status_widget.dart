import 'package:flutter/material.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final String? errorMessage;
  
  const ConnectionStatusWidget({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    if (errorMessage == null) return const SizedBox.shrink();
    
    final isOfflineMessage = errorMessage!.contains('offline') || 
                            errorMessage!.contains('unavailable') ||
                            errorMessage!.contains('connection');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isOfflineMessage ? Colors.orange.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOfflineMessage ? Colors.orange : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOfflineMessage ? Icons.wifi_off : Icons.error_outline,
            color: isOfflineMessage ? Colors.orange : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOfflineMessage ? 'Working offline - some features may be limited' : errorMessage!,
              style: TextStyle(
                color: isOfflineMessage ? Colors.orange[800] : Colors.red[800],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}