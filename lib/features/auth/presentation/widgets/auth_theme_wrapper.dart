import 'package:flutter/material.dart';

class AuthThemeWrapper extends StatelessWidget {
  final Widget child;

  const AuthThemeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF0B1F3A),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0B1F3A),
          secondary: Color(0xFFF5A623),
          error: Color(0xFFEF4444),
          surface: Colors.white,
        ),
        fontFamily: 'Cairo',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F8FA),
          foregroundColor: Color(0xFF0B1F3A),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0B1F3A),
          ),
          iconTheme: IconThemeData(color: Color(0xFF0B1F3A)),
        ),
      ),
      child: child,
    );
  }
}
