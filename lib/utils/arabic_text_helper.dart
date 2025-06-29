// lib/utils/arabic_text_helper.dart
import 'package:intl/intl.dart';

class ArabicTextHelper {
  // Unicode characters that can cause display issues
  static const List<String> problematicChars = [
    '\u202A', // Left-to-Right Embedding
    '\u202B', // Right-to-Left Embedding
    '\u202C', // Pop Directional Formatting
    '\u202D', // Left-to-Right Override
    '\u202E', // Right-to-Left Override
    '\u200E', // Left-to-Right Mark
    '\u200F', // Right-to-Left Mark
    '\u061C', // Arabic Letter Mark
  ];

  static String cleanText(String text) {
    String cleaned = text;

    // Remove problematic Unicode characters
    for (String char in problematicChars) {
      cleaned = cleaned.replaceAll(char, '');
    }

    // Remove extra whitespaces
    cleaned = cleaned.trim().replaceAll(RegExp(r'\s+'), ' ');

    return cleaned;
  }

  static String extractDocumentNumber(String shownParent) {
    String cleaned = cleanText(shownParent);

    // Remove common Arabic document type suffixes
    cleaned = cleaned.replaceAll(
        RegExp(
            r'\s*(ف\.مبيعات|ف\.يدوية|م\.\s*مبيعات|م\.مبيعات|قبض يدوي|قبض)\s*'),
        '');

    return cleaned.trim();
  }

  static bool isArabicText(String text) {
    // Check if text contains Arabic characters
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  static String formatArabicNumber(double number) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(number);
  }

  static String reverseForRTL(String text) {
    // For specific cases where text direction needs manual handling
    return text.split('').reversed.join('');
  }

  static String normalizeArabicText(String text) {
    String normalized = cleanText(text);

    // Normalize Arabic characters
    normalized = normalized
        .replaceAll('ي', 'ى') // Normalize Yeh
        .replaceAll('ة', 'ه') // Normalize Teh Marbuta
        .replaceAll('أ', 'ا') // Normalize Alef with Hamza
        .replaceAll('إ', 'ا') // Normalize Alef with Hamza below
        .replaceAll('آ', 'ا'); // Normalize Alef with Madda

    return normalized;
  }
}
