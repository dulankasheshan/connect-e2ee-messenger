import 'package:connect/features/auth/presentation/pages/otp_verification_screen.dart';
import 'package:connect/features/home/presentation/pages/home_screen.dart';
import 'package:connect/features/profile/presentation/pages/profile_setup_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/chat/presentation/pages/chat_screen.dart';
import '../../features/discover/domain/entities/search_user_entity.dart';
import '../../features/discover/presentation/bloc/discover_bloc.dart';
import '../../features/discover/presentation/pages/discover_screen.dart';
import '../../features/profile/domain/entities/user_profile_entity.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/pages/edit_profile_screen.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/settings/presentation/pages/blocked_users_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';
import '../../service_locator.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',

    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        name: 'verify-otp',
        builder: (context, state) {
          // 1. Extract the email from the state's extra property
          // We use "as String" to tell Flutter we are 100% sure this is a text
          final email = state.extra as String;

          // 2. Pass it to the screen
          return OtpVerificationScreen(email: email);
        },
      ),

      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (context, state) {
          return BlocProvider(
            create: (context) => sl<ProfileBloc>(),
            child: const ProfileSetupScreen(),
          );
        },
      ),

      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) {
          // Wrap HomeScreen with MultiBlocProvider to provide multiple BLoCs
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => sl<ProfileBloc>()),
              BlocProvider(create: (context) => sl<DiscoverBloc>()),
            ],
            child: const HomeScreen(),
          );
        },
      ),

      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) {
          // Extracting the map passed from the ProfileScreen
          final extraMap = state.extra as Map<String, dynamic>;
          final currentUser = extraMap['user'] as UserProfileEntity;
          final profileBloc = extraMap['bloc'] as ProfileBloc;

          return BlocProvider.value(
            // Providing the EXACT SAME instance of the BLoC
            value: profileBloc,
            child: EditProfileScreen(currentUser: currentUser),
          );
        },
      ),

      GoRoute(
        path: '/discover',
        name: 'discover',
        builder: (context, state) {
          return BlocProvider(
            create: (context) => sl<DiscoverBloc>(),
            child: const DiscoverScreen(),
          );
        },
      ),

      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) {
          final currentUser = state.extra as UserProfileEntity;
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => sl<SettingsBloc>()),
              BlocProvider(create: (context) => sl<AuthBloc>()), // Added AuthBloc
            ],
            child: SettingsScreen(currentUser: currentUser),
          );
        },
      ),

      GoRoute(
        path: '/blocked-users',
        name: 'blocked-users',
        builder: (context, state) {
          return BlocProvider(
            create: (context) => sl<DiscoverBloc>(),
            child: const BlockedUsersScreen(),
          );
        },
      ),

      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          final currentUser = args['currentUser'] as UserProfileEntity;
          final receiverUser = args['receiverUser'] as SearchUserEntity;
          final receiverPublicKey = args['receiverPublicKey'] as String;

          return ChatScreen(
            currentUser: currentUser,
            receiverUser: receiverUser,
            receiverPublicKey: receiverPublicKey,
          );
        },
      ),
    ],
  );
}
