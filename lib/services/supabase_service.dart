import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/property_model.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  // properties ডাটা ফেচ করা
  Future<List<Property>> fetchProperties() async {
    try {
      final response = await _supabase.from('properties').select();
      return (response as List).map((json) => Property.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // ইউজার সাইন ইন
  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // ইউজার সাইন আপ (মেটাডাটাসহ)
  Future<AuthResponse> signUp(String email, String password, String name, String role) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name, 'role': role},
    );
  }

  // গুগল সাইন ইন
  Future<bool> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.estatex://login-callback/',
    );
  }
  // lib/services/supabase_service.dart ফাইলে এটি যোগ করুন
Future<void> signOut() async {
  await Supabase.instance.client.auth.signOut();
}

  // ইউজার রোল দেখা
  Future<String> getUserRole(String userId) async {
    try {
      final data = await _supabase.from('profiles').select('role').eq('id', userId).single();
      return data['role'] ?? 'buyer';
    } catch (e) {
      return 'buyer';
    }
  }
}