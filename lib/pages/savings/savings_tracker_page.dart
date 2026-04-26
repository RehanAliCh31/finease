import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../models/saving_goal.dart';

class SavingsTrackerPage extends StatelessWidget {
  const SavingsTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = authService.firestoreService;
    
    const Color primaryColor = Color(0xFF2E3192);
    const Color accentColor = Color(0xFF1BFFFF);
    const Color surfaceColor = Color(0xFFFBFBFE);

    return Scaffold(
      backgroundColor: surfaceColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(primaryColor),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (firestoreService != null)
                    StreamBuilder<List<SavingGoal>>(
                      stream: firestoreService.getSavingGoals(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(100.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ));
                        }
                        
                        final goals = snapshot.data ?? [];
                        
                        if (goals.isEmpty) {
                          return _buildEmptyState(context, firestoreService, primaryColor);
                        }

                        double totalTarget = goals.fold(0, (sum, g) => sum + g.targetAmount);
                        double totalSaved = goals.fold(0, (sum, g) => sum + g.currentAmount);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryCard(totalSaved, totalTarget, primaryColor, accentColor),
                            const SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Active Milestones', 
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A1A1A),
                                  )),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('${goals.length} active', 
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    )),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: goals.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 16),
                              itemBuilder: (context, index) => _buildGoalCard(context, goals[index], primaryColor),
                            ),
                          ],
                        );
                      },
                    )
                  else
                    _buildLoginRequired(context, primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: firestoreService != null ? Container(
        margin: const EdgeInsets.only(bottom: 90),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddGoalDialog(context, firestoreService, primaryColor),
          backgroundColor: primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text('New Goal', 
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            )),
        ),
      ) : null,
    );
  }

  Widget _buildSliverAppBar(Color primary) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 24, bottom: 20),
        title: Text('Savings', 
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 28,
            color: Colors.white,
          )),
        background: Stack(
          children: [
            Container(color: primary),
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded, color: Colors.white),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSummaryCard(double current, double target, Color primary, Color accent) {
    double progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL SAVINGS', 
                style: GoogleFonts.inter(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                )),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_graph_rounded, color: accent, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('\$${current.toStringAsFixed(0)}', 
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
            )),
          const SizedBox(height: 32),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                curve: Curves.fastOutSlowIn,
                height: 10,
                width: 300 * progress, // Simplified for placeholder
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accent, primary]),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.4),
                      blurRadius: 10,
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(progress * 100).toInt()}% completed', 
                style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                )),
              Text('Target \$${target.toStringAsFixed(0)}', 
                style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontSize: 13,
                )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, SavingGoal goal, Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F1F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(goal.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getCategoryIcon(goal.category),
                    color: _getCategoryColor(goal.category),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.title, 
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1A),
                        )),
                      const SizedBox(height: 4),
                      Text(goal.category, 
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[500],
                        )),
                    ],
                  ),
                ),
                _buildDaysLeftBadge(goal.targetDate),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SAVED', 
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey[400], letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text('\$${goal.currentAmount.toStringAsFixed(0)}', 
                      style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: primary)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('TARGET', 
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey[400], letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text('\$${goal.targetAmount.toStringAsFixed(0)}', 
                      style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A1A))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: goal.progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysLeftBadge(DateTime date) {
    final days = date.difference(DateTime.now()).inDays;
    final color = days < 30 ? Colors.orange : Colors.green;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$days days left', 
        style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState(BuildContext context, dynamic firestoreService, Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.savings_outlined, size: 80, color: primary.withOpacity(0.2)),
            ),
            const SizedBox(height: 32),
            Text('No goals set yet', 
              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text('Set your first saving goal and start\nyour journey to wealth.', 
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 16, height: 1.5)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _showAddGoalDialog(context, firestoreService, primary),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Create Goal', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginRequired(BuildContext context, Color primary) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.lock_outline_rounded, size: 64, color: primary.withOpacity(0.2)),
          const SizedBox(height: 24),
          Text('Login Required', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'travel': return Icons.flight_rounded;
      case 'home': return Icons.home_rounded;
      case 'car': return Icons.directions_car_rounded;
      case 'emergency': return Icons.emergency_rounded;
      case 'education': return Icons.school_rounded;
      case 'gadget': return Icons.devices_rounded;
      case 'shopping': return Icons.shopping_bag_rounded;
      default: return Icons.savings_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'travel': return Colors.blue;
      case 'home': return Colors.orange;
      case 'car': return Colors.purple;
      case 'emergency': return Colors.red;
      case 'education': return Colors.indigo;
      case 'gadget': return Colors.teal;
      case 'shopping': return Colors.pink;
      default: return const Color(0xFF2E3192);
    }
  }

  void _showAddGoalDialog(BuildContext context, dynamic firestoreService, Color primary) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    String selectedCategory = 'General';
    final categories = ['General', 'Travel', 'Home', 'Car', 'Emergency', 'Education', 'Gadget', 'Shopping'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              left: 28,
              right: 28,
              top: 32,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Set New Goal', 
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                  )),
                const SizedBox(height: 8),
                Text('What are you saving for today?', 
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 32),
                _buildTextField(titleController, 'Goal Title', Icons.edit_rounded, primary),
                const SizedBox(height: 20),
                _buildTextField(targetController, 'Target Amount', Icons.attach_money_rounded, primary, isNumber: true),
                const SizedBox(height: 24),
                Text('Category', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: categories.map((cat) {
                      bool isSelected = selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () => setState(() => selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? primary : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? primary : const Color(0xFFF1F1F1)),
                            ),
                            alignment: Alignment.center,
                            child: Text(cat, 
                              style: GoogleFonts.inter(
                                color: isSelected ? Colors.white : Colors.grey[700],
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              )),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      if (firestoreService != null && titleController.text.isNotEmpty) {
                        await firestoreService.addSavingGoal(SavingGoal(
                          id: '',
                          title: titleController.text,
                          targetAmount: double.tryParse(targetController.text) ?? 0,
                          currentAmount: 0,
                          targetDate: DateTime.now().add(const Duration(days: 365)),
                          category: selectedCategory,
                        ));
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text('Launch Goal', 
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, Color primary, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 16),
          prefixIcon: Icon(icon, color: primary, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
      ),
    );
  }
}
