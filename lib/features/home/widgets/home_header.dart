import 'package:flutter/material.dart';
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
        final fullName = profile?['full_name'] ?? 'Md';
        final area = profile?['area'] ?? 'Dhaka-1216';
        final city = profile?['city'] ?? 'Mirpur';
        final avatarUrl = profile?['avatar_url'] as String?;

        final firstName = _getFirstName(fullName);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Greeting + Location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, $firstName!",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primary,
                          size: 19,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "$area, $city",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Notification Icon with modern badge
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
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
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        ' ',
                        style: TextStyle(fontSize: 8),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 14),

              // Avatar with border & shadow
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                            size: 32,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getProfile(SupabaseService service) async {
    final user = service.currentUser;
    if (user == null) return null;
    return await service.getProfile(user.id);
  }

  String _getFirstName(String fullName) {
    final parts = fullName.split(' ');
    return parts.isNotEmpty ? parts[0] : 'User';
  }
}