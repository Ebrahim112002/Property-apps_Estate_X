import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/property_model.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  // সব প্রপার্টি এবং তাদের সেলারের তথ্য একসাথে আনা
  Future<List<Property>> fetchProperties() async {
    try {
      final List<dynamic> response = await _client
          .from('properties')
          .select('*, sellers(name)') // Join query with sellers table
          .order('created_at', ascending: false);
      
      return response.map((item) => Property.fromJson(item)).toList();
    } catch (e) {
      print('Supabase Fetch Error: $e');
      throw Exception('Failed to load properties');
    }
  }

  // টাইপ অনুযায়ী ফিল্টার (যেমন: শুধু 'Land' অথবা 'Flat')
  Future<List<Property>> fetchPropertiesByType(String type) async {
    try {
      final List<dynamic> response = await _client
          .from('properties')
          .select('*, sellers(name)')
          .eq('property_type', type)
          .order('created_at', ascending: false);
      
      return response.map((item) => Property.fromJson(item)).toList();
    } catch (e) {
      print('Filter Fetch Error: $e');
      return [];
    }
  }
}