import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HomeSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onFilterTap;

  const HomeSearchBar({super.key, required this.controller, this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(Icons.search, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Search your home...",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}