import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../theme/app_theme.dart';

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;
}

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late final GenerativeModel _model;
  late final ChatSession _session;

  final _prompts = const [
    'How can I pay off debt faster?',
    'Explain index funds simply.',
    'Should I get a loan right now?',
    'How do I build an emergency fund?',
  ];

  @override
  void initState() {
    super.initState();
    final envKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: envKey,
      systemInstruction: Content.system(
        'You are FinEase AI, a friendly financial coach for users in Pakistan. '
        'Prefer PKR examples instead of USD. Give practical budgeting, loans, savings, and investment basics. '
        'Use concise answers and bullets where useful. Never recommend specific stocks.',
      ),
    );
    _session = _model.startChat();
    _messages.add(
      ChatMessage(
        text:
            "Hi! I'm FinEase AI. I can help with budgeting, loans, savings goals, and financial planning in PKR.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) {
      return;
    }
    _controller.clear();
    setState(() {
      _messages.add(
        ChatMessage(text: text.trim(), isUser: true, timestamp: DateTime.now()),
      );
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await _session.sendMessage(Content.text(text.trim()));
      if (!mounted) {
        return;
      }
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: response.text ?? 'I could not generate a response.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text:
                'I could not connect right now. Please check your internet and try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FinEase AI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  _isTyping ? 'Typing...' : 'Online',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _isTyping ? AppTheme.warning : AppTheme.success,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: () => setState(() {
              _messages
                ..clear()
                ..add(
                  ChatMessage(
                    text: 'Chat cleared. What would you like help with next?',
                    isUser: false,
                    timestamp: DateTime.now(),
                  ),
                );
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const _TypingIndicator();
                }
                return _Bubble(message: _messages[index]);
              },
            ),
          ),
          if (_messages.length == 1)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _prompts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => _send(_prompts[index]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _prompts[index],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          _InputBar(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(18),
            bottomLeft: isUser
                ? const Radius.circular(18)
                : const Radius.circular(4),
          ),
          boxShadow: AppTheme.softShadow,
          border: isUser ? null : Border.all(color: AppTheme.border),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isUser ? Colors.white : AppTheme.textPrimary,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Thinking...',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: onSend,
              decoration: InputDecoration(
                hintText: 'Ask about finances...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                fillColor: AppTheme.background,
                filled: true,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => onSend(controller.text),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
