import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HomeSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const HomeSectionHeader({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: onSeeAll,
          child: Text("See all", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}