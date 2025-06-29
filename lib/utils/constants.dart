// lib/utils/constants.dart
class AppConstants {
  static const String appName = 'جالا - كشف الحساب';
  static const String supabaseUrl =
      'https://ykwnsmyvkwjctidhoqib.supabase.co'; // Replace with your URL
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlrd25zbXl2a3dqY3RpZGhvcWliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTExOTkzMzYsImV4cCI6MjA2Njc3NTMzNn0.W6WYYc-s24kX2H_-9bvWe1nG31lDlFCSVnDSqIKD5xk'; // Replace with your key

  // Shared Preferences Keys
  static const String pinCodeKey = 'pin_code';
  static const String isLoggedInKey = 'is_logged_in';
  static const String lastActiveTimeKey = 'last_active_time';
  static const String userDataKey = 'user_data';

  // App Settings
  static const int pinLength = 4;
  static const int backgroundTimeoutMinutes = 5;

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String displayDateFormat = 'dd/MM/yyyy';

  // Colors
  static const primaryColor = 0xFF2196F3;
  static const secondaryColor = 0xFF03DAC6;
  static const errorColor = 0xFFB00020;
  static const backgroundColor = 0xFFF5F5F5;
}
