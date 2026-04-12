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
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name, 'role': role},
    );
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
      return (response as List)
          .map((json) => Property.fromJson(json))
          .toList();
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

  Future<void> updateProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            ...data,
            'updated_at': DateTime.now().toIso8601String(),
          })
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
  // AVATAR UPLOAD - CORRECTED VERSION
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
      
      // Get current session for access token
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('User not authenticated');
      }
      
      final accessToken = session.accessToken;
      final supabaseUrl = 'https://hxkokgzbeqmfdkzzeuex.supabase.co';
      
      debugPrint('📤 Uploading: $storagePath');
      debugPrint('📤 Bytes size: ${bytes.lengthInBytes}B');
      
      // Method 1: Try direct HTTP upload (more reliable)
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
        final responseBody = await streamedResponse.stream.bytesToString();
        
        if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
          // Success - get public URL
          final publicUrl = '$supabaseUrl/storage/v1/object/public/avatars/$storagePath';
          
          // Update profile with avatar URL
          await updateProfile(userId, {'avatar_url': publicUrl});
          
          debugPrint('✅ Upload success (HTTP): $publicUrl');
          return publicUrl;
        } else {
          debugPrint('⚠️ HTTP upload failed: ${streamedResponse.statusCode}');
          debugPrint('Response: $responseBody');
          
          // Fall back to SDK method
          return await _uploadWithSDK(storagePath, bytes, ext, userId);
        }
      } catch (httpError) {
        debugPrint('⚠️ HTTP upload error: $httpError');
        debugPrint('Falling back to SDK method...');
        
        // Fall back to SDK method
        return await _uploadWithSDK(storagePath, bytes, ext, userId);
      }
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      rethrow;
    }
  }
  
  // Fallback upload method using Supabase SDK
  Future<String?> _uploadWithSDK(
    String storagePath,
    Uint8List bytes,
    String ext,
    String userId,
  ) async {
    try {
      final mimeType = _getMimeType(ext);
      
      await _supabase.storage.from('avatars').uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(
          contentType: mimeType,
          upsert: true,
        ),
      );
      
      final supabaseUrl = 'https://hxkokgzbeqmfdkzzeuex.supabase.co';
      final publicUrl = '$supabaseUrl/storage/v1/object/public/avatars/$storagePath';
      
      await updateProfile(userId, {'avatar_url': publicUrl});
      
      debugPrint('✅ Upload success (SDK): $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ SDK upload failed: $e');
      throw Exception('All upload methods failed: $e');
    }
  }

  String _cleanExt(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) return 'jpg';
    final ext = parts.last.toLowerCase().trim().replaceAll(' ', '');
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
  
  // ─────────────────────────────────────────
  // HELPER: Test bucket connection
  // ─────────────────────────────────────────
  
  Future<bool> testStorageConnection() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        debugPrint('❌ No user logged in');
        return false;
      }
      
      final supabaseUrl = 'https://hxkokgzbeqmfdkzzeuex.supabase.co';
      final testUrl = Uri.parse('$supabaseUrl/storage/v1/object/public/avatars/');
      
      final response = await http.get(testUrl);
      debugPrint('Storage test status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        debugPrint('✅ Storage bucket is accessible');
        return true;
      } else {
        debugPrint('❌ Storage bucket not accessible: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Storage test error: $e');
      return false;
    }
  }
}