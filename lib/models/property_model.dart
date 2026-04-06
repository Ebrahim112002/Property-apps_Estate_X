class Property {
  final String id;
  final String title;
  final String location;
  final double price;
  final String imageUrl;
  final String propertyType;
  final String? sellerName;

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
      // ১. ID অনেক সময় int বা String আসতে পারে, তাই .toString() করা নিরাপদ
      id: json['id']?.toString() ?? '',
      
      title: json['title'] ?? 'No Title',
      location: json['location'] ?? 'No Location',
      
      // ২. Price হ্যান্ডলিং: num কে double এ কনভার্ট করার আগে নাল চেক
      price: (json['price'] ?? 0).toDouble(),
      
      imageUrl: json['image_url'] ?? '',
      propertyType: json['property_type'] ?? 'General',

      // ৩. Join Query-র ডাটা ধরার প্রফেশনাল নিয়ম
      // Supabase এ সাধারণত সেলারের তথ্য 'profiles' বা 'users' টেবিল থেকে আসে
      // আপনার টেবিল রিলেশন অনুযায়ী 'sellers' কি-টি চেক করা হয়েছে
      sellerName: _parseSellerName(json),
    );
  }

  // সেলারের নাম পার্স করার জন্য একটি আলাদা হেল্পার মেথড (কোড ক্লিন রাখার জন্য)
  static String? _parseSellerName(Map<String, dynamic> json) {
    if (json['sellers'] != null) {
      // যদি 'sellers' টেবিল থেকে name আসে
      return json['sellers']['full_name'] ?? json['sellers']['name'] ?? 'Unknown Seller';
    }
    return 'Owner';
  }
}