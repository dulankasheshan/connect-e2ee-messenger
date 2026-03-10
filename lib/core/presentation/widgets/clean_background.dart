import 'package:flutter/material.dart';

class CleanBackground extends StatelessWidget {
  final Widget child;

  const CleanBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [const Color(0xFF1E293B), const Color(0xFF000000)] // Elegant slate to pure black
                : [const Color(0xFFFFFFFF), const Color(0xFFF1F5F9)], // Pure white to very soft gray-blue
          ),
        ),
        child: SafeArea(
          child: child,
        ),
      ),
    );
  }
}