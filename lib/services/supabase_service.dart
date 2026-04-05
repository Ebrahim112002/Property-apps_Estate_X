import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // বর্তমান ইউজার সেশন চেক করা
  User? get currentUser => _supabase.auth.currentUser;

  // রেজিস্ট্রেশন (Sign Up)
  Future<AuthResponse> signUp(String email, String password) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  // লগইন (Sign In)
  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // লগআউট (Sign Out)
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ইউজারের রোল (Admin/Seller/Buyer) ডাটাবেস থেকে নিয়ে আসা
  Future<String> getUserRole(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();
    return response['role'] ?? 'buyer';
  }
}