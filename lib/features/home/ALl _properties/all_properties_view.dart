import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/property_model.dart';
import '../../profile/screens/Dashboard/Hooks/property_card.dart';
import '../../profile/screens/Dashboard/Hooks/property_details_page.dart';
import '../widgets/home_search_bar.dart';   // সঠিক পাথ নিশ্চিত করো

class AllPropertiesView extends StatefulWidget {
  const AllPropertiesView({super.key});

  @override
  State<AllPropertiesView> createState() => _AllPropertiesViewState();
}

class _AllPropertiesViewState extends State<AllPropertiesView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String selectedType = 'Any type';
  String selectedFilter = 'Any type';

  List<Property> _allProperties = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "All Properties",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // ==================== SEARCH BAR ====================
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: HomeSearchBar(
              controller: _searchController,
              allProperties: _allProperties,        // ← এখানে আসল লিস্ট দেয়া হচ্ছে
              onFilterTap: () {
                // Filter bottom sheet চাইলে পরে যোগ করতে পারবে
              },
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // ==================== MAIN CONTENT ====================
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('properties')
                  .stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Convert to Property Model
                _allProperties = snapshot.data!
                    .map((map) => Property.fromJson(map))
                    .toList();

                // Filtering (Search + Type + Category)
                final displayProperties = _allProperties.where((property) {
                  final query = _searchQuery.toLowerCase().trim();

                  final titleMatch = property.title.toLowerCase().contains(query);
                  final locationMatch = property.location.toLowerCase().contains(query);
                  final textMatches = query.isEmpty || titleMatch || locationMatch;

                  final typeMatches = selectedType == 'Any type' ||
                      property.listingType.toLowerCase() == selectedType.toLowerCase();

                  final categoryMatches = selectedFilter == 'Any type' ||
                      property.propertyType.toLowerCase() == selectedFilter.toLowerCase();

                  return textMatches && typeMatches && categoryMatches;
                }).toList();

                if (displayProperties.isEmpty) {
                  return const Center(
                    child: Text(
                      'No properties match your search',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    int crossAxisCount = 1;
                    double extent = 420;

                    if (width > 1500) {
                      crossAxisCount = 2;
                      extent = 440;
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 16,
                        mainAxisExtent: extent,
                      ),
                      itemCount: displayProperties.length,
                      itemBuilder: (context, index) {
                        return PropertyCard(
                          property: displayProperties[index],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}