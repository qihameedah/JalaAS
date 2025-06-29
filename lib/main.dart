// lib/main.dart - Mobile Entry Point
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/supabase_service.dart';
import 'screens/mobile/pin_setup_screen.dart';
import 'screens/mobile/pin_enter_screen.dart';
import 'screens/mobile/login_screen.dart';
import 'screens/mobile/contact_selection_screen.dart';
import 'screens/mobile/no_internet_screen.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseService.initialize();
  } catch (e) {
    print('Failed to initialize Supabase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
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
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer>
    with WidgetsBindingObserver {
  bool _hasInternet = true;
  bool _isNavigating = false; // Prevent multiple navigation calls

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _checkAppResume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      Helpers.updateLastActiveTime();
    }
  }

  Future<void> _checkInitialState() async {
    if (_isNavigating || !mounted) return;

    try {
      // Check internet connection
      _hasInternet = await Helpers.hasInternetConnection();

      if (!mounted) return;

      if (!_hasInternet) {
        _navigateToNoInternet();
        return;
      }

      // Check if PIN is required
      final shouldRequirePin = await Helpers.shouldRequirePin();
      final hasPinCode = await Helpers.hasPinCode();

      if (!mounted) return;

      if (!hasPinCode) {
        _navigateToPinSetup();
      } else if (shouldRequirePin) {
        _navigateToPinEntry();
      } else {
        _checkLoginStatus();
      }
    } catch (e) {
      print('Error in _checkInitialState: $e');
      if (mounted) {
        // Fallback to login screen in case of error
        _navigateToLogin();
      }
    }
  }

  Future<void> _checkAppResume() async {
    if (_isNavigating || !mounted) return;

    try {
      _hasInternet = await Helpers.hasInternetConnection();

      if (!mounted) return;

      if (!_hasInternet) {
        _navigateToNoInternet();
        return;
      }

      final shouldRequirePin = await Helpers.shouldRequirePin();
      if (!mounted) return;

      if (shouldRequirePin) {
        _navigateToPinEntry();
      }
    } catch (e) {
      print('Error in _checkAppResume: $e');
    }
  }

  Future<void> _checkLoginStatus() async {
    if (_isNavigating || !mounted) return;

    try {
      final isLoggedIn = await Helpers.isLoggedIn();

      if (!mounted) return;

      if (isLoggedIn && SupabaseService.currentAuthUser != null) {
        _navigateToContactSelection();
      } else {
        _navigateToLogin();
      }
    } catch (e) {
      print('Error in _checkLoginStatus: $e');
      if (mounted) {
        _navigateToLogin();
      }
    }
  }

  void _navigateToNoInternet() {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => NoInternetScreen(
          onRetry: () {
            _isNavigating = false;
            _checkInitialState();
          },
        ),
      ),
    );
  }

  void _navigateToPinSetup() {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PinSetupScreen(
          onPinSet: () {
            _isNavigating = false;
            _checkLoginStatus();
          },
        ),
      ),
    );
  }

  void _navigateToPinEntry() {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PinEnterScreen(
          onPinVerified: () {
            _isNavigating = false;
            _checkLoginStatus();
          },
        ),
      ),
    );
  }

  void _navigateToLogin() {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _navigateToContactSelection() {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const ContactSelectionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
