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

  @override
  void initState() {
    super.initState();
    _loadBookingStatus();
  }

  String? _getPropertyId() {
    return (widget.property['id'] ?? widget.property['property_id'])
        ?.toString();
  }

  Future<void> _loadBookingStatus() async {
    final propertyId = _getPropertyId();
    if (propertyId == null || propertyId.isEmpty) return;

    try {
      final hasRequested = await _supabaseService.hasRequestedBooking(
        propertyId: propertyId,
      );
      if (mounted) {
        setState(() {
          _hasRequestedBooking = hasRequested;
        });
      }
    } catch (e) {
      debugPrint('Error loading booking status: $e');
    }
  }

  Future<void> _requestBooking() async {
    debugPrint("Full Property Data Received: ${widget.property}");

    // Try multiple possible ID keys
    final propertyId = _getPropertyId();

    if (propertyId == null || propertyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Property ID not found. Please refresh."),
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
          "Do you want to send a booking request for this property?\n\n"
          "The seller will contact you soon.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, Request"),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    if (_hasRequestedBooking) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already requested booking for this property'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isRequesting = true);

    try {
      final success = await _supabaseService.requestBooking(
        propertyId: propertyId,
        message: "I am interested in this property. Please contact me.",
      );
      if (success && mounted) {
        setState(() {
          _hasRequestedBooking = true;
        });

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Booking Request Sent Successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        } 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
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
    final String description =
        widget.property['description'] ?? 'No description available.';
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
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image, size: 100),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 100),
                        ),
                ),

                if (images.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
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
                                  color: _currentIndex == index
                                      ? Colors.green
                                      : Colors.transparent,
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
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (_isResidential(propertyType))
                            _buildFeature(
                              Icons.king_bed,
                              "${widget.property['bedrooms'] ?? 0} Bed",
                            ),
                          if (_isResidential(propertyType))
                            _buildFeature(
                              Icons.bathtub,
                              "${widget.property['bathrooms'] ?? 0} Bath",
                            ),
                          _buildFeature(
                            Icons.square_foot,
                            "${widget.property['area'] ?? 'N/A'} Sqft",
                          ),
                          if (_isLand(propertyType))
                            _buildFeature(
                              Icons.landscape,
                              "${widget.property['plot_area'] ?? widget.property['area'] ?? 'N/A'} Sqft",
                            ),
                        ],
                      ),

                      const SizedBox(height: 35),
                      const Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: (_isRequesting || _hasRequestedBooking)
                  ? null
                  : _requestBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasRequestedBooking
                    ? Colors.grey
                    : Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
              child: _isRequesting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _hasRequestedBooking
                          ? "Requested Already"
                          : "Request for Booking",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

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
