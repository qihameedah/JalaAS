// lib/web/web_main.dart - Web Entry Point
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'web_login_screen.dart';
import '../../utils/constants.dart';

class WebApp extends StatelessWidget {
  const WebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${AppConstants.appName} - Web',
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(AppConstants.primaryColor),
        scaffoldBackgroundColor: const Color(AppConstants.backgroundColor),
        fontFamily: GoogleFonts.notoSansArabic().fontFamily,
        textTheme: GoogleFonts.notoSansArabicTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(AppConstants.primaryColor),
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.notoSansArabic(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(AppConstants.primaryColor),
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.notoSansArabic(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(AppConstants.primaryColor),
              width: 2,
            ),
          ),
          labelStyle: GoogleFonts.notoSansArabic(),
        ),
      ),
      home: const WebLoginScreen(),
    );
  }
}
