class Property {
  final String id;
  final String title;
  final String location;
  final double price;
  final String imageUrl;
  final String propertyType;
  final String? sellerName; // সেলারের নাম রাখার জন্য

  Property({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.propertyType,
    this.sellerName,
  });

 factory Property.fromJson(Map<String, dynamic> json) {
  return Property(
    id: json['id'].toString(),
    title: json['title'] ?? '',
    location: json['location'] ?? '',
    price: (json['price'] as num).toDouble(),
    imageUrl: json['image_url'] ?? '',
    propertyType: json['property_type'] ?? '',
    // Join Query-র ডাটা ধরার সঠিক নিয়ম
    sellerName: json['sellers'] != null ? json['sellers']['name'] : 'Owner',
  );
}
}