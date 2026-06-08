import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/property_model.dart';
import 'package:estatex/services/supabase_service.dart';
import '../../profile/screens/Dashboard/Hooks/property_details_page.dart';
import '../../auth/screens/login_screen.dart';

class PropertyCard extends StatefulWidget {
  final Property property;
  final VoidCallback? onRemove;

  const PropertyCard({super.key, required this.property, this.onRemove});

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  final SupabaseService _service = SupabaseService();
  bool _isFavorited = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    if (_service.currentUser == null) return; 

    final isFav = await _service.isFavorite(widget.property.id);
    if (mounted) {
      setState(() => _isFavorited = isFav);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_service.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please login to add favorite"),
          backgroundColor: Colors.orange,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final wasFavorited = _isFavorited;
      bool success;
      if (_isFavorited) {
        success = await _service.removeFromFavorite(widget.property.id);
      } else {
        success = await _service.addToFavorite(widget.property.id);
      }

      if (success && mounted) {
        setState(() {
          _isFavorited = !_isFavorited;
        });

        if (wasFavorited && widget.onRemove != null) {
          widget.onRemove!();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorited ? "Added to favorite ❤️" : "Removed from favorite",
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Toggle Favorite Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isResidential(String? type) {
    if (type == null) return false;
    final t = type.toLowerCase();
    return t.contains('apartment') ||
        t.contains('house') ||
        t.contains('villa') ||
        t.contains('flat') ||
        t.contains('residential') ||
        t.contains('home');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: Image.network(
                  widget.property.imageUrls.isNotEmpty
                      ? widget.property.imageUrls.first
                      : '',
                  height: 210,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 210,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: GestureDetector(
                  onTap: _isLoading ? null : _toggleFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Icon(
                            _isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 22,
                            color: _isFavorited
                                ? Colors.red.shade400
                                : AppColors.primary,
                          ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.property.propertyType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.property.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.property.location,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "\$${widget.property.price.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          widget.property.listingType == 'Rent' ? "/month" : "",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (_isResidential(widget.property.propertyType))
                          _buildFeature(
                            Icons.bed,
                            "${widget.property.bedrooms}",
                          ),
                        const SizedBox(width: 14),
                        if (_isResidential(widget.property.propertyType))
                          _buildFeature(
                            Icons.bathtub,
                            "${widget.property.bathrooms}",
                          ),
                        const SizedBox(width: 14),
                        _buildFeature(Icons.garage_outlined, "1"),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PropertyDetailsPage(
                            property: widget.property.toJson(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "See Details",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}