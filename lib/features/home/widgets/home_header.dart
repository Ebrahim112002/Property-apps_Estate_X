import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/supabase_service.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback? onAvatarTap;

  const HomeHeader({super.key, this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    final service = SupabaseService();

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getProfile(service),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final isLoggedIn = profile != null;

        final fullName = profile?['full_name'] ?? '';
        final firstName = _getFirstName(fullName);
        final avatarUrl = profile?['avatar_url'] as String?;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== Left: EstateX + Greeting ====================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),

                    // Dynamic Greeting
                    Text(
                      isLoggedIn ? "Hello, $firstName!" : _getGreeting(),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Date
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getPremiumDate(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // ==================== Right Side: Notification + Avatar ====================
              Row(
                children: [
                  // Notification
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          size: 26,
                          color: Colors.black87,
                        ),
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          height: 8,
                          width: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  // Avatar
                  GestureDetector(
                    onTap: onAvatarTap,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.4),
                          width: 2.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 29,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? const Icon(
                                Icons.person_rounded,
                                color: Colors.grey,
                                size: 32,
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== Helper Functions ====================

  Future<Map<String, dynamic>?> _getProfile(SupabaseService service) async {
    final user = service.currentUser;
    if (user == null) return null;
    return await service.getProfile(user.id);
  }

  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return 'User';
    final parts = fullName.trim().split(' ');
    return parts.first;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  String _getPremiumDate() {
    return DateFormat("EEEE, dd MMMM").format(DateTime.now());
  }
}
