import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/property_model.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  SupabaseClient get supabaseClient => _supabase;
  User? get currentUser => _supabase.auth.currentUser;

  // ─────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────

  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(
    String email,
    String password,
    String name,
    String role,
  ) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name, 'role': role},
    );

    if (response.user != null) {
      await _createInitialProfile(
        userId: response.user!.id,
        fullName: name,
        email: email,
        role: role,
      );
    }

    return response;
  }

  Future<void> _createInitialProfile({
    required String userId,
    required String fullName,
    required String email,
    required String role,
  }) async {
    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        'full_name': fullName,
        'email': email,
        'role': role,
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      debugPrint('✅ Initial profile created | Email: $email | Role: $role');
    } catch (e) {
      debugPrint('❌ Initial profile error: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.estatex://login-callback/',
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ─────────────────────────────────────────
  // PROPERTIES
  // ─────────────────────────────────────────

  Future<List<Property>> fetchProperties() async {
    try {
      final response = await _supabase.from('properties').select();
      return (response as List).map((json) => Property.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Fetch properties error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────
  // PROFILE — READ
  // ─────────────────────────────────────────

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('Get profile error: $e');
      return null;
    }
  }

  Future<String> getUserRole(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      return data['role'] ?? 'buyer';
    } catch (e) {
      debugPrint('Get user role error: $e');
      return 'buyer';
    }
  }

  Future<Map<String, dynamic>?> getBuyerProfile(String userId) async {
    try {
      final data = await _supabase
          .from('buyer_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('Get buyer profile error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSellerProfile(String userId) async {
    try {
      final data = await _supabase
          .from('seller_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('Get seller profile error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────
  // PROFILE — UPDATE
  // ─────────────────────────────────────────

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from('profiles')
          .update({...data, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> upsertBuyerProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _supabase.from('buyer_profiles').upsert({
        'id': userId,
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save buyer profile: $e');
    }
  }

  Future<void> upsertSellerProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _supabase.from('seller_profiles').upsert({
        'id': userId,
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save seller profile: $e');
    }
  }

  // ─────────────────────────────────────────
  // AVATAR UPLOAD
  // ─────────────────────────────────────────

  Future<String?> uploadAvatar(
    String userId,
    String fileName,
    Uint8List bytes,
  ) async {
    try {
      final ext = _cleanExt(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '${userId}_$timestamp.$ext';

      final session = _supabase.auth.currentSession;
      if (session == null) throw Exception('User not authenticated');

      final accessToken = session.accessToken;
      final supabaseUrl = 'https://hxkokgzbeqmfdkzzeuex.supabase.co';

      // HTTP Upload
      try {
        final uploadUrl = '$supabaseUrl/storage/v1/object/avatars/$storagePath';
        final uri = Uri.parse(uploadUrl);

        final request = http.MultipartRequest('POST', uri);
        request.headers['Authorization'] = 'Bearer $accessToken';
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: storagePath,
            contentType: http.MediaType('image', ext),
          ),
        );

        final streamedResponse = await request.send();

        if (streamedResponse.statusCode == 200 ||
            streamedResponse.statusCode == 201) {
          final publicUrl =
              '$supabaseUrl/storage/v1/object/public/avatars/$storagePath';
          await updateProfile(userId, {'avatar_url': publicUrl});
          debugPrint('✅ Avatar uploaded: $publicUrl');
          return publicUrl;
        }
      } catch (_) {}

      // Fallback to SDK
      return await _uploadWithSDK(storagePath, bytes, ext, userId);
    } catch (e) {
      debugPrint('❌ Avatar upload error: $e');
      rethrow;
    }
  }

  Future<String?> _uploadWithSDK(
    String storagePath,
    Uint8List bytes,
    String ext,
    String userId,
  ) async {
    try {
      final mimeType = _getMimeType(ext);

      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      final supabaseUrl = 'https://hxkokgzbeqmfdkzzeuex.supabase.co';
      final publicUrl =
          '$supabaseUrl/storage/v1/object/public/avatars/$storagePath';

      await updateProfile(userId, {'avatar_url': publicUrl});
      return publicUrl;
    } catch (e) {
      debugPrint('❌ SDK upload failed: $e');
      throw Exception('Upload failed: $e');
    }
  }

  // ─────────────────────────────────────────
  // PROPERTY IMAGES UPLOAD
  // ─────────────────────────────────────────

  Future<List<String>> uploadPropertyImages(
    String userId,
    List<Map<String, dynamic>> imageFiles,
  ) async {
    List<String> publicUrls = [];

    if (imageFiles.isEmpty) return publicUrls;

    final supabaseUrl = 'https://hxkokgzbeqmfdkzzeuex.supabase.co';
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('User not authenticated');

    for (int i = 0; i < imageFiles.length; i++) {
      final img = imageFiles[i];
      final String originalName = img['name'] ?? 'property_$i.jpg';
      final Uint8List bytes = img['bytes'] as Uint8List;

      try {
        final ext = _cleanExt(originalName);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final String fileName = '${userId}_${timestamp}_$i.$ext';
        final String path = fileName;

        final uploadUrl =
            '$supabaseUrl/storage/v1/object/property_images/$path';
        final uri = Uri.parse(uploadUrl);

        final request = http.MultipartRequest('POST', uri);
        request.headers['Authorization'] = 'Bearer ${session.accessToken}';
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
            contentType: http.MediaType('image', ext),
          ),
        );

        final streamedResponse = await request.send();

        if (streamedResponse.statusCode == 200 ||
            streamedResponse.statusCode == 201) {
          final publicUrl =
              '$supabaseUrl/storage/v1/object/public/property_images/$path';
          publicUrls.add(publicUrl);
          debugPrint('✅ Property image uploaded: $publicUrl');
        } else {
          throw Exception('HTTP upload failed: ${streamedResponse.statusCode}');
        }
      } catch (e) {
        debugPrint('❌ Property image $i upload failed: $e');
      }
    }

    return publicUrls;
  }

  // ─────────────────────────────────────────
  // BID PROPERTIES
  // ─────────────────────────────────────────

  Future<List<String>> uploadBidPropertyImages(
    String userId,
    List<Map<String, dynamic>> imageFiles,
  ) async {
    List<String> publicUrls = [];

    if (imageFiles.isEmpty) return publicUrls;

    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('User not authenticated');

    final supabaseUrl = 'https://hxkokgzbeqmfdkzzeuex.supabase.co';

    for (int i = 0; i < imageFiles.length; i++) {
      final img = imageFiles[i];
      final String originalName = img['name'] ?? 'bid_$i.jpg';
      final Uint8List bytes = img['bytes'] as Uint8List;

      try {
        final ext = _cleanExt(originalName);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final String fileName = '${userId}_${timestamp}_$i.$ext';

        final uploadUrl =
            '$supabaseUrl/storage/v1/object/bid_properties/$fileName';
        final uri = Uri.parse(uploadUrl);

        final request = http.MultipartRequest('POST', uri);
        request.headers['Authorization'] = 'Bearer ${session.accessToken}';
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
            contentType: http.MediaType('image', ext),
          ),
        );

        final streamedResponse = await request.send();

        if (streamedResponse.statusCode == 200 ||
            streamedResponse.statusCode == 201) {
          final publicUrl =
              '$supabaseUrl/storage/v1/object/public/bid_properties/$fileName';
          publicUrls.add(publicUrl);
          debugPrint('✅ Bid image $i uploaded successfully');
        }
      } catch (e) {
        debugPrint('❌ Image $i upload error: $e');
      }
    }
    return publicUrls;
  }

  // Create Bid Property
  Future<bool> createBidProperty({
    required String title,
    required String location,
    String? description,
    required double basePrice,
    required double area,
    required String propertyType,
    int? bedrooms,
    int? bathrooms,
    double? plotSize,
    int? parkingSpaces,
    required List<Map<String, dynamic>> imageFiles,
    required DateTime endTime,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final imageUrls = await uploadBidPropertyImages(user.id, imageFiles);

      final data = {
        'seller_id': user.id,
        'title': title,
        'location': location,
        'description': description,
        'base_price': basePrice,
        'current_highest_bid': basePrice,
        'highest_bidder_id': null,
        'area': area,
        'property_type': propertyType,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'plot_size': plotSize,
        'parking_spaces': parkingSpaces,
        'image_urls': imageUrls,
        'end_time': endTime.toIso8601String(),
        'is_active': true,
        'is_verified': false,
        'bid_count': 0,
      };

      await _supabase.from('bid_properties').insert(data);

      debugPrint('✅ Bid Property Created Successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Create Bid Property Error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────
  // HELPER METHODS
  // ─────────────────────────────────────────

  String _cleanExt(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) return 'jpg';
    final ext = parts.last.toLowerCase().trim();
    const valid = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
    return valid.contains(ext) ? ext : 'jpg';
  }

  String _getMimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  // ===================== MY BID PROPERTIES =====================

  Future<List<dynamic>> fetchMyBidProperties() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('bid_properties')
          .select()
          .eq('seller_id', user.id)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      debugPrint('❌ Fetch My Bid Properties Error: $e');
      return [];
    }
  }

  Future<bool> updateBidProperty({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _supabase
          .from('bid_properties')
          .update({...data, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      debugPrint('✅ Bid Property Updated');
      return true;
    } catch (e) {
      debugPrint('❌ Update Bid Property Error: $e');
      rethrow;
    }
  }

  Future<bool> deleteBidProperty(String id) async {
    try {
      await _supabase.from('bid_properties').delete().eq('id', id);
      debugPrint('✅ Bid Property Deleted');
      return true;
    } catch (e) {
      debugPrint('❌ Delete Bid Property Error: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> fetchActiveBidProperties() async {
    try {
      final response = await _supabase
          .from('bid_properties')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      debugPrint('❌ Fetch Active Bid Properties Error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────
  // BID RELATED - FIXED
  // ─────────────────────────────────────────

  /// Highest Bidder Profile
  Future<Map<String, dynamic>?> getUserProfile({required String userId}) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('id, full_name, email, avatar_url')
          .eq('id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('Get user profile error: $e');
      return null;
    }
  }

  /// ✅ Fixed - Total Bids Count
  Future<int> getBidCount({required String bidPropertyId}) async {
    try {
      final response = await _supabase
          .from('bids')
          .select('id')
          .eq('bid_property_id', bidPropertyId);

      return (response as List).length;
    } catch (e) {
      debugPrint('Get bid count error: $e');
      return 0;
    }
  }

  /// ✅ Fixed Place Bid - bids table + bid_properties update
  Future<bool> placeBid({
    required String bidPropertyId,
    required double bidAmount,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Check current highest bid
      final current = await _supabase
          .from('bid_properties')
          .select('current_highest_bid')
          .eq('id', bidPropertyId)
          .maybeSingle();

      if (current == null) throw Exception('Property not found');

      if (bidAmount <= (current['current_highest_bid'] ?? 0)) {
        throw Exception('Bid must be higher than current highest bid');
      }

      // Insert into bids history table
      await _supabase.from('bids').insert({
        'bid_property_id': bidPropertyId,
        'bidder_id': user.id,
        'bid_amount': bidAmount,
      });

      // Update main property
      await _supabase
          .from('bid_properties')
          .update({
            'current_highest_bid': bidAmount,
            'highest_bidder_id': user.id,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bidPropertyId);

      debugPrint('✅ Bid placed successfully! Amount: ৳$bidAmount');
      return true;
    } catch (e) {
      debugPrint('❌ Place Bid Error: $e');
      rethrow;
    }
  }
  // ─────────────────────────────────────────
  // FAVORITES
  // ─────────────────────────────────────────

  Future<bool> addToFavorite(String propertyId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _supabase.from('favorites').insert({
        'user_id': user.id,
        'property_id': propertyId,
      });

      debugPrint('✅ Added to favorite: $propertyId');
      return true;
    } catch (e) {
      debugPrint('❌ Add to favorite error: $e');
      return false;
    }
  }

  Future<bool> removeFromFavorite(String propertyId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('property_id', propertyId);

      debugPrint('✅ Removed from favorite: $propertyId');
      return true;
    } catch (e) {
      debugPrint('❌ Remove from favorite error: $e');
      return false;
    }
  }

  Future<bool> isFavorite(String propertyId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('favorites')
          .select()
          .eq('user_id', user.id)
          .eq('property_id', propertyId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('❌ Check favorite error: $e');
      return false;
    }
  }

  Future<List<Property>> getFavoriteProperties() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('favorites')
          .select('*, properties(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List favorites = response as List;

      return favorites.map((fav) {
        return Property.fromJson(fav['properties'] as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('❌ Fetch favorites error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────
  // BID HISTORY FOR SELLER
  // ─────────────────────────────────────────

  Future<List<dynamic>> getBidHistoryForSeller({
    required String bidPropertyId,
  }) async {
    try {
      final response = await _supabase
          .from('bids')
          .select('*, profiles!bidder_id(full_name, avatar_url, email)')
          .eq('bid_property_id', bidPropertyId)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      debugPrint('Get bid history error: $e');
      return [];
    }
  }
  // ─────────────────────────────────────────
  // BOOKING REQUESTS (FIXED & ALIGNED VERSION)
  // ─────────────────────────────────────────

  /// ✅ 1. Create a Booking Request (Buyer trigger points - 'message' field excluded)
  Future<bool> createBookingRequest({
    required String propertyId,
    required String sellerId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final data = {
        'property_id': propertyId,
        'buyer_id': user.id,
        'seller_id': sellerId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // 'message' column chara safely insert hobe PGRST204 error bad diye
      await _supabase.from('booking_requests').insert(data);
      debugPrint('✅ Booking Request Sent Successfully!');
      return true;
    } catch (e) {
      debugPrint('❌ Create Booking Request Error: $e');
      return false;
    }
  }

  /// ✅ 2. Fetch Booking Requests for Seller (With Profiles relational parsing)
  Future<List<Map<String, dynamic>>> fetchSellersBookingRequests() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Seller page er explicit structural inner join filtering mapping query
      final response = await _supabase
          .from('booking_requests')
          .select('''
            id,
            status,
            created_at,
            buyer_id,
            profiles!buyer_id(full_name, email, role, city, area), 
            properties(id, title, price, location, image_urls)
          ''')
          .eq('seller_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Fetch Seller Bookings Error: $e');
      return [];
    }
  }

  /// ✅ 3. Fetch Booking Requests for Buyer (To trace records or status updates)
  Future<List<Map<String, dynamic>>> fetchBuyersBookingRequests() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('booking_requests')
          .select('*, properties(*)')
          .eq('buyer_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Fetch Buyer Bookings Error: $e');
      return [];
    }
  }

  /// ✅ 4. Dynamic Status State Update (Handles Seller Approved/Reject/Pending & Buyer Cancellation)
  Future<bool> updateBookingStatus({
    required String bookingId,
    required String
    nextStatus, // 'approved', 'rejected', 'pending', 'cancelled'
  }) async {
    try {
      await _supabase
          .from('booking_requests')
          .update({
            'status': nextStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId);

      debugPrint('✅ Booking status successfully updated to: $nextStatus');
      return true;
    } catch (e) {
      debugPrint('❌ Update Booking Status Error: $e');
      return false;
    }
  }
  // ─────────────────────────────────────────
  // BUYER - MY BIDS
  // ─────────────────────────────────────────

  /// Fetch all bids placed by current buyer
  Future<List<Map<String, dynamic>>> fetchMyBids() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('bids')
          .select('''
            id,
            bid_amount,
            created_at,
            bid_property_id,
            bid_properties!bid_property_id (
              id, 
              title, 
              location, 
              base_price,
              current_highest_bid,
              image_urls,
              end_time,
              is_active
            )
          ''')
          .eq('bidder_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Fetch My Bids Error: $e');
      return [];
    }
  }

  Future<int> getMyBidsCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      final response = await _supabase
          .from('bids')
          .select('id')
          .eq('bidder_id', user.id);

      return (response as List).length;
    } catch (e) {
      debugPrint('❌ Get My Bids Count Error: $e');
      return 0;
    }
  }

  // ─────────────────────────────────────────
  // ALL BID HISTORY FOR PUBLIC / BUYER / ADMIN
  // ─────────────────────────────────────────

  /// নির্দিষ্ট একটি প্রপার্টির সম্পূর্ণ বিড হিস্ট্রি নিয়ে আসে (সবাই দেখতে পারবে)
  Future<List<dynamic>> getAllBidHistoryForProperty({
    required String bidPropertyId,
  }) async {
    try {
      final response = await _supabase
          .from('bids')
          .select('*, profiles!bidder_id(full_name, avatar_url, email)')
          .eq('bid_property_id', bidPropertyId)
          .order('bid_amount', ascending: false); // সর্বোচ্চ বিড আগে দেখাবে

      return response;
    } catch (e) {
      debugPrint('Get all bid history error: $e');
      return [];
    }
  }

  // ===================== ADMIN METHODS =====================

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*, buyer_profiles(*), seller_profiles(*)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get all users error: $e');
      return [];
    }
  }

  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            'role': newRole,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleUserBan(String userId, bool isBanned) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            'is_active': !isBanned,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUserAccount(String userId) async {
    try {
      await _supabase.from('profiles').delete().eq('id', userId);
      await _supabase.from('buyer_profiles').delete().eq('id', userId);
      await _supabase.from('seller_profiles').delete().eq('id', userId);
      // Optional: Delete auth user (needs service role)
      return true;
    } catch (e) {
      debugPrint('Delete user error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAllBookingRequests() async {
    try {
      final response = await _supabase
          .from('booking_requests')
          .select('''
            *,
            profiles!buyer_id(full_name, avatar_url, email),
            properties(id, title, location, price, image_urls)
          ''')
          .order('created_at', ascending: false);
      debugPrint("✅ Fetched ${response.length} booking requests");
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Get all booking requests error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────
  // PROPERTIES — ADMIN UPDATED METHODS
  // ─────────────────────────────────────────

  // প্রপার্টির সাথে সেলারের নাম, প্রোফাইল পিকচার এবং ইমেইল একসাথে তুলে আনার জন্য মেথড
 Future<List<dynamic>> getAllProperties() async {
    try {
      final response = await _supabase
          .from('properties')
          .select('*, profiles!seller_id(full_name, avatar_url, email, role)')
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      debugPrint('❌ Get all properties error: $e');
      return [];
    }
  }
  Future<bool> deleteProperty(dynamic propertyId) async {
    try {
      // ID যদি int হয় তবে int-এ কনভার্ট করবে, নাহলে string/uuid রাখবে
      final targetId = int.tryParse(propertyId.toString()) ?? propertyId;
      
      await _supabase.from('properties').delete().eq('id', targetId);
      debugPrint('✅ Property deleted successfully from DB');
      return true;
    } catch (e) {
      debugPrint('❌ Delete property error: $e');
      return false;
    }
  }

  // অ্যাডমিন প্যানেল থেকে নতুন প্রপার্টি সরাসরি ডেটাবেজে ইনসার্ট করার জন্য
  Future<bool> createPropertyAdmin(Map<String, dynamic> data) async {
    try {
      await _supabase.from('properties').insert({
        'seller_id': data['seller_id'],
        'title': data['title'],
        'location': data['location'],
        'description': data['description'],
        'price': data['price'],
        'property_type': data['property_type'],
        'image_urls': data['image_urls'] ?? [],
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('❌ Admin Create Property Error: $e');
      return false;
    }
  }

  // অ্যাডমিন প্যানেল থেকে বিদ্যমান প্রপার্টি আপডেট করার জন্য
  Future<bool> updatePropertyAdmin(String propertyId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('properties').update({
        'title': data['title'],
        'location': data['location'],
        'description': data['description'],
        'price': data['price'],
        'property_type': data['property_type'],
        'image_urls': data['image_urls'] ?? [],
      }).eq('id', propertyId);
      return true;
    } catch (e) {
      debugPrint('❌ Admin Update Property Error: $e');
      return false;
    }
  }
  
  // প্রপার্টির সাথে সেলার প্রোফাইল ডাটা আনার ফিক্সড মেথড
  Future<List<dynamic>> getAllBidProperties() async {
    try {
      final response = await _supabase
          .from('bid_properties')
          .select('*, profiles!seller_id(full_name, avatar_url, email, role)')
          .order('created_at', ascending: false);
      debugPrint("✅ Fetched ${response.length} bid properties");
      return response;
    } catch (e) {
      debugPrint('❌ Get all bid properties error: $e');
      return [];
    }
  }

  // Admin Update Bid Property (UUID String-ভিত্তিক)
  Future<bool> updateBidPropertyAdmin(String id, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from('bid_properties')
          .update({...data, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      debugPrint('✅ Bid Property Updated by Admin');
      return true;
    } catch (e) {
      debugPrint('❌ Admin Update Bid Property Error: $e');
      return false;
    }
  }

  // Admin Delete Bid Property
  Future<bool> deleteBidPropertyAdmin(String id) async {
    try {
      await _supabase.from('bid_properties').delete().eq('id', id);
      debugPrint('✅ Bid Property Deleted by Admin');
      return true;
    } catch (e) {
      debugPrint('❌ Admin Delete Bid Property Error: $e');
      return false;
    }
  }
}
