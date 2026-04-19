import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HomeBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const HomeBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  State<HomeBottomNavBar> createState() => _HomeBottomNavBarState();
}

class _HomeBottomNavBarState extends State<HomeBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      // নিচের দিকে একটু বাড়তি হাইট দিচ্ছি যাতে পপ-আপ ইফেক্ট এর জন্য পর্যাপ্ত জায়গা থাকে
      height: 100,
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // মেইন নেভিগেশন বার (Deep Navy Background)
          Container(
            height: 75,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.background, // আপনার লাক্সারি ডিপ নেভি ব্লু
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: AppColors.background.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.home_filled, 0),
                _buildNavItem(Icons.search_rounded, 1),
                _buildNavItem(Icons.favorite_rounded, 2),
                _buildNavItem(Icons.person_rounded, 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final bool isSelected = widget.selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // আইকন পপ-আপ অ্যানিমেশন
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack, // প্রিমিয়াম বাউন্স ইফেক্ট
              // আইকনটি সিলেক্ট হলে ৩টি পিক্সেল উপরে পপ-আপ করবে
              transform: Matrix4.translationValues(0, isSelected ? -38 : 0, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // গোল্ডেন সার্কেল কন্টেইনার
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    padding: EdgeInsets.all(isSelected ? 14 : 10),
                    decoration: BoxDecoration(
                      // সিলেক্টেড অবস্থায় আপনার Accent (Warm Gold) কালার
                      color: isSelected ? AppColors.accent : Colors.transparent,
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      icon,
                      // আইকন কালার: সিলেক্ট হলে পিওর হোয়াইট, না হলে সেকেন্ডারি টেক্সট কালার
                      color: isSelected ? Colors.white : AppColors.textSecondary.withOpacity(0.6),
                      size: isSelected ? 28 : 24, // সিলেক্ট হলে বড় হবে
                    ),
                  ),
                  
                  // নিচের ছোট গোল্ডেন ডট ইন্ডিকেটর
                  const SizedBox(height: 6),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isSelected ? 1 : 0,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}