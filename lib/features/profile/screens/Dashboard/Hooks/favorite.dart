import 'package:flutter/material.dart';
import 'package:estatex/core/constants/app_colors.dart';
import 'package:estatex/models/property_model.dart';
import 'package:estatex/services/supabase_service.dart';
import 'package:estatex/features/profile/screens/Dashboard/Hooks/property_details_page.dart';
import 'package:estatex/features/home/widgets/property_card.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final SupabaseService _service = SupabaseService();
  List<Property> _favoriteProperties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    try {
      final favorites = await _service.getFavoriteProperties();
      if (mounted) {
        setState(() {
          _favoriteProperties = favorites;
        });
      }
    } catch (e) {
      debugPrint('❌ Load Favorites Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load favorites")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeFromFavorite(String propertyId) async {
    final success = await _service.removeFromFavorite(propertyId);

    if (success && mounted) {
      // লিস্ট থেকে রিমুভ করি
      setState(() {
        _favoriteProperties.removeWhere(
          (property) => property.id == propertyId,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Removed from favorites"),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "My Favorites",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _favoriteProperties.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "No favorites yet",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Your favorite properties will appear here",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: ListView.builder(
                  itemCount: _favoriteProperties.length,
                  itemBuilder: (context, index) {
                    final property = _favoriteProperties[index];
                    return PropertyCard(
                      property: property,
                      // আমরা চাইলে এখানে কাস্টম remove অপশন দিতে পারি
                      onRemove: () => _removeFromFavorite(property.id!),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
