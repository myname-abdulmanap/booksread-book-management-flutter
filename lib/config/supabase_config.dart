import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {

  static const String supabaseUrl = 'https://deibyhkspwxnwlvlncos.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRlaWJ5aGtzcHd4bndsdmxuY29zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgyMjIxNzAsImV4cCI6MjA4Mzc5ODE3MH0.4RGXoHvbrTWXumJO6IxMcfVi9-Lp5IIKlEE-yWO_foI';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}