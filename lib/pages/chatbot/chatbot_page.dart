import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../theme/app_theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});
  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late final GenerativeModel _model;
  late final ChatSession _session;

  final _prompts = [
    'How can I pay off debt faster? 💳',
    'Explain index funds simply 📈',
    'Should I get a loan right now? 🏦',
    'How to build an emergency fund? 💰',
  ];

  static const String _fallbackKey = 'AIzaSyB97wIZHlQXBrbl5tEPCXJGjNmeIq14xtU';

  @override
  void initState() {
    super.initState();
    final envKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final key = envKey.isNotEmpty ? envKey : _fallbackKey;
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: key,
      systemInstruction: Content.system(
        'You are FinEase AI, a professional and friendly financial advisor. '
        'You specialize in personal finance, budgeting, savings, loans, and investments. '
        'Give concise, practical advice tailored to users in Pakistan and globally. '
        'Use bullet points for lists. Keep responses under 200 words unless detail is needed. '
        'Always encourage smart financial decisions. Never recommend specific stocks.',
      ),
    );
    _session = _model.startChat();
    _messages.add(ChatMessage(
      text: "Hi! I'm **FinEase AI** — your personal financial advisor 🎯\n\nI can help with budgeting, loans, savings goals, and investment basics. What's on your mind?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isTyping = true;
    });
    _scrollToBottom();
    try {
      final resp = await _session.sendMessage(Content.text(text));
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(text: resp.text ?? 'Sorry, I could not respond.', isUser: false, timestamp: DateTime.now()));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        final errMsg = e.toString().contains('API_KEY') || e.toString().contains('403')
            ? 'API key error. Please contact support.'
            : 'Sorry, I could not connect. Please check your internet and try again. (${e.runtimeType})';
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(text: errMsg, isUser: false, timestamp: DateTime.now()));
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FinEase AI', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                Text(_isTyping ? 'Typing...' : '● Online', style: GoogleFonts.inter(fontSize: 11, color: _isTyping ? AppTheme.warning : AppTheme.success)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: () => setState(() {
              _messages.clear();
              _messages.add(ChatMessage(text: "Chat cleared. How can I help you?", isUser: false, timestamp: DateTime.now()));
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length) return _TypingIndicator();
                return _Bubble(msg: _messages[i]);
              },
            ),
          ),
          // Quick prompts (only before first user message)
          if (_messages.length == 1)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _prompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _send(_prompts[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(_prompts[i], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.primary)),
                  ),
                ),
              ),
            ),
          _InputBar(ctrl: _ctrl, onSend: _send),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
          ),
          boxShadow: AppTheme.softShadow,
          border: isUser ? null : Border.all(color: AppTheme.border),
        ),
        child: Text(
          msg.text,
          style: GoogleFonts.inter(fontSize: 14, color: isUser ? Colors.white : AppTheme.textPrimary, height: 1.5),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
          const SizedBox(width: 10),
          Text('Thinking...', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
        ]),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onSend;
  const _InputBar({required this.ctrl, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(color: AppTheme.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))]),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: onSend,
            decoration: InputDecoration(
              hintText: 'Ask about finances...',
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              fillColor: AppTheme.background,
              filled: true,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => onSend(ctrl.text),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.cardShadow),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}
