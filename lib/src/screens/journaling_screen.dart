import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/journal_service.dart';
import '../models/journal_entry.dart';
import '../widgets/connection_status_widget.dart';
import 'journal_editor_screen.dart';

class JournalingScreen extends StatefulWidget {
  const JournalingScreen({super.key});

  @override
  State<JournalingScreen> createState() => _JournalingScreenState();
}

class _JournalingScreenState extends State<JournalingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    
    // Load journal entries
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalService>().loadEntries();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journalService = context.watch<JournalService>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F1), // Warm paper-like background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8F6F1),
        foregroundColor: const Color(0xFF3A2F2A),
        title: Text(
          'My Journal',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A2F2A),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showJournalInsights(context, journalService),
            icon: const Icon(Icons.insights, color: Color(0xFF8B4513)),
            tooltip: 'Journal Insights',
          ),
          IconButton(
            onPressed: () => _createNewEntry(context),
            icon: const Icon(Icons.edit_note, color: Color(0xFF8B4513)),
            tooltip: 'New Entry',
          ),
        ],
      ),
      body: Column(
        children: [
          ConnectionStatusWidget(errorMessage: journalService.lastError),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: journalService.loading && journalService.entries.isEmpty
                  ? _buildLoadingState()
                  : journalService.entries.isEmpty
                      ? _buildEmptyState(context)
                      : _buildJournalList(context, journalService),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewEntry(context),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.create),
        label: Text(
          'Write',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your journal...',
            style: GoogleFonts.inter(
              color: const Color(0xFF3A2F2A),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF8B4513).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 60,
                color: Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Journal Awaits',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A2F2A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start capturing your thoughts, experiences, and daily reflections. Your words help us understand you better.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF6B5B5B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _createNewEntry(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.create),
              label: Text(
                'Write First Entry',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalList(BuildContext context, JournalService journalService) {
    return RefreshIndicator(
      onRefresh: () => journalService.loadEntries(),
      color: const Color(0xFF8B4513),
      child: CustomScrollView(
        slivers: [
          // Header stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildJournalStats(journalService),
            ),
          ),
          
          // Journal entries
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = journalService.entries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildJournalCard(context, entry, journalService),
                  );
                },
                childCount: journalService.entries.length,
              ),
            ),
          ),
          
          // Bottom padding for FAB
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalStats(JournalService journalService) {
    final totalEntries = journalService.entries.length;
    final totalWords = journalService.entries.fold<int>(0, (sum, entry) => sum + entry.wordCount);
    final avgWords = totalEntries > 0 ? (totalWords / totalEntries).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B4513).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem('Entries', totalEntries.toString(), Icons.book),
          const VerticalDivider(color: Color(0xFFE0E0E0)),
          _buildStatItem('Words', totalWords.toString(), Icons.text_fields),
          const VerticalDivider(color: Color(0xFFE0E0E0)),
          _buildStatItem('Avg/Entry', avgWords.toString(), Icons.analytics),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: const Color(0xFF8B4513)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A2F2A),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF6B5B5B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalCard(BuildContext context, JournalEntry entry, JournalService journalService) {
    final daysSince = DateTime.now().difference(entry.createdAt).inDays;
    final timeText = daysSince == 0 
        ? 'Today'
        : daysSince == 1 
          ? 'Yesterday'
          : '$daysSince days ago';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _editEntry(context, entry),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A2F2A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editEntry(context, entry);
                        } else if (value == 'delete') {
                          _deleteEntry(context, entry, journalService);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Text(
                  entry.content,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B5B5B),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getMoodColor(entry.mood).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getMoodEmoji(entry.mood),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.mood.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getMoodColor(entry.mood),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${entry.wordCount} words',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF8B8B8B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF8B8B8B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': return const Color(0xFF4CAF50);
      case 'excited': return const Color(0xFFFF9800);
      case 'sad': return const Color(0xFF2196F3);
      case 'stressed': return const Color(0xFFf44336);
      case 'calm': return const Color(0xFF9C27B0);
      case 'grateful': return const Color(0xFFE91E63);
      default: return const Color(0xFF607D8B);
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': return '😊';
      case 'excited': return '🎉';
      case 'sad': return '😔';
      case 'stressed': return '😰';
      case 'calm': return '😌';
      case 'grateful': return '🙏';
      default: return '😐';
    }
  }

  void _createNewEntry(BuildContext context) {
    final newEntry = JournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '',
      content: '',
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      wordCount: 0,
    );
    
    context.read<JournalService>().setCurrentEntry(newEntry);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const JournalEditorScreen(isNewEntry: true),
      ),
    );
  }

  void _editEntry(BuildContext context, JournalEntry entry) {
    context.read<JournalService>().setCurrentEntry(entry);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const JournalEditorScreen(isNewEntry: false),
      ),
    );
  }

  void _deleteEntry(BuildContext context, JournalEntry entry, JournalService journalService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Entry',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${entry.title}"? This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              journalService.deleteEntry(entry.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showJournalInsights(BuildContext context, JournalService journalService) {
    final insights = journalService.getJournalInsights();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Journal Insights',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Entries: ${insights['totalEntries']}'),
              Text('Total Words: ${insights['totalWords']}'),
              Text('Average Words/Entry: ${insights['averageWordsPerEntry']}'),
              Text('Dominant Mood: ${insights['dominantMood']}'),
              const SizedBox(height: 8),
              Text('Writing helps us understand your personality and thought patterns for better career guidance.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}