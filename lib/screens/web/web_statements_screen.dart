// lib/screens/web/web_statements_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import 'web_contact_selection_screen.dart';

class WebStatementsScreen extends StatelessWidget {
  final AppUser user;

  const WebStatementsScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    // Redirect to the new contact selection screen
    return ContactSelectionScreen(user: user);
  }
}
