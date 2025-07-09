import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:jala_as/main.dart';
import 'package:jala_as/screens/web/web_login_screen.dart';

import '../web/web_main.dart';



class ResponsiveHelper {
  static bool isMobileApp() =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  static bool isDesktopApp() =>
      !kIsWeb && !(defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  static bool isMobileWeb(BuildContext context) =>
      kIsWeb && MediaQuery.of(context).size.width < 800;

  static bool isDesktopWeb(BuildContext context) =>
      kIsWeb && MediaQuery.of(context).size.width >= 800;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isMobileWeb(context)) {
      return const MyApp(); // Web (Mobile Layout)
    } else if (ResponsiveHelper.isDesktopWeb(context)) {
      return const WebApp(); // Web (Desktop Layout)
    } else if (ResponsiveHelper.isMobileApp()) {
      return const MyApp(); // Mobile App
    } else {
      return const WebApp(); // Desktop App fallback
    }
  }
}
