import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/property_model.dart';
import '../../../services/supabase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<Property>> _propertiesFuture;
  String selectedCategory = 'House'; // ডিফল্ট ক্যাটাগরি

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _propertiesFuture = _supabaseService.fetchProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // ১. লোকেশন ও প্রোফাইল সেকশন
              _buildHeader(),
              const SizedBox(height: 25),
              // ২. সার্চ বার
              _buildSearchBar(),
              const SizedBox(height: 25),
              // ৩. ক্যাটাগরি লিস্ট
              _buildCategoryList(),
              const SizedBox(height: 25),
              // ৪. Recommended সেকশন (Horizontal)
              _buildSectionHeader("Recommended Property"),
              const SizedBox(height: 15),
              _buildRecommendedList(),
              const SizedBox(height: 25),
              // ৫. Nearby সেকশন (Vertical)
              _buildSectionHeader("Nearby Property"),
              const SizedBox(height: 15),
              _buildNearbyList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Location",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            Row(
              children: const [
                Icon(Icons.location_on, color: AppColors.primary, size: 18),
                SizedBox(width: 4),
                Text(
                  "New York, USA",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: const Badge(
            child: Icon(Icons.notifications_outlined, size: 26),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: const [
                Icon(Icons.search, color: Colors.grey),
                SizedBox(width: 10),
                Text(
                  "Search property...",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 15),
        Container(
          height: 55,
          width: 55,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.tune, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildCategoryList() {
    List<Map<String, dynamic>> categories = [
      {'name': 'House', 'icon': Icons.home_filled},
      {'name': 'Villa', 'icon': Icons.villa},
      {'name': 'Apartment', 'icon': Icons.apartment},
      {'name': 'Bungalow', 'icon': Icons.cottage},
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: categories.map((cat) {
        bool isSel = selectedCategory == cat['name'];
        return Column(
          children: [
            GestureDetector(
              onTap: () => setState(() => selectedCategory = cat['name']),
              child: Container(
                height: 65,
                width: 65,
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  cat['icon'],
                  color: isSel ? Colors.white : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cat['name'],
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Text(
          "See all",
          style: TextStyle(color: AppColors.secondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildRecommendedList() {
    return SizedBox(
      height: 280,
      child: FutureBuilder<List<Property>>(
        future: _propertiesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) =>
                _buildLargeCard(snapshot.data![index]),
          );
        },
      ),
    );
  }

  Widget _buildLargeCard(Property property) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  property.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: const Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            property.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            property.location,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Spacer(),
          Text(
            "\$${property.price}/month",
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyList() {
    return FutureBuilder<List<Property>>(
      future: _propertiesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) =>
              _buildSmallCard(snapshot.data![index]),
        );
      },
    );
  }

  Widget _buildSmallCard(Property property) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              property.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  property.location,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  "\$${property.price}/month",
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.favorite_border, color: Colors.grey),
        ],
      ),
    );
  }
}
