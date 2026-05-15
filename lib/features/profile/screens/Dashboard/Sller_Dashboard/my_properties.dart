import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _myProperties = [];

  @override
  void initState() {
    super.initState();
    _fetchMyProperties();
  }

  Future<void> _fetchMyProperties() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('properties')
          .select('*')
          .eq('seller_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _myProperties = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching properties: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Property Listings"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myProperties.isEmpty
              ? const Center(child: Text("You haven't posted any properties yet."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _myProperties.length,
                  itemBuilder: (context, index) {
                    return PropertyCard(property: _myProperties[index]);
                  },
                ),
    );
  }
}

// ====================== Property Card Widget ======================
class PropertyCard extends StatefulWidget {
  final dynamic property;
  const PropertyCard({super.key, required this.property});

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    List<dynamic> images = widget.property['image_urls'] ?? [];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Slider Section
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 220,
                width: double.infinity,
                child: images.isNotEmpty
                    ? PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) => setState(() => _currentPage = index),
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            images[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Icon(Icons.broken_image, size: 50)),
                          );
                        },
                      )
                    : const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
              ),
              
              // Left Button
              if (images.length > 1 && _currentPage > 0)
                Positioned(
                  left: 10,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ),

              // Right Button
              if (images.length > 1 && _currentPage < images.length - 1)
                Positioned(
                  right: 10,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ),
                
              // Image Counter Indicator
              Positioned(
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${_currentPage + 1} / ${images.length}",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),

          // Property Details Section
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "৳${widget.property['price']}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        widget.property['listing_type'] ?? 'N/A',
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.property['title'] ?? 'No Title',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.property['location'] ?? 'No Location',
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFeature(Icons.king_bed, "${widget.property['bedrooms']} Bed"),
                    _buildFeature(Icons.bathtub, "${widget.property['bathrooms']} Bath"),
                    _buildFeature(Icons.square_foot, "${widget.property['area']} Sqft"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
      ],
    );
  }
}