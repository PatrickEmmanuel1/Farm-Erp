import 'package:flutter/material.dart';

class _RecommendationTip {
  const _RecommendationTip({
    required this.title,
    required this.category,
    required this.summary,
    required this.recommendedFor,
    required this.icon,
    required this.backgroundColor,
  });

  final String title;
  final String category;
  final String summary;
  final String recommendedFor;
  final IconData icon;
  final Color backgroundColor;
}

class ManagerRecommendationsScreen extends StatefulWidget {
  const ManagerRecommendationsScreen({
    required this.farmId,
    required this.repository,
    super.key,
  });

  final String farmId;
  final dynamic repository;

  @override
  State<ManagerRecommendationsScreen> createState() =>
      _ManagerRecommendationsScreenState();
}

class _ManagerRecommendationsScreenState
    extends State<ManagerRecommendationsScreen> {
  final List<String> _categories = const [
    'All',
    'Soil & Fertilizer',
    'Crop Care',
    'Water & Irrigation',
  ];

  String _selectedCategory = 'All';

  static const List<_RecommendationTip> _tips = [
    _RecommendationTip(
      title: 'Optimal Planting Season & Soil pH',
      category: 'Soil & Fertilizer',
      summary:
          'Maintain soil pH between 6.0 - 6.8 for optimal nutrient absorption. Apply organic compost 2 weeks prior to planting.',
      recommendedFor: 'Maize, Beans, Tomatoes, Potatoes',
      icon: Icons.eco_outlined,
      backgroundColor: Color(0xFFF7E4E0),
    ),
    _RecommendationTip(
      title: 'Drip Irrigation Best Practices',
      category: 'Water & Irrigation',
      summary:
          'Water crops early in the morning (6 AM - 8 AM) to reduce evaporation loss by up to 30%.',
      recommendedFor: 'Tomatoes, Cabbage, Onions, Vegetables',
      icon: Icons.water_drop_outlined,
      backgroundColor: Color(0xFFE8F2EE),
    ),
    _RecommendationTip(
      title: 'Integrated Pest Management (IPM)',
      category: 'Crop Care',
      summary:
          'Scout fields twice a week for early armyworm and aphid signs. Rotate crops regularly to break pest cycles.',
      recommendedFor: 'Maize, Sorghum, Cabbage, Legumes',
      icon: Icons.bug_report_outlined,
      backgroundColor: Color(0xFFF4E7D2),
    ),
  ];

  List<_RecommendationTip> get _visibleTips {
    if (_selectedCategory == 'All') {
      return _tips;
    }
    return _tips
        .where((tip) => tip.category == _selectedCategory)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: AppBar(
          backgroundColor: const Color(0xFF0E7A5A),
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          toolbarHeight: 120,
          title: Padding(
            padding: const EdgeInsets.only(left: 8, right: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  color: Colors.white,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Get Tips & Recommendations',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Crop recommendations & agronomy advice',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECF4F0),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0E7A5A),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.lightbulb_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Smart Farming Tips',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF16322E),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Actionable recommendations for higher yields',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF5F716B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(_categories.length, (index) {
                          final category = _categories[index];
                          final selected = category == _selectedCategory;
                          return ChoiceChip(
                            label: Text(category),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedCategory = category),
                            backgroundColor: Colors.transparent,
                            selectedColor: const Color(0xFF0E7A5A).withValues(alpha: 0.1),
                            labelStyle: TextStyle(
                              color: selected ? const Color(0xFF0E7A5A) : const Color(0xFF3D4945),
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            ),
                            side: BorderSide(
                              color: selected ? const Color(0xFF0E7A5A) : Colors.grey.shade400,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            visualDensity: VisualDensity.compact,
                          );
                        }),
                      ),
                      const SizedBox(height: 18),
                      ..._visibleTips.map((tip) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: tip.backgroundColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0E7A5A).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  tip.icon,
                                  color: const Color(0xFF0E7A5A),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tip.title,
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E2D29),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tip.category,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0E7A5A),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      tip.summary,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        height: 1.45,
                                        color: Color(0xFF2E3A36),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Recommended for: ${tip.recommendedFor}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: Color(0xFF465B57),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8E0))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _BottomNavItem(icon: Icons.home_outlined, label: 'Dashboard', active: false),
                    _BottomNavItem(icon: Icons.grass_outlined, label: 'Crops', active: false),
                    _BottomNavItem(icon: Icons.list_alt_outlined, label: 'Activities', active: false),
                    _BottomNavItem(icon: Icons.group_outlined, label: 'Employees', active: false),
                    _BottomNavItem(icon: Icons.menu_rounded, label: 'More', active: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 24,
          color: active ? const Color(0xFF0E7A5A) : Colors.grey.shade600,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active ? const Color(0xFF0E7A5A) : Colors.grey.shade600,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
