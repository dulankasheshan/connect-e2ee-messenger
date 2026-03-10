import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  // Added this for future use (e.g., if we ever need passwords)
  final bool obscureText;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onFieldSubmitted,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if the app is currently in Dark Mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define subtle border colors based on the theme
    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.15)
        : Colors.black.withOpacity(0.1);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
        // Display the prefix icon only if it is provided
        prefixIcon: prefixIcon != null
            ? Icon(
          prefixIcon,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
        )
            : null,

        filled: true,
        fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),

        // 1. Default Border (When not focused)
        // Uses a very subtle, elegant outline
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: borderColor,
            width: 1.5,
          ),
        ),

        // 2. Focused Border (When the user is typing)
        // Highlights using the primary brand color
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2.0,
          ),
        ),

        // 3. Error Border (When validation fails)
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.5,
          ),
        ),

        // 4. Focused Error Border
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2.0,
          ),
        ),
      ),
    );
  }
}