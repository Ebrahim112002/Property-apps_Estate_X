import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HomeFilterChips extends StatelessWidget {
  final String selectedType;
  final String selectedFilter;
  final Function(String) onTypeChanged;
  final Function(String) onCategoryChanged;

  const HomeFilterChips({
    super.key,
    required this.selectedType,
    required this.selectedFilter,
    required this.onTypeChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==================== Property Type Section ====================
        _buildSectionTitle("Property Type", Icons.category_rounded),
        const SizedBox(height: 12),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Any type', 'Rent', 'Buy'].map((type) {
              bool isSelected = selectedType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildModernChip(
                  label: type,
                  isSelected: isSelected,
                  onSelected: () => onTypeChanged(type),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // ==================== Categories Section ====================
        _buildSectionTitle("Categories", Icons.home_work_rounded),
        const SizedBox(height: 12),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['House', 'Apartment', 'Villa', 'Land'].map((cat) {
              bool isSelected = selectedFilter == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildModernChip(
                  label: cat,
                  isSelected: isSelected,
                  onSelected: () => onCategoryChanged(cat),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Modern Premium Chip
  Widget _buildModernChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  // Section Title with Icon (Premium Feel)
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 22,
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}