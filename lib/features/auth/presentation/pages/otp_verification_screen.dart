import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:connect/core/utils/responsive_extension.dart';
import 'package:connect/core/presentation/widgets/clean_background.dart';
import 'package:connect/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:connect/features/auth/presentation/bloc/auth_event.dart';
import 'package:connect/features/auth/presentation/bloc/auth_state.dart';

class OtpVerificationScreen extends StatefulWidget {
  // We need the email from the previous screen to send the verify request
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  // Triggered when the user enters all 6 digits or presses the Verify button
  void _verifyOtp() {
    // Prevent double-triggering if an API call is already in progress
    if (context.read<AuthBloc>().state is AuthLoading) return;

    final otp = _pinController.text.trim();
    if (otp.length == 6) {
      FocusScope.of(context).unfocus();
      // Dispatch the verification event to the BLoC
      context.read<AuthBloc>().add(VerifyOtpRequested(widget.email, otp));
    } else {
      // Clear any existing SnackBars before showing a new one
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid 6-digit code.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    // --- Pinput Theming ---
    // 1. Default state of the boxes
    final defaultPinTheme = PinTheme(
      width: context.isMobile ? 50 : 60,
      height: context.isMobile ? 60 : 70,
      textStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1),
          width: 1.5,
        ),
      ),
    );

    // 2. Focused state (When typing in a specific box)
    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: primaryColor, width: 2.0),
      borderRadius: BorderRadius.circular(12),
    );

    // 3. Submitted state (When a box has a number inside it)
    final submittedPinTheme = defaultPinTheme.copyDecorationWith(
      color: primaryColor.withOpacity(0.1),
      border: Border.all(color: primaryColor.withOpacity(0.5), width: 1.5),
    );

    return Scaffold(
      body: CleanBackground(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              _pinController.clear(); // Clear the PIN so they can try again
              _pinFocusNode.requestFocus(); // Bring the keyboard back up

              // IMMEDIATELY clear the queue so SnackBars don't stack up
              ScaffoldMessenger.of(context).clearSnackBars();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is AuthVerifiedSuccess) {
              // Successfully verified!
              if (state.session.isProfileComplete) {
                context.go('/home');
              } else {
                context.go('/profile-setup');
              }
            }
          },
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: context.widthPct(0.08)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Header Section ---
                    Icon(
                      Icons.security_rounded,
                      size: context.heightPct(0.08),
                      color: primaryColor,
                    ),

                    SizedBox(height: context.heightPct(0.03)),

                    Text(
                      'Verify Email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.isMobile ? 28 : 36,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 1.2,
                      ),
                    ),

                    SizedBox(height: context.heightPct(0.02)),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: context.isMobile ? 14 : 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'We\'ve sent a 6-digit code to\n'),
                          TextSpan(
                            text: widget.email, // Displaying the email passed from login
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: context.heightPct(0.05)),

                    // --- 6-Digit PIN Input Section ---
                    Pinput(
                      length: 6,
                      controller: _pinController,
                      focusNode: _pinFocusNode,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      keyboardType: TextInputType.number,
                      // Automatically triggers verification when the 6th digit is entered
                      onCompleted: (pin) => _verifyOtp(),
                      // Adds a cool animation when typing
                      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                      showCursor: true,
                    ),

                    SizedBox(height: context.heightPct(0.05)),

                    // --- Verify Button Section ---
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading ? null : _verifyOtp,
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
                          'Verify Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: context.heightPct(0.03)),

                    // --- Resend Code Section ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Didn\'t receive the code? ',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        TextButton(
                          onPressed: state is AuthLoading
                              ? null
                              : () {
                            // Dispatch the Send OTP event again
                            context.read<AuthBloc>().add(SendOtpRequest(widget.email));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sending new code...')),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Resend',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}