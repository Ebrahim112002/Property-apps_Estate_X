import 'package:flutter/material.dart';
import '../../../../../services/supabase_service.dart';

class DashboardHeader extends StatefulWidget {
  final String title;
  final String role;
  final String? welcomeText;
  final String profileRoute;

  const DashboardHeader({
    super.key,
    required this.title,
    required this.role,
    this.welcomeText,
    required this.profileRoute,
  });

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _getProfile();
  }

  Future<Map<String, dynamic>?> _getProfile() async {
    final user = _supabaseService.currentUser;
    if (user == null) return null;
    return await _supabaseService.getProfile(user.id);
  }

  String _getFirstName(String fullName) {
    final parts = fullName.split(' ');
    return parts.isNotEmpty ? parts[0] : widget.role;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 385;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final avatarUrl = profile?['avatar_url'] as String?;
        final fullName = profile?['full_name'] ?? widget.role;
        final firstName = _getFirstName(fullName);

        return SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipPath(
                  clipper: DashboardHeaderClipper(),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF04261F),
                          const Color(0xFF0B4633),
                          const Color(0xFF145D47),
                          const Color(0xFF1B705A).withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Container(
                height: isSmallScreen ? 215 : 235, // হাইট সামান্য বাড়ানো হয়েছে
                width: double.infinity,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 14 : 16,
                      vertical: isSmallScreen ? 14 : 18, // উপর থেকে একটু বেশি স্পেস
                    ),
                    child: Column(
                      children: [
                        // Top Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/home',
                                    (route) => false,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Back",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isSmallScreen ? 14.5 : 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            Expanded(
                              child: Center(
                                child: Text(
                                  widget.title,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 20 : 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, widget.profileRoute),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black.withOpacity(0.2), width: 2),
                                    ),
                                    child: CircleAvatar(
                                      radius: isSmallScreen ? 20 : 22,
                                      backgroundColor: Colors.white,
                                      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                          ? NetworkImage(avatarUrl)
                                          : null,
                                      child: (avatarUrl == null || avatarUrl.isEmpty)
                                          ? const Icon(Icons.person_rounded, color: Color(0xFF203A43), size: 24)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text("My Profile", 
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                      Text(
                                        firstName,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 11.5 : 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22), // এখানে স্পেস বাড়ানো হয়েছে

                        // Welcome Text
                        Text(
                          widget.welcomeText ?? "Welcome back, $firstName 👋",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 21.5 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),

                        Text(
                          widget.role == "Seller"
                              ? "Manage your properties & track performance"
                              : "Find your dream property & track inquiries",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13.2 : 14,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Clipper (একই আছে)
class DashboardHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 35);

    var firstControlPoint = Offset(size.width * 0.25, size.height - 5);
    var firstEndPoint = Offset(size.width * 0.5, size.height - 20);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 0.75, size.height - 40);
    var secondEndPoint = Offset(size.width, size.height - 15);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}