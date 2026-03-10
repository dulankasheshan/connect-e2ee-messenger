import 'package:connect/core/constants/app_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:connect/core/utils/responsive_extension.dart';
import 'package:connect/core/presentation/widgets/clean_background.dart';
import 'package:connect/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:connect/features/auth/presentation/bloc/auth_event.dart';
import 'package:connect/features/auth/presentation/bloc/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Dispatch the event to check authentication status on startup
    context.read<AuthBloc>().add(CheckAuthStatusRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthVerifiedSuccess) {
          // Check if the user has completed their profile setup
          if (state.session.isProfileComplete) {
            // Profile is complete, safe to go home
            Future.delayed(const Duration(seconds: 2), () {
              context.go('/home');
            });

          } else {
            // User killed the app during profile setup previously.
            // Redirect them back to finish it!
            context.go('/profile-setup');
          }
        } else if (state is AuthInitial || state is AuthError) {

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) context.go('/login');
          });
        }
      },
      child: CleanBackground(
        child: SizedBox(
          width: double.infinity,
          child: TweenAnimationBuilder(
            // Creates a smooth fade and scale-up animation for the logo
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.8 + (value * 0.2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo
                      SvgPicture.asset(
                        AppImages.appLogo,
                        width: context.heightPct(0.12),
                        height: context.heightPct(0.12),
                      ),

                      SizedBox(height: context.heightPct(0.03)),

                      // App Name
                      Text(
                        'Connect',
                        style: TextStyle(
                          fontSize: context.isMobile ? 32 : 44,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),



                      SizedBox(height: context.heightPct(0.06)),

                      // Minimalist Loading Indicator
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}