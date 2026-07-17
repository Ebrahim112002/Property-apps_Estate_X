import 'package:flutter/material.dart';
import '../../../../../../services/supabase_service.dart';

class PropertyDetailsPage extends StatefulWidget {
  final Map<String, dynamic> property;
  const PropertyDetailsPage({super.key, required this.property});

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  final _supabaseService = SupabaseService();
  int _currentIndex = 0;
  bool _isRequesting = false;
  bool _hasRequestedBooking = false;
  String? _currentBookingId;

  // Favorite States
  bool _isFavorited = false;
  bool _isFavoriteLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBookingStatus();
    _checkIfFavorite();
  }

  String? _getPropertyId() {
    return (widget.property['id'] ?? widget.property['property_id'])?.toString();
  }

  String? _getSellerId() {
    return widget.property['seller_id']?.toString();
  }

  // ==================== Favorite Logic ====================
  Future<void> _checkIfFavorite() async {
    if (_supabaseService.currentUser == null) return;

    final propertyId = _getPropertyId();
    if (propertyId == null) return;

    final isFav = await _supabaseService.isFavorite(propertyId);
    if (mounted) {
      setState(() => _isFavorited = isFav);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_supabaseService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please login to add favorite"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isFavoriteLoading = true);

    try {
      final propertyId = _getPropertyId();
      if (propertyId == null) return;

      bool success;
      if (_isFavorited) {
        success = await _supabaseService.removeFromFavorite(propertyId);
      } else {
        success = await _supabaseService.addToFavorite(propertyId);
      }

      if (success && mounted) {
        setState(() => _isFavorited = !_isFavorited);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorited ? "Added to favorite ❤️" : "Removed from favorite",
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Favorite Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isFavoriteLoading = false);
    }
  }

  // ==================== Booking Logic (অপরিবর্তিত) ====================
  Future<void> _loadBookingStatus() async {
    final propertyId = _getPropertyId();
    if (propertyId == null || propertyId.isEmpty) return;

    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      final response = await _supabaseService.supabaseClient
          .from('booking_requests')
          .select('id, status')
          .eq('property_id', propertyId)
          .eq('buyer_id', user.id)
          .neq('status', 'cancelled')
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _hasRequestedBooking = true;
          _currentBookingId = response['id']?.toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading booking status: $e');
    }
  }

  Future<void> _requestBooking() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please login first to submit a booking request!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final propertyId = _getPropertyId();
    final sellerId = _getSellerId();

    if (propertyId == null || propertyId.isEmpty || sellerId == null || sellerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Something went wrong"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Booking Request"),
        content: const Text(
          "Do you want to send a booking request for this property?\n\nThe seller will contact you soon.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Yes, Request"),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    setState(() => _isRequesting = true);

    try {
      final success = await _supabaseService.createBookingRequest(
        propertyId: propertyId,
        sellerId: sellerId,
      );
      
      if (success && mounted) {
        await _loadBookingStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Booking Request Sent Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  Future<void> _cancelBooking() async {
    if (_currentBookingId == null) return;

    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cancel Booking Request"),
        content: const Text(
          "Are you sure you want to cancel your booking request for this property?",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Yes, Cancel Request"),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    setState(() => _isRequesting = true);

    try {
      final success = await _supabaseService.updateBookingStatus(
        bookingId: _currentBookingId!,
        nextStatus: 'cancelled',
      );

      if (success && mounted) {
        setState(() {
          _hasRequestedBooking = false;
          _currentBookingId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🔴 Booking Request Cancelled Successfully."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cancellation Failed: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isRequesting = false);
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

  bool _isLand(String? type) {
    if (type == null) return false;
    final t = type.toLowerCase();
    return t.contains('land') || t.contains('plot') || t.contains('বাস্তু');
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> images = widget.property['image_urls'] ?? [];
    final String title = widget.property['title'] ?? 'No Title';
    final String location = widget.property['location'] ?? 'No Location';
    final String price = widget.property['price']?.toString() ?? '0';
    final String listingType = widget.property['listing_type'] ?? '';
    final String description = widget.property['description'] ?? 'No description available.';
    final String propertyType = widget.property['property_type'] ?? 'Property';

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 380,
                  width: double.infinity,
                  child: images.isNotEmpty
                      ? Image.network(
                          images[_currentIndex],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 100),
                        ),
                ),

                if (images.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: SizedBox(
                      height: 85,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => setState(() => _currentIndex = index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _currentIndex == index ? Colors.green : Colors.transparent,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  images[index],
                                  width: 85,
                                  height: 85,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            propertyType,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "৳$price${listingType == 'Rent' ? '/Month' : ''}",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF046007),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (_isResidential(propertyType))
                            _buildFeature(Icons.king_bed, "${widget.property['bedrooms'] ?? 0} Bed"),
                          if (_isResidential(propertyType))
                            _buildFeature(Icons.bathtub, "${widget.property['bathrooms'] ?? 0} Bath"),
                          _buildFeature(Icons.square_foot, "${widget.property['area'] ?? 'N/A'} Sqft"),
                          if (_isLand(propertyType))
                            _buildFeature(Icons.landscape, "${widget.property['plot_area'] ?? widget.property['area'] ?? 'N/A'} Sqft"),
                        ],
                      ),
                      const SizedBox(height: 35),
                      const Text(
                        "Description",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 16, height: 1.65),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Top Right: Favorite + Share
          Positioned(
            top: 50,
            right: 20,
            child: Row(
              children: [
                // Favorite Button
                GestureDetector(
                  onTap: _isFavoriteLoading ? null : _toggleFavorite,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 22,
                    child: _isFavoriteLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Icon(
                            _isFavorited ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorited ? Colors.red : Colors.black87,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Share Button
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.share, color: Colors.black87),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Share feature coming soon")),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Back Button (আসল জায়গায়)
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Bottom Booking Button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _isRequesting
                  ? null
                  : (_hasRequestedBooking ? _cancelBooking : _requestBooking),
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasRequestedBooking ? Colors.red[700] : Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              child: _isRequesting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _hasRequestedBooking ? "Cancel the Booking" : "Request for Booking",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.green[700]),
        const SizedBox(height: 6),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}