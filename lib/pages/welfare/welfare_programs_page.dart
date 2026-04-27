import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class WelfareProgramsPage extends StatefulWidget {
  const WelfareProgramsPage({super.key});

  @override
  State<WelfareProgramsPage> createState() => _WelfareProgramsPageState();
}

class _WelfareProgramsPageState extends State<WelfareProgramsPage> {
  String _searchQuery = '';
  String _selectedCategory = 'All Programs';

  final List<Map<String, dynamic>> _allPrograms = [
    {
      'category': 'Education',
      'icon': Icons.school_outlined,
      'iconBgColor': const Color(0xFFEFF4FF),
      'iconColor': AppTheme.primary,
      'badgeLabel': 'Education',
      'badgeColor': const Color(0xFF29FCF3),
      'badgeTextColor': const Color(0xFF00504D),
      'title': 'Global Scholars Grant',
      'description': 'Providing full-tuition coverage and monthly stipends for undergraduate students in STEM fields from underserved communities.',
      'orgName': 'EduLift International',
      'statusLabel': 'Ends in',
      'statusValue': '12 Days',
      'statusValueColor': AppTheme.textPrimary,
    },
    {
      'category': 'Financial Aid',
      'icon': Icons.business_center_outlined,
      'iconBgColor': const Color(0xFFEFF4FF),
      'iconColor': AppTheme.primary,
      'badgeLabel': 'Financial Aid',
      'badgeColor': const Color(0xFFFFDBCB),
      'badgeTextColor': const Color(0xFF773207),
      'title': 'Micro-Biz Foundation',
      'description': 'Seed funding and zero-interest micro-loans for women-led startups in rural sectors to promote local economic growth.',
      'orgName': 'Prosperity Partners',
      'statusLabel': 'Amount',
      'statusValue': 'Up to \$5,000',
      'statusValueColor': AppTheme.textPrimary,
    },
    {
      'category': 'Health',
      'icon': Icons.health_and_safety_outlined,
      'iconBgColor': const Color(0xFFEFF4FF),
      'iconColor': AppTheme.primary,
      'badgeLabel': 'Health',
      'badgeColor': const Color(0xFFDCE9FF),
      'badgeTextColor': AppTheme.primary,
      'title': 'Urban Health Access',
      'description': 'Subsidized healthcare packages including chronic disease management and mental wellness sessions for low-income families.',
      'orgName': 'Community Care Trust',
      'statusLabel': 'Coverage',
      'statusValue': '80% Subsidy',
      'statusValueColor': AppTheme.textPrimary,
    },
    {
      'category': 'Housing',
      'icon': Icons.home_work_outlined,
      'iconBgColor': const Color(0xFFEFF4FF),
      'iconColor': AppTheme.primary,
      'badgeLabel': 'Housing',
      'badgeColor': const Color(0xFFFFDBCB),
      'badgeTextColor': const Color(0xFF773207),
      'title': 'First Home Assistance',
      'description': 'Down payment assistance and counseling for first-time homebuyers to bridge the affordability gap in urban centers.',
      'orgName': 'Habitat Collective',
      'statusLabel': 'Type',
      'statusValue': 'Grant Aid',
      'statusValueColor': AppTheme.textPrimary,
    },
    {
      'category': 'Sustainability',
      'icon': Icons.agriculture_outlined,
      'iconBgColor': const Color(0xFFEFF4FF),
      'iconColor': AppTheme.primary,
      'badgeLabel': 'Sustainability',
      'badgeColor': const Color(0xFFE8F5E9),
      'badgeTextColor': const Color(0xFF2E7D32),
      'title': 'Green Farm Initiative',
      'description': 'Tools, seeds, and training for sustainable urban farming to improve local food security and community health.',
      'orgName': 'EarthGuard NGO',
      'statusLabel': 'Status',
      'statusValue': 'Open Now',
      'statusValueColor': const Color(0xFF2E7D32),
    },
    {
      'category': 'Education',
      'icon': Icons.laptop_chromebook_outlined,
      'iconBgColor': const Color(0xFFEFF4FF),
      'iconColor': AppTheme.primary,
      'badgeLabel': 'Education',
      'badgeColor': const Color(0xFF29FCF3),
      'badgeTextColor': const Color(0xFF00504D),
      'title': 'Tech Skills Bootcamp',
      'description': 'Intensive 12-week coding and design bootcamps with guaranteed interview placement for career changers.',
      'orgName': 'Digital Future Org',
      'statusLabel': 'Availability',
      'statusValue': '48 Seats Left',
      'statusValueColor': AppTheme.textPrimary,
    },
  ];

