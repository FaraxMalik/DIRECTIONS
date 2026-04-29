import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/personality_results.dart';
import '../services/groq_service.dart';
import '../services/journal_service.dart';
import '../services/personality_service.dart';
import '../theme/app_theme.dart';

class _ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  _ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

class CareerCounselorScreen extends StatefulWidget {
  const CareerCounselorScreen({super.key});

  @override
  State<CareerCounselorScreen> createState() => _CareerCounselorScreenState();
}

class _CareerCounselorScreenState extends State<CareerCounselorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  final GroqService _groq = GroqService();

  final List<_ChatMessage> _messages = [];
  String _systemPrompt = '';
  bool _isTyping = false;
  bool _isInitializing = true;
  PersonalityResults? _personality;

  late final AnimationController _typingAnim;

  static const List<String> _starters = [
    "I'm confused about which career path to choose",
    'Should I do CSS or join the private sector?',
    'How do I start freelancing in Pakistan?',
    'I want to study abroad but my parents disagree',
    'What career suits my personality best?',
    'I feel stuck in my current job',
  ];

  @override
  void initState() {
    super.initState();
    _typingAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _initializeCounselor();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    _typingAnim.dispose();
    super.dispose();
  }

  Future<void> _initializeCounselor() async {
    try {
      final journalService =
          Provider.of<JournalService>(context, listen: false);
      await journalService.loadEntries();
      final journalInsights = journalService.getJournalInsights();

      PersonalityResults? personality;
      try {
        personality = await PersonalityService().getPersonalityResults();
      } catch (_) {}

      _personality = personality;
      _systemPrompt = GroqService.buildSystemPrompt(
        personality: personality,
        journalInsights: journalInsights.isNotEmpty ? journalInsights : null,
      );

      final greeting = await _groq.chat([
        {'role': 'system', 'content': _systemPrompt},
        {
          'role': 'user',
          'content':
              '[The user has just opened the chat. Greet them warmly in 2-3 short sentences. '
                  'Reference their personality or journal subtly if you can. End with an open-ended '
                  "question that invites them to share what's on their mind.]"
        }
      ]);

      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          content: greeting,
          timestamp: DateTime.now(),
        ));
        _isInitializing = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          content:
              "Assalam-o-Alaikum! I'm Faraz, your personal career counselor. "
              "I'm here to help you think through any career questions or doubts you have. "
              "What's on your mind today?",
          timestamp: DateTime.now(),
        ));
        _isInitializing = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping) return;

    setState(() {
      _messages.add(_ChatMessage(
        role: 'user',
        content: text.trim(),
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
      _inputController.clear();
    });
    _scrollToBottom();
    HapticFeedback.lightImpact();

    final history = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
      ..._messages.map((m) => {'role': m.role, 'content': m.content}),
    ];

    final response = await _groq.chat(history);
    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
      ));
      _isTyping = false;
    });
    _scrollToBottom();
    HapticFeedback.selectionClick();
  }

  void _resetChat() {
    setState(() {
      _messages.clear();
      _isInitializing = true;
    });
    _initializeCounselor();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildChatBody()),
          if (_messages.length <= 1 && !_isInitializing && !_isTyping)
            _buildStarterChips(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.beige,
        border: Border(
          bottom: BorderSide(color: AppColors.beigeDeep, width: 1),
        ),
      ),
      child: Row(
        children: [
          _avatar(size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Faraz',
                      style: GoogleFonts.playfairDisplay(
                        color: AppColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded,
                        size: 16, color: AppColors.crimson),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isTyping ? 'typing...' : 'Your career counselor',
                      style: GoogleFonts.inter(
                        color: AppColors.inkSoft,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _resetChat,
            tooltip: 'New chat',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.crimson),
          ),
        ],
      ),
    );
  }

  Widget _avatar({double size = 36}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.crimsonGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(Icons.auto_awesome_rounded,
          color: Colors.white, size: size * 0.5),
    );
  }

  Widget _buildChatBody() {
    if (_isInitializing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _avatar(size: 64),
            const SizedBox(height: 18),
            Text(
              'Faraz is reviewing your profile...',
              style: GoogleFonts.inter(
                color: AppColors.inkSoft,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _personality != null
                  ? 'Personalizing for ${_personality!.mbtiLikeType}'
                  : 'Preparing your session',
              style: GoogleFonts.inter(
                color: AppColors.inkMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return _typingBubble();
        return _messageBubble(_messages[index]);
      },
    );
  }

  Widget _messageBubble(_ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _avatar(size: 30),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.crimsonGradient : null,
                color: isUser ? null : AppColors.surface,
                border: isUser
                    ? null
                    : Border.all(
                        color: AppColors.crimson.withValues(alpha: 0.10)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: AppColors.crimson.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    msg.content,
                    style: GoogleFonts.inter(
                      color: isUser ? Colors.white : AppColors.ink,
                      fontSize: 14.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(msg.timestamp),
                    style: GoogleFonts.inter(
                      color: (isUser ? Colors.white : AppColors.inkMuted)
                          .withValues(alpha: 0.65),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.crimson.withValues(alpha: 0.10),
                border: Border.all(
                    color: AppColors.crimson.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.person_rounded,
                  color: AppColors.crimson, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _typingBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _avatar(size: 30),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              border:
                  Border.all(color: AppColors.crimson.withValues(alpha: 0.10)),
            ),
            child: AnimatedBuilder(
              animation: _typingAnim,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.2;
                    final v = (_typingAnim.value - delay) % 1.0;
                    final opacity =
                        0.3 + 0.7 * (1 - (v - 0.5).abs() * 2).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.crimson.withValues(alpha: opacity),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarterChips() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Try asking',
              style: GoogleFonts.inter(
                color: AppColors.inkMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _starters.map((s) {
              return Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  onTap: () => _sendMessage(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      border: Border.all(
                          color: AppColors.crimson.withValues(alpha: 0.20)),
                    ),
                    child: Text(
                      s,
                      style: GoogleFonts.inter(
                        color: AppColors.ink,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.beige,
        border: Border(
          top: BorderSide(color: AppColors.beigeDeep, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(
                    color: AppColors.crimson.withValues(alpha: 0.18)),
              ),
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocus,
                style: GoogleFonts.inter(
                    color: AppColors.ink, fontSize: 14.5),
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Ask Faraz anything about your career...',
                  hintStyle: GoogleFonts.inter(
                      color: AppColors.inkMuted, fontSize: 13.5),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                enabled: !_isInitializing,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              onTap: _isInitializing || _isTyping
                  ? null
                  : () => _sendMessage(_inputController.text),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: (_isInitializing || _isTyping)
                      ? null
                      : AppColors.crimsonGradient,
                  color: (_isInitializing || _isTyping)
                      ? AppColors.beigeDeep
                      : null,
                  boxShadow: (_isInitializing || _isTyping)
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.crimson.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: Icon(
                  _isTyping ? Icons.hourglass_top_rounded : Icons.send_rounded,
                  color: (_isInitializing || _isTyping)
                      ? AppColors.inkMuted
                      : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
