import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import '../theme/app_theme.dart';
import '../widgets/paper_background.dart';
import 'journal_editor_screen.dart';

class JournalingScreen extends StatefulWidget {
  const JournalingScreen({super.key});

  @override
  State<JournalingScreen> createState() => _JournalingScreenState();
}

class _JournalingScreenState extends State<JournalingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeAnim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _fadeAnim, curve: Curves.easeOut);
    _fadeAnim.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalService>().loadEntries();
    });
  }

  @override
  void dispose() {
    _fadeAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journalService = context.watch<JournalService>();
    final entries = [...journalService.entries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return PaperBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.crimson,
          onRefresh: () => journalService.loadEntries(),
          child: FadeTransition(
            opacity: _fade,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(entries.length)),
                if (journalService.loading && entries.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.crimson),
                    ),
                  )
                else if (entries.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _emptyState(context),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                    sliver: SliverList.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 16),
                      itemBuilder: (_, i) => _DiaryEntryCard(
                        entry: entries[i],
                        index: entries.length - i,
                        onTap: () => _editEntry(entries[i]),
                        onDelete: () =>
                            _confirmDelete(entries[i], journalService),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EST. ${DateTime.now().year}',
                      style: GoogleFonts.inter(
                        color: AppColors.inkMuted,
                        fontSize: 10,
                        letterSpacing: 2.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'My Diary',
                      style: GoogleFonts.playfairDisplay(
                        color: AppColors.crimsonDeep,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              _writeButton(),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const PageOrnament(width: 100),
              const SizedBox(width: 10),
              Text(
                total == 0
                    ? 'a blank book, awaiting words'
                    : '$total ${total == 1 ? "entry" : "entries"} so far',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.inkSoft,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _writeButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _createNewEntry,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: AppColors.crimsonGradient,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: [
              BoxShadow(
                color: AppColors.crimson.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_note_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                'New page',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.crimson.withValues(alpha: 0.06),
              border: Border.all(
                  color: AppColors.crimson.withValues(alpha: 0.20)),
            ),
            child: const Icon(Icons.auto_stories_rounded,
                size: 56, color: AppColors.crimsonDark),
          ),
          const SizedBox(height: 28),
          Text(
            'A fresh, untouched book.',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.ink,
              fontSize: 22,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Start by writing your first page —\na thought, a worry, a small win, anything.',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.inkSoft,
              fontSize: 14,
              height: 1.55,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewEntry,
            icon: const Icon(Icons.create_rounded),
            label: const Text('Open the first page'),
          ),
        ],
      ),
    );
  }

  void _createNewEntry() {
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
        builder: (_) => const JournalEditorScreen(isNewEntry: true),
      ),
    );
  }

  void _editEntry(JournalEntry entry) {
    context.read<JournalService>().setCurrentEntry(entry);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const JournalEditorScreen(isNewEntry: false),
      ),
    );
  }

  void _confirmDelete(JournalEntry entry, JournalService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        title: Text(
          'Tear out this page?',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          'Once removed, "${entry.title.isEmpty ? "this entry" : entry.title}" cannot be brought back.',
          style: GoogleFonts.inter(color: AppColors.inkSoft, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () {
              service.deleteEntry(entry.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Tear out'),
          ),
        ],
      ),
    );
  }
}

class _DiaryEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DiaryEntryCard({
    required this.entry,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(
                    color: AppColors.crimson.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.crimsonDeep.withValues(alpha: 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                child: CustomPaint(
                  painter: _PageEdgePainter(),
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 18, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _dateLine(),
                        const SizedBox(height: 6),
                        Text(
                          entry.title.isNotEmpty
                              ? entry.title
                              : 'Untitled page',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            color: AppColors.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (entry.content.isNotEmpty)
                          Text(
                            entry.content,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              color: AppColors.inkSoft,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _moodChip(),
                            const SizedBox(width: 10),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.inkMuted
                                    .withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${entry.wordCount} words',
                              style: GoogleFonts.inter(
                                color: AppColors.inkMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            _menuButton(context),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Page-number ribbon in the corner
            Positioned(
              top: 0,
              right: 14,
              child: _pageNumber(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageNumber() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        gradient: AppColors.crimsonGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(alpha: 0.30),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No.',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 8,
              fontStyle: FontStyle.italic,
            ),
          ),
          Text(
            '$index',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateLine() {
    final dt = entry.createdAt;
    final wd = _weekday(dt.weekday);
    final mn = _monthName(dt.month);
    final dayOrd = _ordinal(dt.day);
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Expanded(
          child: Text(
            '$wd, the $dayOrd of $mn ${dt.year}',
            style: GoogleFonts.playfairDisplay(
              color: AppColors.crimsonDark,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Text(
          time,
          style: GoogleFonts.inter(
            color: AppColors.inkMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _moodChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.crimson.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_moodEmoji(entry.mood),
              style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            entry.mood,
            style: GoogleFonts.inter(
              color: AppColors.crimsonDark,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuButton(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'More',
      icon: const Icon(Icons.more_horiz_rounded,
          color: AppColors.inkMuted, size: 20),
      color: AppColors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: BorderSide(color: AppColors.crimson.withValues(alpha: 0.15)),
      ),
      onSelected: (v) {
        if (v == 'edit') onTap();
        if (v == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined,
                  size: 16, color: AppColors.ink),
              const SizedBox(width: 8),
              Text('Edit',
                  style: GoogleFonts.inter(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w500,
                      fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded,
                  size: 16, color: AppColors.danger),
              const SizedBox(width: 8),
              Text('Tear out',
                  style: GoogleFonts.inter(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w500,
                      fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  String _moodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'excited':
        return '🎉';
      case 'sad':
        return '😔';
      case 'stressed':
        return '😰';
      case 'anxious':
        return '😟';
      case 'calm':
        return '😌';
      case 'grateful':
        return '🙏';
      default:
        return '🖋';
    }
  }

  String _weekday(int wd) =>
      const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][wd - 1];

  String _monthName(int m) => const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ][m - 1];

  String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }
}

/// Paints a soft inner shadow / page-edge to give the card a worn paper feel.
class _PageEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.crimsonDeep.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.center,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
