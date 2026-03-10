import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connect/core/routing/app_router.dart';
import 'package:connect/core/theme/app_theme.dart';
import 'package:connect/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:connect/service_locator.dart'; // We will create this next

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Global HTTP overrides to bypass SSL certificate validation.
/// This ensures that widgets like [NetworkImage] can load assets from
/// local servers with self-signed certificates during development.
class DevelopmentHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Allows self-signed certificates only in debug mode for security reasons.
        return kDebugMode;
      };
  }
}

void main() async {
  // Required before calling any async methods or native code in main()
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Apply HTTP overrides globally
  HttpOverrides.global = DevelopmentHttpOverrides();

  // Initialize Dependency Injection (setup get_it)
  await initDependencies();

  runApp(const ConnectChatApp());
}

class ConnectChatApp extends StatelessWidget {
  const ConnectChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiBlocProvider makes Blocs available throughout the widget tree
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          // Fetch the AuthBloc instance from our Service Locator (get_it)
          create: (context) => sl<AuthBloc>(),
        ),
      ],
      // Using router constructor for GoRouter integration
      child: MaterialApp.router(
        title: 'Connect Chat',
        debugShowCheckedModeBanner: false,

        // --- THEME CONFIGURATION ---
        theme: AppTheme.lightTheme,         // Applied when phone is in Light Mode
        darkTheme: AppTheme.darkTheme,      // Applied when phone is in Dark Mode
        themeMode: ThemeMode.system,        // Automatically listen to device settings
        // ---------------------------

        // Pass the GoRouter configuration
        routerConfig: AppRouter.router,
      ),
    );
  }
}