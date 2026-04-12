class Property {
  final String id;
  final String title;
  final String location;
  final double price;
  final String imageUrl;
  final String propertyType;
  final String? sellerName;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final bool isVerified;
  final DateTime createdAt;
  final String listingType;  // ✅ নতুন ফিল্ড: 'Rent' বা 'Sale'

  Property({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.propertyType,
    this.sellerName,
    this.bedrooms = 2,
    this.bathrooms = 2,
    this.area = 1200,
    this.isVerified = false,
    required this.createdAt,
    this.listingType = 'Rent',  // ✅ ডিফল্ট মান
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'No Title',
      location: json['location'] ?? 'No Location',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['image_url'] ?? '',
      propertyType: json['property_type'] ?? json['type'] ?? 'General',
      sellerName: _parseSellerName(json),
      bedrooms: json['bedrooms'] ?? json['bedroom'] ?? 2,
      bathrooms: json['bathrooms'] ?? json['bathroom'] ?? 2,
      area: (json['area'] ?? json['size'] ?? 1200).toDouble(),
      isVerified: json['is_verified'] ?? json['verified'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      listingType: json['listing_type'] ?? json['listingType'] ?? 'Rent',  // ✅ Supabase থেকে আসবে
    );
  }

  static String? _parseSellerName(Map<String, dynamic> json) {
    if (json['profiles'] != null && json['profiles']['full_name'] != null) {
      return json['profiles']['full_name'];
    }
    if (json['sellers'] != null && json['sellers']['full_name'] != null) {
      return json['sellers']['full_name'];
    }
    if (json['seller_name'] != null) {
      return json['seller_name'];
    }
    return 'Owner';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'price': price,
      'image_url': imageUrl,
      'property_type': propertyType,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'listing_type': listingType,  // ✅ যোগ করুন
    };
  }
}