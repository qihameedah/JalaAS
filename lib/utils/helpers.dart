// lib/utils/helpers.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:jala_as/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui' as ui;

class Helpers {
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  static String formatDisplayDate(DateTime date) {
    return DateFormat(AppConstants.displayDateFormat).format(date);
  }

  static DateTime? parseDate(String dateStr) {
    try {
      return DateFormat(AppConstants.dateFormat).parse(dateStr);
    } catch (e) {
      return null;
    }
  }

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

  static Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  static Future<void> savePinCode(String pinCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.pinCodeKey, pinCode);
  }

  static Future<String?> getPinCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.pinCodeKey);
  }

  static Future<bool> hasPinCode() async {
    final pinCode = await getPinCode();
    return pinCode != null && pinCode.isNotEmpty;
  }

  static Future<void> setLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.isLoggedInKey, isLoggedIn);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.isLoggedInKey) ?? false;
  }

  static Future<void> updateLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      AppConstants.lastActiveTimeKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<bool> shouldRequirePin() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActiveTime = prefs.getInt(AppConstants.lastActiveTimeKey);

    if (lastActiveTime == null) return true;

    final now = DateTime.now().millisecondsSinceEpoch;
    final timeDifference = now - lastActiveTime;
    final minutesDifference = timeDifference / (1000 * 60);

    return minutesDifference > AppConstants.backgroundTimeoutMinutes;
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userDataKey, json.encode(userData));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString(AppConstants.userDataKey);

    if (userDataStr != null) {
      return json.decode(userDataStr);
    }

    return null;
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userDataKey);
    await prefs.remove(AppConstants.isLoggedInKey);
  }

  static String getDocumentTypeInArabic(String documentType) {
    switch (documentType) {
      case 'invoice':
        return 'فاتورة';
      case 'return':
        return 'مرتجع';
      case 'payment':
        return 'قبض';
      default:
        return 'مستند';
    }
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  static bool isValidPinCode(String pinCode) {
    return pinCode.length == AppConstants.pinLength &&
        RegExp(r'^\d+$').hasMatch(pinCode);
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static void showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: ui.TextDirection.rtl,
        ),
        backgroundColor: isError
            ? const Color(AppConstants.errorColor)
            : const Color(AppConstants.primaryColor),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