  List<Map<String, dynamic>> get _filteredPrograms {
    return _allPrograms.where((program) {
      final matchesQuery = program['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          program['orgName'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All Programs' || program['category'] == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welfare Programs',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Discover and apply for financial aid, educational grants, and health support from verified NGOs.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _buildSearchBar(context),
            const SizedBox(height: 16),
            _buildCategoryChips(context),
            const SizedBox(height: 16),
            _buildFilters(context),
            const SizedBox(height: 24),
            _buildProgramList(context),
            const SizedBox(height: 32),
            _buildImpactBanner(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.background,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppTheme.primary),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu coming soon')));
        },
      ),
      title: Text(
        'FinEase',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppTheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        const Padding(
          padding: EdgeInsets.only(right: 20.0, left: 8.0),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primary,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Search for programs or organizations...',
        prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
        fillColor: AppTheme.surface,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(context, 'All Programs', isSelected: _selectedCategory == 'All Programs'),
          const SizedBox(width: 8),
          _buildChip(context, 'Education', isSelected: _selectedCategory == 'Education'),
          const SizedBox(width: 8),
          _buildChip(context, 'Health', isSelected: _selectedCategory == 'Health'),
          const SizedBox(width: 8),
          _buildChip(context, 'Housing', isSelected: _selectedCategory == 'Housing'),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, {required bool isSelected}) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Row(
      children: [
        _buildFilterDropdown(context, 'Location', Icons.location_on_outlined),
        const SizedBox(width: 8),
        _buildFilterDropdown(context, 'Support Type', Icons.filter_list),
      ],
    );
  }

  Widget _buildFilterDropdown(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.primary),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.primary),
        ],
      ),
    );
  }

  Widget _buildProgramList(BuildContext context) {
    final filtered = _filteredPrograms;
    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('No programs match your search.', style: Theme.of(context).textTheme.bodyLarge),
        ),
      );
    }
    
    return Column(
      children: filtered.map((program) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildProgramCard(
            context,
            icon: program['icon'] as IconData,
            iconBgColor: program['iconBgColor'] as Color,
            iconColor: program['iconColor'] as Color,
            badgeLabel: program['badgeLabel'] as String,
            badgeColor: program['badgeColor'] as Color,
            badgeTextColor: program['badgeTextColor'] as Color,
            title: program['title'] as String,
            description: program['description'] as String,
            orgName: program['orgName'] as String,
            statusLabel: program['statusLabel'] as String,
            statusValue: program['statusValue'] as String,
            statusValueColor: program['statusValueColor'] as Color,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgramCard(
    BuildContext context, {
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String badgeLabel,
    required Color badgeColor,
    required Color badgeTextColor,
    required String title,
    required String description,
    required String orgName,
    required String statusLabel,
    required String statusValue,
    required Color statusValueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: badgeTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.business, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(orgName, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusLabel, style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 2),
                  Text(
                    statusValue,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: statusValueColor,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Application started for \$title!')));
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  minimumSize: const Size(0, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Apply Now'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Making a\nmeasurable\nimpact together',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'FinEase has partnered with over 500+ NGOs to deliver critical support to those who need it most. Our verification process ensures your data and applications are always secure.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildImpactStat(context, '12K+', 'APPLICATIONS'),
              _buildImpactStat(context, '\$2M', 'FUNDED'),
              _buildImpactStat(context, '85%', 'SUCCESS RATE'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStat(BuildContext context, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
