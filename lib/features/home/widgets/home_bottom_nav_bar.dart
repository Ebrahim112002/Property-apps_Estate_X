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
  final Color neonPurple = const Color(0xFFB14EFF);
  final Color royalPurple = const Color(0xFF6A00FF);
  final Color inactiveColor = const Color(0xFFB0B0B0);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // ---- Glass Notched Bottom Bar (with background image) ----
          Container(
            height: 78,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipPath(
              clipper: _NotchClipper(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // background image layer
                  Image.network(
                    'https://i.ibb.co.com/DfJ3D39S/download-2.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: const Color(0xFF1A1A2E)),
                  ),
                  // frosted glass blur layer
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.16),
                            Colors.white.withOpacity(0.06),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      // nav items — Expanded keeps every item evenly
                      // spaced no matter the screen width, so nothing
                      // overlaps or drifts into the neighbour's spot.
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          children: [
                            Expanded(child: _buildNavItem(Icons.home_rounded, 0)),
                            Expanded(child: _buildNavItem(Icons.search_rounded, 1)),
                            const Expanded(flex: 2, child: SizedBox()), // notch gap
                            Expanded(child: _buildNavItem(Icons.favorite_rounded, 2)),
                            Expanded(child: _buildNavItem(Icons.chat_bubble_rounded, 3)),
                            if (screenWidth > 380)
                              Expanded(child: _buildNavItem(Icons.dashboard_rounded, 4)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---- Floating Center Button ----
          Positioned(
            bottom: 44,
            child: GestureDetector(
              onTap: widget.onAuctionTapped,
              child: Container(
                height: 66,
                width: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [royalPurple, neonPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: neonPurple.withOpacity(0.55),
                      blurRadius: 22,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  color: Colors.white,
                  size: 30,
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

    return GestureDetector(
      onTap: () => widget.onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
            Icon(
              icon,
              color: isSelected ? neonPurple : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isSelected ? 5 : 0,
              width: isSelected ? 5 : 0,
              decoration: BoxDecoration(
                color: neonPurple,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: neonPurple.withOpacity(0.7),
                          blurRadius: 6,
                        )
                      ]
                    : [],
              ),
            ),
        ],
      ),
    );
  }
}

/// Creates the bar shape with a smooth scooped notch in the middle
/// (matches the reference image) for the floating button to sit in.
class _NotchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double w = size.width;
    final double h = size.height;
    const double cornerRadius = 34;
    const double notchRadius = 40;

    final double centerX = w / 2;
    final double notchWidth = notchRadius * 2.3;

    final Path path = Path();

    // top-left corner
    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    // straight line to start of notch
    path.lineTo(centerX - notchWidth, 0);

    // scoop down into the notch (left curve)
    path.cubicTo(
      centerX - notchWidth * 0.55,
      0,
      centerX - notchRadius,
      h * 0.62,
      centerX,
      h * 0.62,
    );

    // scoop back up out of the notch (right curve)
    path.cubicTo(
      centerX + notchRadius,
      h * 0.62,
      centerX + notchWidth * 0.55,
      0,
      centerX + notchWidth,
      0,
    );

    // straight line to top-right corner
    path.lineTo(w - cornerRadius, 0);
    path.quadraticBezierTo(w, 0, w, cornerRadius);

    // right side down
    path.lineTo(w, h - cornerRadius);
    path.quadraticBezierTo(w, h, w - cornerRadius, h);

    // bottom line
    path.lineTo(cornerRadius, h);
    path.quadraticBezierTo(0, h, 0, h - cornerRadius);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}