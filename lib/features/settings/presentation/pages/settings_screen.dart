import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:connect/core/utils/responsive_extension.dart';
import 'package:connect/core/presentation/widgets/clean_background.dart';
import 'package:connect/features/profile/domain/entities/user_profile_entity.dart';
import 'package:connect/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:connect/features/settings/presentation/bloc/settings_event.dart';
import 'package:connect/features/settings/presentation/bloc/settings_state.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfileEntity currentUser;

  const SettingsScreen({super.key, required this.currentUser});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isLastSeenVisible;

  @override
  void initState() {
    super.initState();
    _isLastSeenVisible = widget.currentUser.lastSeenVisibility;
  }

  void _onToggleLastSeen(bool value) {
    setState(() {
      _isLastSeenVisible = value;
    });
    context.read<SettingsBloc>().add(ToggleLastSeenRequested(isVisible: value));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
        ),
      ),
      body: CleanBackground(
        child: SafeArea(
          child: MultiBlocListener(
            listeners: [
              // 1. Settings Listener (For Privacy Toggle)
              BlocListener<SettingsBloc, SettingsState>(
                listener: (context, state) {
                  if (state is SettingsError) {
                    setState(() {
                      _isLastSeenVisible = !_isLastSeenVisible;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),

              // 2. Auth Listener (For Logout)
              BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthInitial) {
                    // Logout successful, clear navigation stack and go to login
                    context.go('/login');
                  } else if (state is AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: context.widthPct(0.06),
                vertical: 16.0,
              ),
              children: [
                _buildSectionHeader(context, 'Privacy'),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _isLastSeenVisible,
                        onChanged: _onToggleLastSeen,
                        title: const Text(
                          'Show Last Seen',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Let others see when you were last active',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        activeColor: colorScheme.primary,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: colorScheme.outlineVariant.withOpacity(0.5),
                        indent: 20,
                        endIndent: 20,
                      ),
                      ListTile(
                        onTap: () {
                          context.push('/blocked-users');
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        title: const Text(
                          'Blocked Users',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Manage your blocked contacts',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                _buildSectionHeader(context, 'Account'),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ListTile(
                    onTap: () {
                      // Trigger the logout event in AuthBloc
                      context.read<AuthBloc>().add(LogoutRequested());
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: colorScheme.error,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Log Out',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}