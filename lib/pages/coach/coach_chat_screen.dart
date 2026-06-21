import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/budget_plan.dart';
import '../../models/parsed_expense.dart';
import '../../models/saving_goal.dart';
import '../../models/transaction.dart';
import '../../services/ai_service.dart';
import '../../services/anomaly_alert_service.dart';
import '../../services/auth_service.dart';
import '../../services/financial_coach_service.dart';
import '../../services/firestore_service.dart';
import '../../services/voice_input_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/anomaly_alert_card.dart';

class CoachChatScreen extends StatefulWidget {
  const CoachChatScreen({
    super.key,
    required this.transactions,
    required this.budgets,
    required this.monthlyIncome,
  });

  final List<FinancialTransaction> transactions;
  final Map<String, double> budgets;
  final double monthlyIncome;

  @override
  State<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends State<CoachChatScreen> {
  static const _primary = Color(0xFF2E3192);
  final _coachService = FinancialCoachService();
  final _aiService = AIService();
  final _voiceService = VoiceInputService();
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          'Hello! I am your AI Finance Coach. I use your real budgets, transactions, and savings context for personalized guidance. You can also say "I spent..." to log expenses or use voice!',
      isBot: true,
    ),
  ];
  bool _isLoading = false;
  bool _isListening = false;
  bool _listeningDialogOpen = false;
  bool _voiceStopRequested = false;
  List<AnomalyAlert> _anomalies = [];
  bool _showingAnomalies = false;
  late final List<FinancialTransaction> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = List<FinancialTransaction>.from(widget.transactions);
    _initializeVoice();
    _checkAnomalies();

    final tips = _coachService.getInstantTips(
      transactions: _transactions,
      budgets: widget.budgets,
      monthlyIncome: widget.monthlyIncome,
    );
    if (tips.isNotEmpty) {
      _messages.add(
        _ChatMessage(
          text: tips
              .take(2)
              .map((tip) => '${tip.icon} ${tip.message}')
              .join('\n\n'),
          isBot: true,
        ),
      );
    }
  }

  Future<void> _initializeVoice() async {
    try {
      await _voiceService.initialize();
    } catch (e) {
      debugPrint('Voice initialization error: $e');
    }
  }

  Future<void> _checkAnomalies() async {
    try {
      final anomalies = await _aiService.detectUnusualSpending(_transactions);
      if (mounted && anomalies.isNotEmpty) {
        setState(() {
          _anomalies = AnomalyAlertService.processAnomalies(anomalies);
          _showingAnomalies = true;
        });
      }
    } catch (e) {
      // Fallback to local detection if AI fails
      final localAnomalies = AnomalyAlertService.detectAnomaliesLocally(
        _transactions,
      );
      if (mounted && localAnomalies.isNotEmpty) {
        setState(() {
          _anomalies = localAnomalies;
          _showingAnomalies = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _startVoiceInput() async {
    try {
      setState(() => _isListening = true);
      await _voiceService.startListening();

      // Show listening UI feedback
      if (mounted) {
        _showListeningDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Microphone error: $e')));
      }
    }
  }

  void _showListeningDialog() {
    _listeningDialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primary.withAlpha(51),
              ),
              child: Center(
                child: Icon(Icons.mic_rounded, size: 30, color: _primary),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Listening...',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Say "I spent 500 on lunch"',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _stopVoiceInput();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    ).whenComplete(() {
      final shouldCancel = _listeningDialogOpen && !_voiceStopRequested;
      _listeningDialogOpen = false;
      if (shouldCancel && mounted) {
        _voiceService.cancelListening();
        setState(() => _isListening = false);
      }
    });
  }

  Future<void> _stopVoiceInput() async {
    _voiceStopRequested = true;
    try {
      final text = await _voiceService.stopListening();
      if (mounted) {
        _closeListeningDialog();
        setState(() => _isListening = false);

        if (text.isNotEmpty) {
          _inputController.text = text;
          await _sendMessage();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No speech captured. Try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _closeListeningDialog();
        setState(() => _isListening = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      _voiceStopRequested = false;
    }
  }

  void _closeListeningDialog() {
    if (!_listeningDialogOpen) return;
    _listeningDialogOpen = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _toggleAnomaliesView() {
    setState(() {
      _showingAnomalies = !_showingAnomalies;
    });
  }

  Future<void> _sendMessage() async {
    final userMessage = _inputController.text.trim();
    if (userMessage.isEmpty || _isLoading) return;

    _inputController.clear();
    setState(() {
      _isLoading = true;
      _messages.add(_ChatMessage(text: userMessage, isBot: false));
    });
    _scrollToBottom();

    try {
      // Try to parse as an expense first
      final parsedExpense = await _aiService.parseExpenseFromNaturalLanguage(
        userMessage,
        availableCategories: _availableExpenseCategories(),
      );

      if (parsedExpense.isValid) {
        // This looks like an expense - show confirmation and option to log it
        await _showExpenseConfirmation(parsedExpense);
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // Not an expense, proceed with normal Q&A
      final budgets = widget.budgets.entries
          .map(
            (entry) => BudgetPlan(
              id: '',
              title: entry.key,
              category: entry.key,
              allocatedAmount: entry.value,
              notes: '',
              monthKey: '',
              createdAt: DateTime.now(),
            ),
          )
          .toList();
      final response = await _aiService.personalizedCoachAnswer(
        question: userMessage,
        transactions: _transactions,
        budgets: budgets,
        goals: const <SavingGoal>[],
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(_ChatMessage(text: response, isBot: true));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(
          _ChatMessage(
            text: 'AI Finance Coach is not running yet: $error',
            isBot: true,
          ),
        );
      });
    }
    _scrollToBottom();
  }

  Future<void> _showExpenseConfirmation(ParsedExpense expense) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Expense?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'I detected an expense. Ready to log it?',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              'Amount',
              'PKR ${expense.amount?.toStringAsFixed(0) ?? '?'}',
            ),
            _DetailRow('Category', expense.category ?? 'Unknown'),
            _DetailRow('Description', expense.description ?? 'No description'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _CoachChatScreenState._primary,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Expense'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _logExpense(expense);
    }
  }

  Future<void> _logExpense(ParsedExpense expense) async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _messages.add(
          _ChatMessage(text: 'Logging your expense...', isBot: true),
        );
      });
      _scrollToBottom();

      final authService = context.read<AuthService>();
      final firestoreService = FirestoreService(uid: authService.user!.uid);
      final amount = expense.amount ?? 0;
      if (amount <= 0) {
        throw Exception('Expense amount must be greater than zero.');
      }
      final category = expense.category ?? 'Others';

      final transaction = FinancialTransaction(
        id: '',
        title: expense.description ?? 'Expense',
        amount: amount,
        date: DateTime.now(),
        category: category,
        type: 'expense',
        note: 'Logged via AI chatbot: ${expense.rawInput}',
      );

      await firestoreService.addTransaction(transaction);

      if (mounted) {
        setState(() {
          _messages.removeLast(); // Remove "Logging..." message
          _transactions.insert(0, transaction);
          _isLoading = false;
          _messages.add(
            _ChatMessage(
              text:
                  'Expense logged: PKR ${amount.toStringAsFixed(0)} spent on $category. Your budget has been updated.',
              isBot: true,
            ),
          );
        });
        await _checkAnomalies();
        _scrollToBottom();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _messages.removeLast(); // Remove "Logging..." message
          _isLoading = false;
          _messages.add(
            _ChatMessage(text: 'Failed to log expense: $error', isBot: true),
          );
        });
      }
    }
  }

  List<String> _availableExpenseCategories() {
    return <String>{
      'Groceries',
      'Transport',
      'Education',
      'Electricity',
      'Healthcare',
      'Entertainment',
      'Savings',
      'Others',
      ...widget.budgets.keys.where((category) => category.trim().isNotEmpty),
      ..._transactions
          .where((transaction) => transaction.type == 'expense')
          .map((transaction) => transaction.category)
          .where((category) => category.trim().isNotEmpty),
    }.toList();
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
      backgroundColor: AppTheme.backgroundFor(context),
      appBar: AppBar(
        title: Text(
          'AI Finance Coach',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: _anomalies.isNotEmpty
            ? [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_anomalies.length}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onPressed: _toggleAnomaliesView,
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          if (_showingAnomalies && _anomalies.isNotEmpty)
            Container(
              color: Colors.orange.shade50,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Spending Alerts (${_anomalies.length})',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 18),
                          onPressed: _toggleAnomaliesView,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: (_anomalies.length * 210.0)
                        .clamp(190.0, MediaQuery.sizeOf(context).height * 0.36)
                        .toDouble(),
                    child: AnomalyAlertsList(
                      alerts: _anomalies,
                      scrollable: true,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const _TypingBubble();
                }
                return _ChatBubble(message: _messages[index]);
              },
            ),
          ),
          _InputArea(
            controller: _inputController,
            onSend: _sendMessage,
            onVoicePress: _startVoiceInput,
            isListening: _isListening,
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isBot
              ? AppTheme.surfaceFor(context)
              : _CoachChatScreenState._primary,
          border: message.isBot
              ? Border.all(color: AppTheme.borderFor(context))
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.inter(
            color: message.isBot
                ? AppTheme.textPrimaryFor(context)
                : Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  const _InputArea({
    required this.controller,
    required this.onSend,
    required this.onVoicePress,
    required this.isListening,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onVoicePress;
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        border: Border(top: BorderSide(color: AppTheme.borderFor(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Ask, or say: I spent 500 on lunch',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: isListening ? null : onVoicePress,
            icon: Icon(
              isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isListening
                  ? Colors.red.shade600
                  : Color(0xFF2E3192),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded),
            style: IconButton.styleFrom(backgroundColor: Color(0xFF2E3192)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isBot});

  final String text;
  final bool isBot;
}
