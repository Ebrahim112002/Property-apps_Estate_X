class Property {
  final String id;
  final String sellerId; // কার প্রোপার্টি সেটা ট্র্যাক করার জন্য
  final String title;
  final String location;
  final double price;
  final List<String> imageUrls; // ✅ একাধিক ইমেজের জন্য List<String>
  final String propertyType; // 'Land', 'Flat', ইত্যাদি
  final String listingType; // 'Rent' বা 'Sale'
  final String? sellerName;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final bool isVerified;
  final DateTime createdAt;

  Property({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.location,
    required this.price,
    required this.imageUrls,
    required this.propertyType,
    required this.listingType,
    this.sellerName,
    this.bedrooms = 2,
    this.bathrooms = 2,
    required this.area,
    this.isVerified = false,
    required this.createdAt,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    // ইমেজ ইউআরএল লিস্ট হ্যান্ডেল করার লজিক
    List<String> urls = [];
    if (json['image_urls'] != null) {
      urls = List<String>.from(json['image_urls']);
    } else if (json['image_url'] != null &&
        json['image_url'].toString().isNotEmpty) {
      urls = [json['image_url']];
    }

    return Property(
      id: json['id']?.toString() ?? '',
      sellerId: json['seller_id']?.toString() ?? '',
      title: json['title'] ?? 'No Title',
      location: json['location'] ?? 'No Location',
      price: (json['price'] ?? 0).toDouble(),
      imageUrls: urls,
      propertyType: json['property_type'] ?? json['type'] ?? 'Flat',
      listingType: json['listing_type'] ?? 'Rent',
      sellerName: _parseSellerName(json),
      bedrooms: json['bedrooms'] ?? json['bedroom'] ?? 0,
      bathrooms: json['bathrooms'] ?? json['bathroom'] ?? 0,
      area: (json['area'] ?? json['size'] ?? 0).toDouble(),
      isVerified: json['is_verified'] ?? json['verified'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  static String? _parseSellerName(Map<String, dynamic> json) {
    if (json['profiles'] != null && json['profiles']['full_name'] != null) {
      return json['profiles']['full_name'];
    }
    if (json['seller_name'] != null) return json['seller_name'];
    return 'Owner';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'title': title,
      'location': location,
      'price': price,
      'image_urls': imageUrls, // ✅ Supabase-এ text[] বা jsonb হিসেবে জমা হবে
      'property_type': propertyType,
      'listing_type': listingType,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
