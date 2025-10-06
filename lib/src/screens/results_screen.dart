import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/results_service.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    // Load results when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final resultsService = Provider.of<ResultsService>(context, listen: false);
      resultsService.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsService = Provider.of<ResultsService>(context);
    final results = resultsService.results;
    final loading = resultsService.loading;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Results'),
        backgroundColor: Colors.indigo,
      ),
      body: Container(
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
                  color: Colors.white.withValues(alpha: 0.95),
                  elevation: 12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: loading
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.indigo),
                                SizedBox(height: 16),
                                Text('Loading results...', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          )
                        : results.isEmpty
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inbox, size: 80, color: Colors.grey),
                                  SizedBox(height: 24),
                                  Text(
                                    'You haven\'t taken any quiz yet!',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Take a career quiz to get personalized recommendations.',
                                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 32),
                                  ElevatedButton.icon(
                                    onPressed: () => Navigator.of(context).pop(),
                                    icon: Icon(Icons.arrow_back),
                                    label: Text('Back to Home'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                    ),
                                  ),
                                ],
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Your Career Results',
                                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 24),
                                    Divider(),
                                    SizedBox(height: 16),
                                    ...results.map((result) {
                                      final description = result.description ?? '';
                                      final lines = description.split('\n');
                                      final title = lines.isNotEmpty ? lines[0] : result.recommendedCareers.join(', ');
                                      final body = lines.length > 1 ? lines.sublist(1).join('\n') : '';
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 24.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.emoji_events, size: 32, color: Colors.orange),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    title,
                                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              body,
                                              style: TextStyle(fontSize: 16, color: Colors.black87),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Date: ${result.createdAt.toString().split(' ')[0]}',
                                              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
                                            ),
                                            Divider(height: 32),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
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
}