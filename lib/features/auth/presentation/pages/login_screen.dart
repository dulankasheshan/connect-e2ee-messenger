import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:connect/core/utils/responsive_extension.dart';
import 'package:connect/core/presentation/widgets/clean_background.dart';
import 'package:connect/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:connect/features/auth/presentation/bloc/auth_event.dart';
import 'package:connect/features/auth/presentation/bloc/auth_state.dart';

import '../../../../core/presentation/widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose(); // Always dispose controllers to prevent memory leaks
    super.dispose();
  }

  // Function to validate the form and dispatch the BLoC event
  void _submitEmail() {
    // Unfocus the keyboard when the button is pressed
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      // Dispatch the event to our BLoC
      context.read<AuthBloc>().add(SendOtpRequest(email));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Wrap the entire screen in our reusable CleanBackground
      body: CleanBackground(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            // Listen for specific states that require one-time actions
            if (state is AuthError) {
              // Show a modern floating SnackBar for errors
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            } else if (state is AuthOtpSendSuccess) {
              // Successfully sent OTP! Navigate to the verification screen.
              // We pass the email as an extra argument so the next screen knows what email to display
              context.push('/verify-otp', extra: state.email);
            }
          },
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                // Responsive padding: 8% of screen width on the sides
                padding: EdgeInsets.symmetric(horizontal: context.widthPct(0.08)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Header Section ---
                      Icon(
                        Icons.mark_email_read_outlined,
                        size: context.heightPct(0.08),
                        color: Theme.of(context).colorScheme.primary,
                      ),

                      SizedBox(height: context.heightPct(0.03)),

                      Text(
                        'Let\'s Connect',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: context.isMobile ? 28 : 36,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 1.2,
                        ),
                      ),

                      SizedBox(height: context.heightPct(0.01)),

                      Text(
                        'Enter your email address to receive a secure login code.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: context.isMobile ? 14 : 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),

                      SizedBox(height: context.heightPct(0.06)),

                      // --- Input Section ---
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email Address',
                        hintText: 'hello@example.com',
                        prefixIcon: Icons.alternate_email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submitEmail(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: context.heightPct(0.04)),

                      // --- Button Section ---
                      SizedBox(
                        height: 56, // Standard height for modern touch targets
                        child: ElevatedButton(
                          // Disable the button while loading to prevent double-clicks
                          onPressed: state is AuthLoading ? null : _submitEmail,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: state is AuthLoading
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}