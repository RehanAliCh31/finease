import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../models/budget_plan.dart';
import '../models/saving_goal.dart';
import '../models/transaction.dart';

class LessonCourse {
  const LessonCourse({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.coverImageUrl,
    required this.category,
    required this.durationMinutes,
    required this.rating,
    required this.xpReward,
    required this.lessons,
    required this.quiz,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String coverImageUrl;
  final String category;
  final int durationMinutes;
  final double rating;
  final int xpReward;
  final List<Lesson> lessons;
  final CourseQuiz quiz;
}

class CourseQuiz {
  const CourseQuiz({
    required this.id,
    required this.title,
    required this.questions,
  });

  final String id;
  final String title;
  final List<QuizQuestion> questions;
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

class DemoFinanceData {
  static const List<Map<String, dynamic>> marketplacePartners = [
    {
      'id': 'jubilee-insurance',
      'name': 'Jubilee Health Secure',
      'description':
          'Affordable health protection plans for families, freelancers, and salaried professionals across Pakistan.',
      'category': 'Insurance',
      'badge': 'Verified',
      'ctaLabel': 'Explore Cover',
      'colorHex': 0xFF2E3192,
      'iconName': 'shield',
      'priority': 1,
    },
    {
      'id': 'hbl-microfinance',
      'name': 'HBL Microfinance Support',
      'description':
          'Microfinance options for women-led households, shopkeepers, and first-time business borrowers.',
      'category': 'Loans',
      'badge': 'Popular',
      'ctaLabel': 'Check Options',
      'colorHex': 0xFF0EA5A4,
      'iconName': 'bank',
      'priority': 2,
    },
    {
      'id': 'rozee-careers',
      'name': 'Career Growth Network',
      'description':
          'Find verified roles, freelance gigs, and upskilling opportunities that improve monthly cash flow.',
      'category': 'Jobs',
      'badge': 'New',
      'ctaLabel': 'View Roles',
      'colorHex': 0xFF059669,
      'iconName': 'briefcase',
      'priority': 3,
    },
    {
      'id': 'solar-installments',
      'name': 'Solar Installment Partners',
      'description':
          'Compare installment-based solar solutions to lower electricity costs and protect your household budget.',
      'category': 'Utilities',
      'badge': 'Save More',
      'ctaLabel': 'Compare Plans',
      'colorHex': 0xFFD97706,
      'iconName': 'sun',
      'priority': 4,
    },
    {
      'id': 'education-aid',
      'name': 'Education & Scholarship Desk',
      'description':
          'Student financing, scholarships, and training programs designed for Pakistani learners and early professionals.',
      'category': 'Education',
      'badge': 'Featured',
      'ctaLabel': 'See Programs',
      'colorHex': 0xFF7C3AED,
      'iconName': 'school',
      'priority': 5,
    },
  ];

  static List<FinancialTransaction> sampleTransactions() {
    final now = DateTime.now();
    return [
      FinancialTransaction(
        id: 'seed-tx-1',
        title: 'Salary Deposit',
        amount: 325000,
        date: DateTime(now.year, now.month, 1),
        category: 'Income',
        type: 'income',
      ),
      FinancialTransaction(
        id: 'seed-tx-2',
        title: 'Apartment Rent',
        amount: 85000,
        date: DateTime(now.year, now.month, 2),
        category: 'Housing',
        type: 'expense',
      ),
      FinancialTransaction(
        id: 'seed-tx-3',
        title: 'Groceries',
        amount: 18500,
        date: now.subtract(const Duration(days: 2)),
        category: 'Food',
        type: 'expense',
      ),
      FinancialTransaction(
        id: 'seed-tx-4',
        title: 'Coffee and Breakfast',
        amount: 1200,
        date: now.subtract(const Duration(days: 1)),
        category: 'Food',
        type: 'expense',
      ),
      FinancialTransaction(
        id: 'seed-tx-5',
        title: 'Gym Membership',
        amount: 6500,
        date: DateTime(now.year, now.month, 4),
        category: 'Health',
        type: 'expense',
      ),
      FinancialTransaction(
        id: 'seed-tx-6',
        title: 'Streaming Bundle',
        amount: 2100,
        date: DateTime(now.year, now.month, 5),
        category: 'Subscriptions',
        type: 'expense',
      ),
      FinancialTransaction(
        id: 'seed-tx-7',
        title: 'Ride Share',
        amount: 4800,
        date: now.subtract(const Duration(days: 3)),
        category: 'Transport',
        type: 'expense',
      ),
      FinancialTransaction(
        id: 'seed-tx-8',
        title: 'Weekend Dining',
        amount: 9600,
        date: now.subtract(const Duration(days: 4)),
        category: 'Dining',
        type: 'expense',
      ),
      FinancialTransaction(
        id: 'seed-tx-9',
        title: 'Freelance Design',
        amount: 72000,
        date: now.subtract(const Duration(days: 6)),
        category: 'Income',
        type: 'income',
      ),
      FinancialTransaction(
        id: 'seed-tx-10',
        title: 'New Headphones',
        amount: 28500,
        date: now.subtract(const Duration(days: 7)),
        category: 'Shopping',
        type: 'expense',
      ),
      FinancialTransaction(
        id: 'seed-tx-11',
        title: 'Electric Bill',
        amount: 14200,
        date: now.subtract(const Duration(days: 8)),
        category: 'Utilities',
        type: 'expense',
      ),
      FinancialTransaction(
        id: 'seed-tx-12',
        title: 'Emergency Fund Transfer',
        amount: 25000,
        date: now.subtract(const Duration(days: 9)),
        category: 'Savings',
        type: 'expense',
      ),
    ];
  }

  static List<SavingGoal> sampleGoals() {
    final now = DateTime.now();
    return [
      SavingGoal(
        id: 'seed-goal-1',
        title: 'Emergency Fund',
        targetAmount: 500000,
        currentAmount: 235000,
        targetDate: DateTime(now.year, now.month + 8, 1),
        category: 'Emergency',
        emoji: 'Shield',
      ),
      SavingGoal(
        id: 'seed-goal-2',
        title: 'Japan Trip',
        targetAmount: 420000,
        currentAmount: 165000,
        targetDate: DateTime(now.year + 1, 4, 15),
        category: 'Travel',
        emoji: 'Plane',
      ),
      SavingGoal(
        id: 'seed-goal-3',
        title: 'Investing Starter Fund',
        targetAmount: 300000,
        currentAmount: 118000,
        targetDate: DateTime(now.year, now.month + 5, 10),
        category: 'General',
        emoji: 'Chart',
      ),
    ];
  }

  static const Map<String, dynamic> sampleProfile = {
    'fullName': 'Alex Morgan',
    'membershipTier': 'Elite Member',
    'monthlyIncome': 397000.0,
    'targetSavingsRate': 0.22,
  };

  static List<BudgetPlan> sampleBudgetPlans() {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return [
      BudgetPlan(
        id: 'seed-budget-1',
        title: 'Home Essentials',
        category: 'Housing',
        allocatedAmount: 95000,
        notes: 'Rent, maintenance, utilities, and internet.',
        monthKey: monthKey,
        createdAt: now,
      ),
      BudgetPlan(
        id: 'seed-budget-2',
        title: 'Food and Groceries',
        category: 'Food',
        allocatedAmount: 45000,
        notes: 'Groceries plus weekly dining cap.',
        monthKey: monthKey,
        createdAt: now,
      ),
      BudgetPlan(
        id: 'seed-budget-3',
        title: 'Mobility',
        category: 'Transport',
        allocatedAmount: 18000,
        notes: 'Fuel, ride hailing, and bus fares.',
        monthKey: monthKey,
        createdAt: now,
      ),
      BudgetPlan(
        id: 'seed-budget-4',
        title: 'Family Savings',
        category: 'Savings',
        allocatedAmount: 60000,
        notes: 'Emergency fund and travel contributions.',
        monthKey: monthKey,
        createdAt: now,
      ),
    ];
  }

  static List<LessonCourse> courses = const [
    LessonCourse(
      id: 'budget-foundations',
      title: 'Budget Foundations',
      subtitle: 'Build a monthly plan that survives real life',
      description:
          'Learn how to structure fixed costs, flexible spending, and savings so every paycheck has a job.',
      coverImageUrl:
          'https://images.unsplash.com/photo-1554224155-6726b3ff858f?auto=format&fit=crop&w=1200&q=80',
      category: 'Budgeting',
      durationMinutes: 38,
      rating: 4.8,
      xpReward: 220,
      lessons: [
        Lesson(
          id: 'bf-1',
          title: 'Give Every Dollar a Job',
          description: 'Set up core budget buckets',
          content:
              'Start with after-tax income. Cover essentials first, cap lifestyle categories, and reserve savings before discretionary spending.',
          icon: 'pie_chart',
          points: 40,
        ),
        Lesson(
          id: 'bf-2',
          title: 'The 50/30/20 Rule',
          description: 'Use a ratio as a starting point',
          content:
              'Treat 50/30/20 as a calibration tool, not a law. High-rent cities may need a temporary 60/20/20 structure until income rises.',
          icon: 'balance',
          points: 40,
        ),
        Lesson(
          id: 'bf-3',
          title: 'Sinking Funds',
          description: 'Plan for irregular expenses',
          content:
              'Break annual costs like insurance, gifts, and repairs into monthly transfers so they stop feeling like emergencies.',
          icon: 'wallet',
          points: 60,
        ),
      ],
      quiz: CourseQuiz(
        id: 'bf-quiz',
        title: 'Budget Foundations Quiz',
        questions: [
          QuizQuestion(
            id: 'bf-q1',
            prompt: 'What is the main purpose of a sinking fund?',
            options: [
              'Pay off credit cards faster',
              'Set aside money for irregular planned costs',
              'Track investment returns',
              'Reduce taxes immediately',
            ],
            correctIndex: 1,
            explanation:
                'Sinking funds smooth predictable but non-monthly expenses like car repairs or insurance renewals.',
          ),
          QuizQuestion(
            id: 'bf-q2',
            prompt: 'Which statement about 50/30/20 is strongest?',
            options: [
              'It fits every household permanently',
              'It only works for high earners',
              'It is a flexible benchmark to adjust',
              'It excludes savings goals',
            ],
            correctIndex: 2,
            explanation:
                'The ratio is useful as a baseline, but it should adapt to cost of living and goals.',
          ),
        ],
      ),
    ),
    LessonCourse(
      id: 'smart-investing',
      title: 'Smart Investing',
      subtitle: 'Understand risk, diversification, and long-term growth',
      description:
          'Move from saving cash to building an investing framework with index funds, time horizon, and risk control.',
      coverImageUrl:
          'https://images.unsplash.com/photo-1640161704729-cbe966a08476?auto=format&fit=crop&w=1200&q=80',
      category: 'Investing',
      durationMinutes: 45,
      rating: 4.9,
      xpReward: 260,
      lessons: [
        Lesson(
          id: 'si-1',
          title: 'Risk and Return',
          description: 'Why higher upside usually means higher volatility',
          content:
              'Investment risk is the price paid for expected growth. Match your portfolio to your timeline so downturns do not force bad decisions.',
          icon: 'trending_up',
          points: 50,
        ),
        Lesson(
          id: 'si-2',
          title: 'Index Funds Explained',
          description: 'A beginner-friendly core holding',
          content:
              'Index funds spread your money across many companies, lowering single-stock risk and keeping fees relatively low.',
          icon: 'stacked_line_chart',
          points: 50,
        ),
        Lesson(
          id: 'si-3',
          title: 'Asset Allocation',
          description: 'Balance growth and stability',
          content:
              'Stocks drive growth, bonds reduce volatility, and cash supports near-term needs. The right mix depends on your horizon and tolerance.',
          icon: 'donut_large',
          points: 70,
        ),
      ],
      quiz: CourseQuiz(
        id: 'si-quiz',
        title: 'Smart Investing Quiz',
        questions: [
          QuizQuestion(
            id: 'si-q1',
            prompt: 'Why do many beginners start with index funds?',
            options: [
              'They guarantee profits',
              'They remove all volatility',
              'They provide broad diversification',
              'They eliminate taxes',
            ],
            correctIndex: 2,
            explanation:
                'Index funds help diversify across many holdings rather than relying on one company.',
          ),
          QuizQuestion(
            id: 'si-q2',
            prompt: 'What should influence your stock/bond mix most?',
            options: [
              'Your friend’s portfolio',
              'Your time horizon and risk tolerance',
              'The latest social media trend',
              'Only this month’s market move',
            ],
            correctIndex: 1,
            explanation:
                'Time horizon and ability to handle volatility are the primary asset-allocation inputs.',
          ),
        ],
      ),
    ),
    LessonCourse(
      id: 'credit-and-debt',
      title: 'Credit and Debt',
      subtitle: 'Borrow strategically and protect your score',
      description:
          'Understand how utilization, payment history, and debt payoff methods affect your financial flexibility.',
      coverImageUrl:
          'https://images.unsplash.com/photo-1556740749-887f6717d7e4?auto=format&fit=crop&w=1200&q=80',
      category: 'Credit',
      durationMinutes: 32,
      rating: 4.7,
      xpReward: 180,
      lessons: [
        Lesson(
          id: 'cd-1',
          title: 'How Credit Scores Work',
          description: 'The major factors behind your score',
          content:
              'Payment history and utilization usually matter most. Missing payments damages trust faster than opening one new account.',
          icon: 'credit_score',
          points: 40,
        ),
        Lesson(
          id: 'cd-2',
          title: 'Avalanche vs Snowball',
          description: 'Choose a debt payoff method',
          content:
              'Avalanche minimizes interest paid, while snowball prioritizes psychological wins by clearing the smallest balances first.',
          icon: 'compare_arrows',
          points: 40,
        ),
        Lesson(
          id: 'cd-3',
          title: 'Use Debt Without Letting It Use You',
          description: 'Rules for responsible borrowing',
          content:
              'Only carry debt with a clear purpose, a payoff path, and a monthly payment that does not choke your cash flow.',
          icon: 'shield',
          points: 50,
        ),
      ],
      quiz: CourseQuiz(
        id: 'cd-quiz',
        title: 'Credit and Debt Quiz',
        questions: [
          QuizQuestion(
            id: 'cd-q1',
            prompt:
                'Which payoff method usually reduces total interest the most?',
            options: [
              'Debt avalanche',
              'Debt snowball',
              'Minimum payments only',
              'Balance transfers without a plan',
            ],
            correctIndex: 0,
            explanation:
                'Avalanche targets the highest-interest debt first, which lowers total interest over time.',
          ),
          QuizQuestion(
            id: 'cd-q2',
            prompt: 'What is credit utilization?',
            options: [
              'Your salary spent on rent',
              'Your used revolving credit versus total limit',
              'Your savings rate',
              'Your interest earned',
            ],
            correctIndex: 1,
            explanation:
                'Utilization measures how much of your revolving credit line you are using.',
          ),
        ],
      ),
    ),
    LessonCourse(
      id: 'pakistan-finance-playbook',
      title: 'Pakistan Finance Playbook',
      subtitle: 'Budget, save, and borrow using real local realities',
      description:
          'Learn how to manage salary cycles, inflation pressure, committee savings, and responsible borrowing in Pakistan.',
      coverImageUrl:
          'https://images.unsplash.com/photo-1520607162513-77705c0f0d4a?auto=format&fit=crop&w=1200&q=80',
      category: 'Local Finance',
      durationMinutes: 34,
      rating: 4.9,
      xpReward: 210,
      lessons: [
        Lesson(
          id: 'pf-1',
          title: 'Budgeting for Inflation',
          description: 'Protect essentials when prices move fast',
          content:
              'Separate fixed bills from volatile items like groceries and fuel, then review those flexible categories weekly instead of monthly.',
          icon: 'pie_chart',
          points: 45,
        ),
        Lesson(
          id: 'pf-2',
          title: 'Emergency Funds in PKR',
          description: 'Build a cushion before chasing returns',
          content:
              'Aim for three to six months of core expenses in accessible savings so medical, job, or repair shocks do not force debt.',
          icon: 'shield',
          points: 55,
        ),
        Lesson(
          id: 'pf-3',
          title: 'Borrowing Carefully',
          description: 'Compare markup, tenure, and real repayment pressure',
          content:
              'Do not judge a loan by monthly installment alone. Check total repayment, income ratio, and whether the purpose improves your finances.',
          icon: 'credit_score',
          points: 60,
        ),
      ],
      quiz: CourseQuiz(
        id: 'pf-quiz',
        title: 'Pakistan Finance Playbook Quiz',
        questions: [
          QuizQuestion(
            id: 'pf-q1',
            prompt:
                'Which category should be reviewed most often during inflation?',
            options: [
              'Volatile essentials like groceries and fuel',
              'Only annual subscriptions',
              'Only charitable giving',
              'None, budgets should stay fixed all year',
            ],
            correctIndex: 0,
            explanation:
                'Fast-moving essential categories drift first, so they need more frequent review.',
          ),
          QuizQuestion(
            id: 'pf-q2',
            prompt: 'What should you compare before taking a loan?',
            options: [
              'Only the monthly installment',
              'Total repayment, markup, and income impact',
              'Only the loan advertisement',
              'Only the branch location',
            ],
            correctIndex: 1,
            explanation:
                'A strong loan decision checks the total cost and affordability, not just the headline installment.',
          ),
        ],
      ),
    ),
  ];

  static IconData courseIcon(String iconName) {
    switch (iconName) {
      case 'pie_chart':
        return Icons.pie_chart_rounded;
      case 'balance':
        return Icons.balance_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'stacked_line_chart':
        return Icons.stacked_line_chart_rounded;
      case 'donut_large':
        return Icons.donut_large_rounded;
      case 'credit_score':
        return Icons.credit_score_rounded;
      case 'compare_arrows':
        return Icons.compare_arrows_rounded;
      case 'shield':
        return Icons.shield_rounded;
      default:
        return Icons.school_rounded;
    }
  }
}
