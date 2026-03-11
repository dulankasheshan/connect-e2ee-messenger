import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connect/core/utils/responsive_extension.dart';
import 'package:connect/core/presentation/widgets/clean_background.dart';
import 'package:connect/features/discover/presentation/bloc/discover_bloc.dart';
import 'package:connect/features/discover/presentation/bloc/discover_event.dart';
import 'package:connect/features/discover/presentation/bloc/discover_state.dart';
import 'package:connect/features/discover/domain/entities/search_user_entity.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DiscoverBloc>().add(GetBlockedUsersRequested());
  }

  void _unblockUser(SearchUserEntity user) {
    context.read<DiscoverBloc>().add(UnblockUserRequested(userId: user.id));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Blocked Users',
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
          child: BlocConsumer<DiscoverBloc, DiscoverState>(
            listener: (context, state) {
              if (state is DiscoverActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                context.read<DiscoverBloc>().add(GetBlockedUsersRequested());
              } else if (state is DiscoverError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            buildWhen: (previous, current) =>
            current is DiscoverBlockedUsersLoaded || current is DiscoverLoading || current is DiscoverError,
            builder: (context, state) {
              if (state is DiscoverLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is DiscoverBlockedUsersLoaded) {
                final users = state.blockedUsers;

                if (users.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.widthPct(0.04),
                    vertical: 16.0,
                  ),
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: colorScheme.primaryContainer,
                          backgroundImage: user.profilePicUrl != null && user.profilePicUrl!.isNotEmpty
                              ? NetworkImage(user.profilePicUrl!)
                              : null,
                          child: user.profilePicUrl == null || user.profilePicUrl!.isEmpty
                              ? Icon(Icons.person, color: colorScheme.onPrimaryContainer)
                              : null,
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('@${user.username}'),
                        trailing: TextButton(
                          onPressed: () => _unblockUser(user),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            backgroundColor: colorScheme.primaryContainer.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Unblock',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 80, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(
              'No Blocked Users',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'When you block someone, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}