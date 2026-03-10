import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import 'package:connect/core/utils/responsive_extension.dart';
import 'package:connect/core/presentation/widgets/clean_background.dart';
import 'package:connect/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:connect/features/profile/presentation/bloc/profile_state.dart';

import '../bloc/profile_event.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CleanBackground(
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {

            // --- Loading State (Skeleton UI) ---
            if (state is ProfileLoading) {
              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: context.widthPct(0.08)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: context.heightPct(0.10)),

                      // Avatar Skeleton
                      Center(
                        child: Container(
                          width: context.isMobile ? 130 : 160,
                          height: context.isMobile ? 130 : 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          ),
                          child: Center(
                            child: Text(
                              'Loading...',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: context.heightPct(0.05)),

                      // Name Skeleton
                      Center(
                        child: Container(
                          width: context.widthPct(0.5),
                          height: 32,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      SizedBox(height: context.heightPct(0.02)),

                      // Username Skeleton
                      Center(
                        child: Container(
                          width: context.widthPct(0.3),
                          height: 18,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),

                      SizedBox(height: context.heightPct(0.08)),

                      // Button Skeletons
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),

                      SizedBox(height: context.heightPct(0.02)),

                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // --- Success State ---
            else if (state is ProfileLoaded) {
              final user = state.profileEntity;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: context.widthPct(0.08)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: context.heightPct(0.10)),

                      // Profile Picture
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(context.widthPct(0.015)),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.surface.withOpacity(0.4),
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.3),
                              width: 3.0,
                            ),
                          ),
                          child: ClipOval(
                            child: SizedBox(
                              width: context.isMobile ? 130 : 160,
                              height: context.isMobile ? 130 : 160,
                              child: user.profilePicUrl != null && user.profilePicUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                imageUrl: user.profilePicUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Icon(
                                  Icons.person_outline,
                                  size: context.isMobile ? 60 : 80,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.person_outline,
                                  size: context.isMobile ? 60 : 80,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              )
                                  : Icon(
                                Icons.person_outline,
                                size: context.isMobile ? 60 : 80,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: context.heightPct(0.03)),

                      // User Information
                      Text(
                        user.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: context.isMobile ? 28 : 36,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          letterSpacing: 1.2,
                        ),
                      ),

                      SizedBox(height: context.heightPct(0.01)),

                      Text(
                        '@${user.username ?? 'unknown'}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: context.isMobile ? 16 : 18,
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),

                      SizedBox(height: context.heightPct(0.06)),

                      // Action Buttons
                      SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate and wait until the user returns from Edit screen
                            context.push(
                              '/edit-profile',
                              extra: {
                                'user': user,
                                'bloc': context.read<ProfileBloc>(), // අරන් යනවා පරණ BLoC එකම!
                              },
                            );

                            // Refresh the current screen's BLoC with new data
                            if (context.mounted) {
                              context.read<ProfileBloc>().add(GetMyProfileRequested());
                            }
                          },
                          icon: const Icon(Icons.edit_outlined, size: 22),
                          label: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),

                      SizedBox(height: context.heightPct(0.02)),

                      SizedBox(
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Route to Settings Screen
                          },
                          icon: const Icon(Icons.settings_outlined, size: 22),
                          label: const Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: colorScheme.outline.withOpacity(0.5),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: context.heightPct(0.06)),

                      // Security Information Card
                      Container(
                        padding: EdgeInsets.all(context.widthPct(0.05)),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_outline,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'End-to-End Encrypted',
                                    style: TextStyle(
                                      fontSize: context.isMobile ? 15 : 17,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Your personal data and messages are secured with military-grade encryption. Not even Connect can read them.',
                                    style: TextStyle(
                                      fontSize: context.isMobile ? 13 : 15,
                                      height: 1.5,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: context.heightPct(0.04)),
                    ],
                  ),
                ),
              );
            }

            // --- Error State ---
            else if (state is ProfileError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.widthPct(0.08)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // --- Initial State ---
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}