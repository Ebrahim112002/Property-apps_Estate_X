import 'package:flutter/material.dart';
import '../../../../../services/supabase_service.dart';

class SellerDashboardHeader extends StatefulWidget {
  const SellerDashboardHeader({super.key});

  @override
  State<SellerDashboardHeader> createState() => _SellerDashboardHeaderState();
}

class _SellerDashboardHeaderState extends State<SellerDashboardHeader> {
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
    return parts.isNotEmpty ? parts[0] : 'Seller';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final avatarUrl = profile?['avatar_url'] as String?;
        final fullName = profile?['full_name'] ?? 'Seller';
        final firstName = _getFirstName(fullName);

        return Stack(
          children: [
            // ১. ওভারঅল ফুল ব্যাকগ্রাউন্ড গ্রাডিয়েন্ট ও ওয়েভ ইফেক্ট (হাইট কমানো হয়েছে)
            ClipPath(
              clipper: DashboardHeaderClipper(),
              child: Container(
                height:
                    220, // আপনার চাহিদা অনুযায়ী ব্যাকগ্রাউন্ড সাইজ ছোট করা হলো
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

            // ২. মেইন কন্টেন্ট লেয়ার
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top App Bar Area (Back Button + Title + Profile)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // বাম পাশে: ব্যাক বাটন ও টেক্সট
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
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "Back",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // মাঝখানে: টাইটেল সেন্টারিং (সাইজ বড় করা হয়েছে)
                        const Expanded(
                          child: Center(
                            child: Text(
                              "Seller Dashboard",
                              style: TextStyle(
                                fontSize: 22, // সাইজ বড় করা হয়েছে
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // ডানপাশে: প্রোফাইল অ্যাভাটার ও নাম (সাইজ বড় ও নরমাল করা হয়েছে)
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/seller-profile'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.2),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 22, // অ্যাভাটার বড় করা হয়েছে
                                  backgroundColor: Colors.white,
                                  backgroundImage:
                                      (avatarUrl != null &&
                                          avatarUrl.isNotEmpty)
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child:
                                      (avatarUrl == null || avatarUrl.isEmpty)
                                      ? const Icon(
                                          Icons.person_rounded,
                                          color: Color(0xFF203A43),
                                          size: 24,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ), // স্পেসিং বাড়ানো হয়েছে যাতে চাপাচাপি না লাগে
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "My Profile",
                                    style: TextStyle(
                                      fontSize: 13, // টেক্সট সাইজ বড় করা হয়েছে
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    firstName,
                                    style: const TextStyle(
                                      fontSize: 12, // টেক্সট সাইজ বড় করা হয়েছে
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
                    const SizedBox(
                      height: 20,
                    ), // ব্যাকগ্রাউন্ড ছোট করায় গ্যাপ সামঞ্জস্য করা হয়েছে
                    // ৩. মাঝখানে এলাইন করা ওয়েলকাম টেক্সট এরিয়া
                    Text(
                      "Welcome back, $firstName 👋",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Manage your properties & track performance",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==================== EXACT MATCH WAVE CLIPPER ====================
class DashboardHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 35);

    var firstControlPoint = Offset(size.width * 0.25, size.height - 5);
    var firstEndPoint = Offset(size.width * 0.5, size.height - 20);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width * 0.75, size.height - 40);
    var secondEndPoint = Offset(size.width, size.height - 15);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
