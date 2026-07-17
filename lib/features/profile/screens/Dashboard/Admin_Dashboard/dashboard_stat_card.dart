import 'package:flutter/material.dart';

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        // LayoutBuilder gives us the card's REAL available size (whatever
        // the parent GridView/aspect-ratio actually hands it), not just
        // the screen width — so sizing decisions are based on truth.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double cardWidth = constraints.maxWidth;
            final bool isSmallScreen = cardWidth < 170;

            final double horizontalPad = isSmallScreen ? 14 : 18;
            final double verticalPad = isSmallScreen ? 12 : 16;
            final double iconSize = isSmallScreen ? 24 : 28;
            final double valueFontSize = isSmallScreen ? 20 : 24;
            final double titleFontSize = isSmallScreen ? 12 : 13;

            // FittedBox = the actual overflow fix. Whatever height the
            // parent hands this card, the whole content block scales down
            // together (never up, via scaleDown) to fit inside it exactly.
            // No more yellow/black overflow bars, even on tiny cards.
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPad,
                vertical: verticalPad,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: cardWidth - (horizontalPad * 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: color, size: iconSize),
                      SizedBox(height: isSmallScreen ? 10 : 14),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          color: Colors.grey[700],
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}