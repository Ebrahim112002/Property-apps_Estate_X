import 'package:flutter/material.dart';

// ==================== RESPONSIVE HELPERS ====================
// One place that decides sizing/aspect-ratio for every breakpoint,
// so both grids stay in sync and nothing gets clipped on narrow phones.
class _GridSizing {
  final double aspectRatio;
  final double iconSize;
  final double valueFontSize;
  final double titleFontSize;
  final double smallFontSize;
  final double paddingV;
  final double paddingH;
  final double spacing;

  const _GridSizing({
    required this.aspectRatio,
    required this.iconSize,
    required this.valueFontSize,
    required this.titleFontSize,
    required this.smallFontSize,
    required this.paddingV,
    required this.paddingH,
    required this.spacing,
  });

  // width = the actual width the grid gets (from LayoutBuilder),
  // not just MediaQuery, so it's correct even inside padded parents.
  factory _GridSizing.of(double width, {required bool tallCard}) {
    if (width < 320) {
      return _GridSizing(
        aspectRatio: tallCard ? 1.15 : 1.35,
        iconSize: 20,
        valueFontSize: 18,
        titleFontSize: 10.5,
        smallFontSize: 9,
        paddingV: 8,
        paddingH: 8,
        spacing: 8,
      );
    } else if (width < 380) {
      return _GridSizing(
        aspectRatio: tallCard ? 1.3 : 1.5,
        iconSize: 22,
        valueFontSize: 20,
        titleFontSize: 11.5,
        smallFontSize: 9.5,
        paddingV: 10,
        paddingH: 10,
        spacing: 10,
      );
    } else if (width < 420) {
      return _GridSizing(
        aspectRatio: tallCard ? 1.5 : 1.7,
        iconSize: 25,
        valueFontSize: 22,
        titleFontSize: 12,
        smallFontSize: 10,
        paddingV: 12,
        paddingH: 12,
        spacing: 12,
      );
    }
    return _GridSizing(
      aspectRatio: tallCard ? 1.65 : 1.85,
      iconSize: 27,
      valueFontSize: 24,
      titleFontSize: 12.5,
      smallFontSize: 10.5,
      paddingV: 14,
      paddingH: 14,
      spacing: 14,
    );
  }
}

// ==================== QUICK ACTIONS COMPONENT ====================
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final sizing = _GridSizing.of(width, tallCard: false);

        final List<Widget> actionButtons = [
          _buildActionButton(
            sizing: sizing,
            icon: Icons.add_circle_outline,
            label: "Add Property",
            color: Colors.deepPurple,
            onTap: () => Navigator.pushNamed(context, '/add-property', arguments: 'Normal'),
          ),
          _buildActionButton(
            sizing: sizing,
            icon: Icons.gavel_outlined,
            label: "Add Auction",
            color: Colors.orange,
            onTap: () => Navigator.pushNamed(context, '/add-bid-properties', arguments: 'Auction'),
          ),
          _buildActionButton(
            sizing: sizing,
            icon: Icons.list_alt_outlined,
            label: "My Properties",
            color: Colors.indigo,
            onTap: () => Navigator.pushNamed(context, '/my-properties'),
          ),
          _buildActionButton(
            sizing: sizing,
            icon: Icons.local_offer_outlined,
            label: "Your Bids",
            color: Colors.teal,
            onTap: () => Navigator.pushNamed(context, '/my-bid-properties'),
          ),
        ];

        return Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: sizing.spacing,
              mainAxisSpacing: sizing.spacing,
              childAspectRatio: sizing.aspectRatio,
              children: actionButtons,
            ),
            SizedBox(height: sizing.spacing + 2),
            // My Bids History Banner
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/my-bids-history'),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: width < 380 ? 13 : 17,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.history_edu_rounded, color: Colors.white, size: width < 380 ? 22 : 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "My Bids History",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: width < 380 ? 14.5 : 16,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton({
    required _GridSizing sizing,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: sizing.paddingV, horizontal: sizing.paddingH),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        // mainAxisSize.min + Flexible label = content never demands more
        // height than the cell actually has, so it can't overflow.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: sizing.iconSize),
            SizedBox(height: sizing.paddingV * 0.55),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: sizing.titleFontSize + 0.5,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== STATISTICS GRID COMPONENT ====================
class DashboardStatsGrid extends StatelessWidget {
  final int totalProperties;
  final int activeListings;
  final int totalBids;
  final int totalFavorites;
  final int totalBookingRequests;

  const DashboardStatsGrid({
    super.key,
    required this.totalProperties,
    required this.activeListings,
    required this.totalBids,
    required this.totalFavorites,
    required this.totalBookingRequests,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        // tallCard: true because one card has an extra "Tap to view" line —
        // sizing accounts for the tallest possible card content up front.
        final sizing = _GridSizing.of(width, tallCard: true);

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: sizing.spacing,
          mainAxisSpacing: sizing.spacing,
          childAspectRatio: sizing.aspectRatio,
          children: [
            _buildStatCard(sizing, "Total Properties", totalProperties.toString(), Icons.home_work_outlined, Colors.blue, onTap: () => Navigator.pushNamed(context, '/seller-booking-requests')),
            _buildStatCard(sizing, "Active Listings", activeListings.toString(), Icons.visibility_outlined, Colors.green, onTap: () {}),
            _buildStatCard(sizing, "Total Bids", totalBids.toString(), Icons.gavel_rounded, Colors.orange, onTap: () => Navigator.pushNamed(context, '/seller-bid-history')),
            _buildStatCard(sizing, "Favorites", totalFavorites.toString(), Icons.favorite, Colors.purple, onTap: () => Navigator.pushNamed(context, '/favorites')),
            _buildStatCard(sizing, "Booking Requests", totalBookingRequests.toString(), Icons.request_page_outlined, Colors.teal, onTap: () => Navigator.pushNamed(context, '/buyer-booking-requests')),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    _GridSizing sizing,
    String title,
    String value,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: sizing.paddingH, vertical: sizing.paddingV),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        // No more Spacer() forcing a fixed gap — mainAxisSize.min lets the
        // column size to its content, and the aspect ratio above already
        // guarantees enough height, so nothing gets pushed past the card.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: sizing.iconSize),
            SizedBox(height: sizing.paddingV * 0.5),
            // FittedBox = a safety net so a big number (e.g. "12,345")
            // shrinks to fit instead of overflowing on very narrow cards.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(fontSize: sizing.valueFontSize, fontWeight: FontWeight.bold, height: 1),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: sizing.titleFontSize, color: Colors.grey[700], height: 1.1),
            ),
            if (title == "Booking Requests")
              Text(
                "Tap to view",
                style: TextStyle(fontSize: sizing.smallFontSize, color: Colors.teal, fontWeight: FontWeight.w500),
              ),
          ],
        ),
      ),
    );
  }
}