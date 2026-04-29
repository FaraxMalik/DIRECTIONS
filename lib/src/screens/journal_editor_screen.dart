import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/journal_service.dart';
import '../theme/app_theme.dart';
import '../widgets/paper_background.dart';

class JournalEditorScreen extends StatefulWidget {
  final bool isNewEntry;
  const JournalEditorScreen({super.key, required this.isNewEntry});

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final FocusNode _titleFocus;
  late final FocusNode _contentFocus;

  String _selectedMood = 'neutral';
  List<String> _tags = [];
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  static const List<({String key, String emoji})> _moods = [
    (key: 'happy', emoji: '😊'),
    (key: 'excited', emoji: '🎉'),
    (key: 'calm', emoji: '😌'),
    (key: 'grateful', emoji: '🙏'),
    (key: 'neutral', emoji: '🖋'),
    (key: 'sad', emoji: '😔'),
    (key: 'stressed', emoji: '😰'),
    (key: 'anxious', emoji: '😟'),
  ];

  @override
  void initState() {
    super.initState();
    final svc = context.read<JournalService>();
    final cur = svc.currentEntry;

    _titleController = TextEditingController(text: cur?.title ?? '');
    _contentController = TextEditingController(text: cur?.content ?? '');
    _titleFocus = FocusNode();
    _contentFocus = FocusNode();

    if (cur != null) {
      _selectedMood = cur.mood;
      _tags = List.of(cur.tags);
    }

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isNewEntry) {
        _titleFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    } else {
      // We still want word count to refresh
      setState(() {});
    }
  }

  int get _wordCount {
    final t = _contentController.text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      _showEmptyEntryDialog();
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    try {
      final svc = context.read<JournalService>();
      final cur = svc.currentEntry;
      if (cur != null) {
        final updated = cur.copyWith(
          title: _titleController.text.trim().isEmpty
              ? 'Untitled page'
              : _titleController.text.trim(),
          content: _contentController.text.trim(),
          modifiedAt: DateTime.now(),
          mood: _selectedMood,
          tags: _tags,
          wordCount: _wordCount,
        );
        await svc.saveEntry(updated);

        if (!mounted) return;
        setState(() {
          _hasUnsavedChanges = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Page saved.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEmptyEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: Text(
          'Empty page',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
        content: Text(
          'Add a title or some words before saving this page.',
          style: GoogleFonts.inter(color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showUnsavedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: Text(
          'Close without saving?',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
        content: Text(
          'You have unsaved words on this page.',
          style: GoogleFonts.inter(color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.inkMuted),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveEntry();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
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
    ];
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    String ordinal(int d) {
      if (d >= 11 && d <= 13) return '${d}th';
      switch (d % 10) {
        case 1:
          return '${d}st';
        case 2:
          return '${d}nd';
        case 3:
          return '${d}rd';
        default:
          return '${d}th';
      }
    }

    return '${weekdays[dt.weekday - 1]}, the ${ordinal(dt.day)} of '
        '${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final dateLine = _formatDate(DateTime.now());

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _hasUnsavedChanges) _showUnsavedDialog();
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.ink),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            widget.isNewEntry ? 'New page' : 'Editing page',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: AppColors.ink,
            ),
          ),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.crimson,
                  ),
                ),
              )
            else
              TextButton.icon(
                onPressed: _saveEntry,
                icon: const Icon(Icons.brush_rounded, size: 16),
                label: const Text('Save'),
              ),
            const SizedBox(width: 4),
          ],
        ),
        body: PaperBackground(
          ruled: true,
          lineSpacing: 30,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date / preamble
                      Center(
                        child: Column(
                          children: [
                            Text(
                              dateLine,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplay(
                                color: AppColors.crimsonDark,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const PageOrnament(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Title (looks hand-written, italic serif)
                      TextField(
                        controller: _titleController,
                        focusNode: _titleFocus,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: AppColors.ink,
                          height: 1.15,
                        ),
                        textInputAction: TextInputAction.next,
                        cursorColor: AppColors.crimson,
                        decoration: InputDecoration(
                          hintText: 'Title this page...',
                          hintStyle: GoogleFonts.playfairDisplay(
                            fontSize: 30,
                            fontStyle: FontStyle.italic,
                            color: AppColors.inkMuted
                                .withValues(alpha: 0.55),
                          ),
                          isCollapsed: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _contentFocus.requestFocus(),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 1,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.crimson,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      // Body content
                      TextField(
                        controller: _contentController,
                        focusNode: _contentFocus,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16.5,
                          color: AppColors.ink,
                          height: 1.85,
                        ),
                        cursorColor: AppColors.crimson,
                        maxLines: null,
                        minLines: 14,
                        decoration: InputDecoration(
                          hintText:
                              'Dear diary,\n\nWrite as if no one will ever read this — '
                              'a thought, a worry, a small win, anything that matters today...',
                          hintStyle: GoogleFonts.playfairDisplay(
                            fontSize: 16.5,
                            color: AppColors.inkMuted
                                .withValues(alpha: 0.55),
                            height: 1.85,
                            fontStyle: FontStyle.italic,
                          ),
                          isCollapsed: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),

                      const SizedBox(height: 32),
                      Center(child: const PageOrnament(width: 60)),
                      const SizedBox(height: 16),

                      // Mood selector
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        decoration: BoxDecoration(
                          color: AppColors.beige,
                          borderRadius:
                              BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: AppColors.crimson.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'How are you feeling?',
                              style: GoogleFonts.playfairDisplay(
                                color: AppColors.ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _moods.map((m) {
                                final selected = _selectedMood == m.key;
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedMood = m.key;
                                    _hasUnsavedChanges = true;
                                  }),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.crimson
                                          : AppColors.cream,
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.crimson
                                            : AppColors.crimson
                                                .withValues(alpha: 0.20),
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          AppRadii.pill),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(m.emoji,
                                            style: const TextStyle(
                                                fontSize: 13)),
                                        const SizedBox(width: 6),
                                        Text(
                                          m.key,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.4,
                                            color: selected
                                                ? Colors.white
                                                : AppColors.crimsonDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _bottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border(
          top: BorderSide(
            color: AppColors.crimson.withValues(alpha: 0.20),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.text_fields_rounded,
              size: 14, color: AppColors.inkMuted),
          const SizedBox(width: 5),
          Text(
            '$_wordCount words',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_hasUnsavedChanges) ...[
            const SizedBox(width: 14),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.crimson,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'unsaved',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.crimson,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveEntry,
            icon: _isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.brush_rounded, size: 16),
            label: Text(
              _isSaving ? 'Sealing...' : 'Save page',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimson,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
