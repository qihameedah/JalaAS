// lib/utils/helpers.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:jala_as/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:async';

class Helpers {
  // Date Formatting Methods
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  static String formatDisplayDate(DateTime date) {
    return DateFormat(AppConstants.displayDateFormat).format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.dateTimeFormat).format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat(AppConstants.timeFormat).format(dateTime);
  }

  static DateTime? parseDate(String dateStr) {
    try {
      return DateFormat(AppConstants.dateFormat).parse(dateStr);
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }

  // Number Formatting Methods
  static String formatNumber(String numberStr) {
    if (numberStr.isEmpty) return '-';

    try {
      final number = double.parse(numberStr.replaceAll(',', ''));
      final formatter = NumberFormat('#,##0.00');
      return formatter.format(number);
    } catch (e) {
      return numberStr;
    }
  }

  static double parseNumber(String numberStr) {
    if (numberStr.isEmpty) return 0;

    try {
      return double.parse(numberStr.replaceAll(',', ''));
    } catch (e) {
      return 0;
    }
  }

  // Internet Connection Methods
  static Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Additional check by trying to reach a reliable host
      try {
        final result = await InternetAddress.lookup('google.com');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        return false;
      }
    } catch (e) {
      print('Error checking internet connection: $e');
      return false;
    }
  }

  // PIN Code Methods - Enhanced with Security
  static Future<void> savePinCode(String pinCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Hash the PIN for security
      final hashedPin = _hashPin(pinCode);
      await prefs.setString(AppConstants.pinCodeKey, hashedPin);
    } catch (e) {
      print('Error saving PIN code: $e');
      throw Exception('Failed to save PIN code');
    }
  }

  static Future<String?> getPinCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.pinCodeKey);
    } catch (e) {
      print('Error getting PIN code: $e');
      return null;
    }
  }

  static Future<bool> hasPinCode() async {
    try {
      final pinCode = await getPinCode();
      return pinCode != null && pinCode.isNotEmpty;
    } catch (e) {
      print('Error checking PIN code: $e');
      return false;
    }
  }

  static Future<bool> verifyPin(String enteredPin) async {
    try {
      final storedHashedPin = await getPinCode();
      if (storedHashedPin == null) return false;

      final enteredHashedPin = _hashPin(enteredPin);
      return storedHashedPin == enteredHashedPin;
    } catch (e) {
      print('Error verifying PIN: $e');
      return false;
    }
  }

  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Login Status Methods - Enhanced
  static Future<void> setLoggedIn(bool isLoggedIn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.isLoggedInKey, isLoggedIn);

      if (isLoggedIn) {
        await updateLastActiveTime();
      }
    } catch (e) {
      print('Error setting login status: $e');
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AppConstants.isLoggedInKey) ?? false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Activity Time Methods - Enhanced
  static Future<void> updateLastActiveTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        AppConstants.lastActiveTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print('Error updating last active time: $e');
    }
  }

  static Future<DateTime?> getLastActiveTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(AppConstants.lastActiveTimeKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      print('Error getting last active time: $e');
      return null;
    }
  }

  static Future<bool> shouldRequirePin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActiveTime = prefs.getInt(AppConstants.lastActiveTimeKey);

      if (lastActiveTime == null) return true;

      final now = DateTime.now().millisecondsSinceEpoch;
      final timeDifference = now - lastActiveTime;
      final minutesDifference = timeDifference / (1000 * 60);

      return minutesDifference > AppConstants.backgroundTimeoutMinutes;
    } catch (e) {
      print('Error checking if PIN required: $e');
      return true; // Default to requiring PIN for security
    }
  }

  // User Data Methods - Enhanced
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userDataKey, json.encode(userData));
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString(AppConstants.userDataKey);

      if (userDataStr != null) {
        return json.decode(userDataStr);
      }

      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userDataKey);
      await prefs.remove(AppConstants.isLoggedInKey);
      await prefs.remove(AppConstants.lastActiveTimeKey);
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  static Future<void> saveUserToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userTokenKey, token);
    } catch (e) {
      print('Error saving user token: $e');
    }
  }

  static Future<String?> getUserToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.userTokenKey);
    } catch (e) {
      print('Error getting user token: $e');
      return null;
    }
  }

  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error clearing all data: $e');
    }
  }

  // Document Type Translation
  static String getDocumentTypeInArabic(String documentType) {
    switch (documentType.toLowerCase()) {
      case 'invoice':
        return 'فاتورة';
      case 'return':
        return 'مرتجع';
      case 'payment':
        return 'قبض';
      case 'receipt':
        return 'إيصال';
      case 'credit':
        return 'دائن';
      case 'debit':
        return 'مدين';
      default:
        return 'مستند';
    }
  }

  // Validation Methods - Enhanced
  static bool isValidEmail(String email) {
    return RegExp(AppConstants.emailPattern).hasMatch(email);
  }

  static bool isValidPinCode(String pinCode) {
    return pinCode.length == AppConstants.pinLength &&
        RegExp(r'^\d+$').hasMatch(pinCode);
  }

  static bool isValidPassword(String password) {
    return password.length >= AppConstants.minPasswordLength &&
        password.length <= AppConstants.maxPasswordLength;
  }

  static bool isValidUsername(String username) {
    return username.length >= AppConstants.minUsernameLength &&
        username.length <= AppConstants.maxUsernameLength &&
        RegExp(AppConstants.usernamePattern).hasMatch(username);
  }

  static bool isValidPhoneNumber(String phone) {
    return RegExp(AppConstants.phonePattern).hasMatch(phone);
  }

  // Form Validation Methods
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    if (!isValidEmail(email)) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (!isValidPassword(password)) {
      return 'كلمة المرور يجب أن تكون بين ${AppConstants.minPasswordLength} و ${AppConstants.maxPasswordLength} أحرف';
    }
    return null;
  }

  static String? validatePin(String? pin) {
    if (pin == null || pin.isEmpty) {
      return 'رمز PIN مطلوب';
    }
    if (!isValidPinCode(pin)) {
      return 'رمز PIN يجب أن يكون ${AppConstants.pinLength} أرقام';
    }
    return null;
  }

  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'اسم المستخدم مطلوب';
    }
    if (!isValidUsername(username)) {
      return 'اسم المستخدم يجب أن يكون بين ${AppConstants.minUsernameLength} و ${AppConstants.maxUsernameLength} أحرف';
    }
    return null;
  }

  // Text Utilities
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String removeExtraSpaces(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // UI Helper Methods - Enhanced
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: ui.TextDirection.rtl,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError
            ? const Color(AppConstants.errorColor)
            : const Color(AppConstants.primaryColor),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
        action: action,
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      isError: false,
      duration: AppConstants.shortSnackBarDuration,
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      isError: true,
      duration: AppConstants.longSnackBarDuration,
    );
  }

  static void showLoadingDialog(BuildContext context, {String? message}) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(AppConstants.primaryColor),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppConstants.mediumSpacing),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  textDirection: ui.TextDirection.rtl,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
  }) async {
    if (!context.mounted) return null;

    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          title: Text(
            title,
            textDirection: ui.TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            textDirection: ui.TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  // Utility Methods
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'صباح الخير';
    } else if (hour < 17) {
      return 'مساء الخير';
    } else {
      return 'مساء الخير';
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'paid':
      case 'completed':
        return const Color(AppConstants.successColor);
      case 'inactive':
      case 'unpaid':
      case 'pending':
        return const Color(AppConstants.warningColor);
      case 'cancelled':
      case 'failed':
        return const Color(AppConstants.errorColor);
      default:
        return const Color(AppConstants.primaryColor);
    }
  }

  static IconData getDocumentTypeIcon(String documentType) {
    switch (documentType.toLowerCase()) {
      case 'invoice':
        return Icons.receipt_long;
      case 'return':
        return Icons.keyboard_return;
      case 'payment':
        return Icons.payment;
      case 'receipt':
        return Icons.receipt;
      default:
        return Icons.description;
    }
  }

  // Performance Utilities
  static void debounce(VoidCallback action, Duration delay) {
    Timer? timer;
    timer?.cancel();
    timer = Timer(delay, action);
  }

  // Debug Utilities
  static void logDebug(String message) {
    if (AppConstants.enableLogging) {
      print('[DEBUG] $message');
    }
  }

  static void logError(String message, [dynamic error]) {
    if (AppConstants.enableLogging) {
      print('[ERROR] $message');
      if (error != null) {
        print('[ERROR] Details: $error');
      }
    }
  }
}

// Timer extension for debounce functionality
