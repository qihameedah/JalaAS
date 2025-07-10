// lib/main.dart - Mobile Entry Point
import 'package:flutter/material.dart';
import 'package:jala_as/utils/responsive.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseService.initialize();
  } catch (e) {
    print('Failed to initialize Supabase: $e');
  }

  runApp(const Responsive());
}
