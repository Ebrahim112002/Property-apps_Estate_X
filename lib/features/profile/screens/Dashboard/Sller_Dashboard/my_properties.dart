import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Hooks/edit_property_screen.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _myProperties = [];

  // Emerald Green Theme
  final Color primaryGreen = const Color(0xFF046007);
  final Color darkGreen = const Color(0xFF0A603);

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

  Future<void> _deleteProperty(String propertyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Property?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('properties').delete().eq('id', propertyId);
      setState(() {
        _myProperties.removeWhere((p) => p['id'] == propertyId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Property deleted successfully"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _editProperty(dynamic property) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPropertyScreen(property: property)),
    ).then((value) {
      if (value == true) _fetchMyProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Property Listings"),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF046007)))
          : _myProperties.isEmpty
              ? const Center(child: Text("You haven't posted any properties yet."))
              : RefreshIndicator(
                  onRefresh: _fetchMyProperties,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _myProperties.length,
                    itemBuilder: (context, index) {
                      final property = _myProperties[index];
                      return PropertyCard(
                        property: property,
                        onEdit: () => _editProperty(property),
                        onDelete: () => _deleteProperty(property['id'].toString()),
                      );
                    },
                  ),
                ),
    );
  }
}

// ====================== Property Card Widget ======================
class PropertyCard extends StatefulWidget {
  final dynamic property;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final Color primaryGreen = const Color(0xFF046007);

  @override
  Widget build(BuildContext context) {
    final List<dynamic> images = widget.property['image_urls'] ?? [];
    final String propertyType = widget.property['property_type'] ?? 'Flat';
    final String listingType = widget.property['listing_type'] ?? 'Sale';

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Slider
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 240,
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
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 80, color: Colors.grey),
                      ),
              ),

              if (images.length > 1) ...[
                if (_currentPage > 0)
                  Positioned(left: 12, child: _buildArrowButton(Icons.arrow_back_ios_new, () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut))),
                if (_currentPage < images.length - 1)
                  Positioned(right: 12, child: _buildArrowButton(Icons.arrow_forward_ios, () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut))),
              ],

              Positioned(
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${_currentPage + 1} / ${images.length}",
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "৳${widget.property['price']}",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryGreen),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        listingType,
                        style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.property['title'] ?? 'No Title',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
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
                const Divider(height: 30),

                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    if (propertyType == 'Flat') ...[
                      _buildFeature(Icons.king_bed, "${widget.property['bedrooms'] ?? 0} Bed"),
                      _buildFeature(Icons.bathtub, "${widget.property['bathrooms'] ?? 0} Bath"),
                    ],
                    if (propertyType == 'Land')
                      _buildFeature(Icons.landscape, "${widget.property['plot_size'] ?? widget.property['area']}"),
                    if (propertyType == 'Commercial')
                      _buildFeature(Icons.local_parking, "${widget.property['parking_spaces'] ?? 0} Parking"),
                    _buildFeature(Icons.square_foot, "${widget.property['area']} Sqft"),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text("Edit"),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryGreen),
                          foregroundColor: primaryGreen,
                        ),
                        onPressed: widget.onEdit,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        label: const Text("Delete", style: TextStyle(color: Colors.red)),
                        onPressed: widget.onDelete,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowButton(IconData icon, VoidCallback onTap) {
    return CircleAvatar(
      backgroundColor: Colors.black.withOpacity(0.6),
      radius: 18,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: primaryGreen),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.blueGrey)),
      ],
    );
  }
}