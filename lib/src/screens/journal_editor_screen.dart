import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/journal_service.dart';

class JournalEditorScreen extends StatefulWidget {
  final bool isNewEntry;
  
  const JournalEditorScreen({
    super.key,
    required this.isNewEntry,
  });

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;
  
  String _selectedMood = 'neutral';
  List<String> _tags = [];
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  
  final List<String> _availableMoods = [
    'happy', 'excited', 'calm', 'grateful', 'neutral', 'sad', 'stressed', 'anxious'
  ];

  @override
  void initState() {
    super.initState();
    
    final journalService = context.read<JournalService>();
    final currentEntry = journalService.currentEntry;
    
    _titleController = TextEditingController(text: currentEntry?.title ?? '');
    _contentController = TextEditingController(text: currentEntry?.content ?? '');
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();
    
    if (currentEntry != null) {
      _selectedMood = currentEntry.mood;
      _tags = List.from(currentEntry.tags);
    }
    
    // Listen for changes
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
    
    // Auto-focus based on entry type
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isNewEntry) {
        _titleFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  int get _wordCount {
    final text = _contentController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _hasUnsavedChanges) {
          _showUnsavedChangesDialog();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F1),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFF8F6F1),
          foregroundColor: const Color(0xFF3A2F2A),
          title: Text(
            widget.isNewEntry ? 'New Entry' : 'Edit Entry',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3A2F2A),
            ),
          ),
          actions: [
            if (_hasUnsavedChanges && !_isSaving)
              TextButton(
                onPressed: _saveEntry,
                child: Text(
                  'Save',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B4513),
                  ),
                ),
              ),
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Input
                    Container(
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
                      child: TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A2F2A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Entry title...',
                          hintStyle: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            color: const Color(0xFFB0B0B0),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) {
                          _contentFocusNode.requestFocus();
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Content Input
                    Container(
                      constraints: const BoxConstraints(minHeight: 300),
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
                      child: TextField(
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: const Color(0xFF3A2F2A),
                          height: 1.6,
                        ),
                        decoration: InputDecoration(
                          hintText: 'What\'s on your mind today?\n\nWrite about your experiences, thoughts, feelings, or anything that happened...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 16,
                            color: const Color(0xFFB0B0B0),
                            height: 1.6,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Mood Selection
                    Container(
                      padding: const EdgeInsets.all(20),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How are you feeling?',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3A2F2A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableMoods.map((mood) {
                              final isSelected = mood == _selectedMood;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedMood = mood;
                                    _hasUnsavedChanges = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? const Color(0xFF8B4513)
                                        : const Color(0xFFF0F0F0),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected 
                                          ? const Color(0xFF8B4513)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _getMoodEmoji(mood),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        mood.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected 
                                              ? Colors.white
                                              : const Color(0xFF6B5B5B),
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
                    
                    const SizedBox(height: 100), // Space for bottom bar
                  ],
                ),
              ),
            ),
            
            // Bottom Stats Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.text_fields,
                    size: 16,
                    color: const Color(0xFF8B8B8B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_wordCount words',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF8B8B8B),
                    ),
                  ),
                  const Spacer(),
                  if (_hasUnsavedChanges) ...[
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: const Color(0xFFFF6B6B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Unsaved changes',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF8B8B8B),
                      ),
                    ),
                  ],
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B4513),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isSaving 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Save',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': return '😊';
      case 'excited': return '🎉';
      case 'calm': return '😌';
      case 'grateful': return '🙏';
      case 'sad': return '😔';
      case 'stressed': return '😰';
      case 'anxious': return '😟';
      default: return '😐';
    }
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty) {
      _showEmptyEntryDialog();
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    try {
      final journalService = context.read<JournalService>();
      final currentEntry = journalService.currentEntry;
      
      if (currentEntry != null) {
        final updatedEntry = currentEntry.copyWith(
          title: _titleController.text.trim().isEmpty 
              ? 'Untitled Entry'
              : _titleController.text.trim(),
          content: _contentController.text.trim(),
          modifiedAt: DateTime.now(),
          mood: _selectedMood,
          tags: _tags,
          wordCount: _wordCount,
        );
        
        await journalService.saveEntry(updatedEntry);
        
        setState(() {
          _hasUnsavedChanges = false;
          _isSaving = false;
        });
        
        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Entry saved successfully!',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving entry: $e',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Unsaved Changes',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'You have unsaved changes. Do you want to save them before leaving?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close editor
            },
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _saveEntry(); // Save and close
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEmptyEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Empty Entry',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Please add a title or content before saving.',
          style: GoogleFonts.inter(),
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
}