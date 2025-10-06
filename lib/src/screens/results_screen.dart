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
        title: Text('Your Results'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFEF0), Color(0xFFF5E6D3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              color: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(color: Color(0xFFB20000).withOpacity(0.2), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: loading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Color(0xFFB20000)),
                            SizedBox(height: 16),
                            Text(
                              'Loading results...', 
                              style: TextStyle(
                                fontSize: 17, 
                                color: Color(0xFFB20000),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : results.isEmpty
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Color(0xFFB20000).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.inbox_outlined, size: 80, color: Color(0xFFB20000)),
                              ),
                              SizedBox(height: 28),
                              Text(
                                'You haven\'t taken any quiz yet!',
                                style: TextStyle(
                                  fontSize: 22, 
                                  fontWeight: FontWeight.bold, 
                                  color: Color(0xFFB20000),
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFFFEF0),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Take a career quiz to get personalized recommendations.',
                                  style: TextStyle(fontSize: 17, color: Colors.grey[700], height: 1.5),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: 36),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(Icons.arrow_back_rounded),
                                label: Text('Back to Home'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFB20000),
                                  foregroundColor: Color(0xFFFFFEF0),
                                  padding: EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFB20000).withOpacity(0.1), Colors.transparent],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.emoji_events_outlined, color: Color(0xFFB20000), size: 28),
                                      SizedBox(width: 12),
                                      Text(
                                        'Your Career Results',
                                        style: TextStyle(
                                          fontSize: 26, 
                                          fontWeight: FontWeight.bold, 
                                          color: Color(0xFFB20000),
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 24),
                                Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Color(0xFFB20000).withOpacity(0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 24),
                                ...results.map((result) {
                                  final description = result.description ?? '';
                                  final lines = description.split('\n');
                                  final title = lines.isNotEmpty ? lines[0] : result.recommendedCareers.join(', ');
                                  final body = lines.length > 1 ? lines.sublist(1).join('\n') : '';
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 20.0),
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFFFFEF0).withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Color(0xFFB20000).withOpacity(0.2)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Color(0xFFB20000).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(Icons.star_rounded, size: 28, color: Color(0xFFB20000)),
                                            ),
                                            SizedBox(width: 16),
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: TextStyle(
                                                  fontSize: 20, 
                                                  fontWeight: FontWeight.bold, 
                                                  color: Color(0xFF8B0000),
                                                  height: 1.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          body,
                                          style: TextStyle(
                                            fontSize: 16, 
                                            color: Colors.black87,
                                            height: 1.6,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFFB20000).withOpacity(0.6)),
                                            SizedBox(width: 6),
                                            Text(
                                              'Date: ${result.createdAt.toString().split(' ')[0]}',
                                              style: TextStyle(
                                                fontSize: 14, 
                                                color: Color(0xFFB20000).withOpacity(0.7), 
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
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
    );
  }
}