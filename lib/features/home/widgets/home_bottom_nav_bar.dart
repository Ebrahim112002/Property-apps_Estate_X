import 'dart:ui';
import 'package:flutter/material.dart';

class HomeBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onAuctionTapped;

  const HomeBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onAuctionTapped,
  });

  @override
  State<HomeBottomNavBar> createState() => _HomeBottomNavBarState();
}

class _HomeBottomNavBarState extends State<HomeBottomNavBar> {
  // Royal Purple + Neon Color
  final Color royalPurple = const Color(0xFF8B00FF);
  final Color neonPurple = const Color(0xFFB14EFF);
  final Color inactiveColor = const Color(0xFFAAAAAA);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Neon Glassmorphic Bottom Bar
          Container(
            height: 72,
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08), // Highly Transparent
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: neonPurple.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: neonPurple.withOpacity(0.25),
                  blurRadius: 25,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home_rounded, 0),           // Home
                    _buildNavItem(Icons.search_rounded, 1),          // Search
                    const SizedBox(width: 70),                       // Space for Auction Button
                    _buildNavItem(Icons.favorite_rounded, 2),        // Saved / Favorites
                    _buildNavItem(Icons.dashboard_rounded, 3),       // Dashboard (Role based)
                  ],
                ),
              ),
            ),
          ),

          // Neon Floating Auction Button
          Positioned(
            bottom: 36,
            child: GestureDetector(
              onTap: widget.onAuctionTapped,
              child: Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [royalPurple, neonPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: neonPurple.withOpacity(0.6),
                      blurRadius: 25,
                      spreadRadius: 4,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: royalPurple.withOpacity(0.4),
                      blurRadius: 35,
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
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
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? neonPurple : inactiveColor,
                size: 27.5,
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 5,
                width: isSelected ? 5 : 0,
                decoration: BoxDecoration(
                  color: neonPurple,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: neonPurple.withOpacity(0.8),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ]
                      : [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}