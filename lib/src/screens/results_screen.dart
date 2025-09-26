
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/results_service.dart';
import '../widgets/connection_status_widget.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: user == null
          ? const Stream.empty()
          : FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('results')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade400, Colors.blueAccent.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Card(
                    color: Colors.white.withOpacity(0.85),
                    elevation: 12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: docs.isEmpty
                          ? Text('No quiz results yet.', style: TextStyle(fontSize: 18))
                          : SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: docs.map((d) {
                                  final text = d.data()['text'] as String? ?? '';
                                  final lines = text.split('\n');
                                  final title = lines.isNotEmpty ? lines[0] : 'Recommended Career';
                                  final description = lines.length > 1 ? lines.sublist(1).join(' ') : '';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 24.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.emoji_events, size: 64, color: Colors.indigo),
                                        SizedBox(height: 16),
                                        Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                        SizedBox(height: 12),
                                        Text(description, style: TextStyle(fontSize: 16, color: Colors.black)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}