import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/transaction.dart';
import '../../services/financial_coach_service.dart';

/// Screen for chatting with the AI Financial Coach
class CoachChatScreen extends StatefulWidget {
  final List<FinancialTransaction> transactions;
  final Map<String, double> budgets;
  final double monthlyIncome;

  const CoachChatScreen({
    super.key,
    required this.transactions,
    required this.budgets,
    required this.monthlyIncome,
  });

  @override
  State<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends State<CoachChatScreen> {
  static const _primary = Color(0xFF2E3192);
  late final FinancialCoachService _coachService;
  late final List<_ChatMessage> _messages;
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _coachService = FinancialCoachService();
    _messages = [
      _ChatMessage(
        text: 'Hello! I\'m your AI Financial Coach. How can I help you today?',
        isBot: true,
      ),
    ];
    _loadInitialAnalysis();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _loadInitialAnalysis() {
    final tips = _coachService.getInstantTips(
      transactions: widget.transactions,
      budgets: widget.budgets,
      monthlyIncome: widget.monthlyIncome,
    );

    if (tips.isNotEmpty) {
      final tipMessage = tips
          .take(2)
          .map((t) => '${t.icon} ${t.message}')
          .join('\n\n');
      setState(() {
        _messages.add(
          _ChatMessage(
            text: 'Here\'s what I found:\n\n$tipMessage',
            isBot: true,
          ),
        );
      });
    }
  }

  void _sendMessage() {
    if (_inputController.text.isEmpty) return;

    final userMessage = _inputController.text;
    _inputController.clear();

    setState(() {
      _messages.add(_ChatMessage(text: userMessage, isBot: false));
    });

    // Simulate bot response with a slight delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        String botResponse = _generateBotResponse(userMessage);
        setState(() {
          _messages.add(_ChatMessage(text: botResponse, isBot: true));
        });
        _scrollToBottom();
      }
    });
  }

  String _generateBotResponse(String userMessage) {
    final summary = _coachService.getBudgetSummary(
      transactions: widget.transactions,
      budgets: widget.budgets,
      monthlyIncome: widget.monthlyIncome,
    );

    final recommendations = _coachService.getRecommendations(
      transactions: widget.transactions,
      budgets: widget.budgets,
      monthlyIncome: widget.monthlyIncome,
    );

    final message = userMessage.toLowerCase();

    if (message.contains('budget') || message.contains('spent')) {
      return 'You\'ve spent ₹${summary['totalExpenses'].toStringAsFixed(0)} out of your budget of ₹${summary['totalBudget'].toStringAsFixed(0)}. That\'s ${(summary['percentageUsed'] as double).toStringAsFixed(1)}% of your budget used.';
    } else if (message.contains('save') || message.contains('savings')) {
      return 'Your current savings rate is ${(summary['savingsRate'] as double).toStringAsFixed(1)}% of your income. Keep working on increasing this!';
    } else if (message.contains('income') || message.contains('earn')) {
      return 'Your monthly income is ₹${summary['monthlyIncome'].toStringAsFixed(0)}. You\'re currently saving ₹${summary['netSavings'].toStringAsFixed(0)} per month.';
    } else if (message.contains('recommend') || message.contains('advice') || message.contains('help')) {
      if (recommendations.isEmpty) {
        return 'Your finances look great! Keep maintaining your current spending habits.';
      }
      return 'Here are my recommendations:\n\n• ${recommendations.join('\n• ')}';
    } else {
      return 'I\'m here to help with your financial management. You can ask me about your budget, spending, savings, or get personalized recommendations!';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
      appBar: AppBar(
        title: Text(
          'Financial Coach',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildChatBubble(message);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(_ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: message.isBot ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: message.isBot
                ? const Color(0xFFF0F0F0)
                : _primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.text,
            style: GoogleFonts.inter(
              color: message.isBot ? Colors.black87 : Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                hintStyle: GoogleFonts.inter(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: _primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: _primary,
                shape: BoxShape.circle,
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

class _ChatMessage {
  final String text;
  final bool isBot;

  _ChatMessage({
    required this.text,
    required this.isBot,
  });
}
