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
  // PROPERTY IMAGES UPLOAD (NEW)
  // ─────────────────────────────────────────

  /// Multiple images upload for properties
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

        // Try HTTP Upload first (same as avatar)
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
        // Continue with other images
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
        } else {
          debugPrint('❌ Upload failed: ${streamedResponse.statusCode}');
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

  Future<bool> placeBid({
    required String bidPropertyId,
    required double bidAmount,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _supabase
          .from('bid_properties')
          .update({
            'current_highest_bid': bidAmount,
            'highest_bidder_id': user.id,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bidPropertyId);

      debugPrint('✅ Bid placed: $bidAmount on $bidPropertyId by ${user.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Place Bid Error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────
  // FAVORITES
  // ─────────────────────────────────────────

  /// Add Property to Favorite
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

  /// Remove Property from Favorite
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

  /// Check if Property is already in Favorite
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

  /// Get All Favorite Properties of Current User
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
}
