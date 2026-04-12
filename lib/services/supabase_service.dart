import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  Future<bool> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(
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
  // AVATAR UPLOAD
  // Flat path: userId.ext (upsert=true → auto-replace)
  // Bucket RLS এ authenticated INSERT policy থাকতে হবে
  // ─────────────────────────────────────────

  Future<String?> uploadAvatar(
    String userId,
    String fileName,
    Uint8List bytes,
  ) async {
    try {
      final ext = _cleanExt(fileName);
      final mimeType = _getMimeType(ext);

      // Flat path — folder নেই, শুধু userId.ext
      // upsert: true → same path এ upload করলে replace হবে
      final storagePath = '$userId.$ext';

      debugPrint(
          '📤 Uploading: $storagePath | $mimeType | ${bytes.lengthInBytes}B');

      await _supabase.storage.from('avatars').uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );

      final ts = DateTime.now().millisecondsSinceEpoch;
      final publicUrl =
          _supabase.storage.from('avatars').getPublicUrl(storagePath);
      final finalUrl = '$publicUrl?v=$ts';

      debugPrint('✅ Upload success → $finalUrl');

      await updateProfile(userId, {'avatar_url': finalUrl});

      return finalUrl;
    } on StorageException catch (e) {
      debugPrint('❌ StorageException [${e.statusCode}]: ${e.message}');
      // এই error মানে RLS policy নেই
      // Supabase SQL Editor এ নিচের query run করো:
      // CREATE POLICY "avatar_upload" ON storage.objects
      // FOR INSERT TO authenticated
      // WITH CHECK (bucket_id = 'avatars');
      throw Exception('Storage error (${e.statusCode}): ${e.message}');
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      rethrow;
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
}