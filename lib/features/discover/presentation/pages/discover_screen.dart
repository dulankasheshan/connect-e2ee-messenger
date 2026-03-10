import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connect/core/utils/responsive_extension.dart';
import 'package:connect/core/presentation/widgets/clean_background.dart';
import 'package:connect/features/discover/presentation/bloc/discover_bloc.dart';
import 'package:connect/features/discover/presentation/bloc/discover_event.dart';
import 'package:connect/features/discover/presentation/bloc/discover_state.dart';
import '../widgets/user_list_tile.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      context.read<DiscoverBloc>().add(ClearSearchRequested());
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().length >= 2) {
        context.read<DiscoverBloc>().add(SearchUsersRequested(query: query.trim()));
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    context.read<DiscoverBloc>().add(ClearSearchRequested());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Discover',
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
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.widthPct(0.06),
                  vertical: 16.0,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search by name or @username...',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, child) {
                        return value.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                          onPressed: _clearSearch,
                        )
                            : const SizedBox.shrink();
                      },
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              Expanded(
                child: BlocBuilder<DiscoverBloc, DiscoverState>(
                  builder: (context, state) {
                    if (state is DiscoverInitial) {
                      return _buildEmptyState(
                        context,
                        icon: Icons.person_search_rounded,
                        title: 'Find New Connections',
                        subtitle: 'Search for friends using their name or username.',
                      );
                    }

                    else if (state is DiscoverLoading) {
                      return _buildLoadingSkeleton(context);
                    }

                    else if (state is DiscoverSearchLoaded) {
                      final users = state.users;

                      if (users.isEmpty) {
                        return _buildEmptyState(
                          context,
                          icon: Icons.search_off_rounded,
                          title: 'No Users Found',
                          subtitle: 'We couldn\'t find anyone matching that search.',
                        );
                      }

                      return ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.widthPct(0.04),
                          vertical: 8.0,
                        ),
                        itemCount: users.length,
                        separatorBuilder: (context, index) => Divider(
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                          height: 1,
                          indent: 76,
                        ),
                        itemBuilder: (context, index) {
                          return UserListTile(
                            user: users[index],
                            onTap: () {
                              // TODO: Navigate to User Profile or direct to Chat Screen
                            },
                          );
                        },
                      );
                    }

                    else if (state is DiscoverError) {
                      return _buildEmptyState(
                        context,
                        icon: Icons.error_outline_rounded,
                        title: 'Oops!',
                        subtitle: state.message,
                        isError: true,
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        bool isError = false,
      }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.widthPct(0.1)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isError
                  ? colorScheme.errorContainer.withOpacity(0.5)
                  : colorScheme.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: isError ? colorScheme.error : colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48), // Bottom visual balance
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: context.widthPct(0.04),
        vertical: 8.0,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: context.widthPct(0.4),
                      height: 16,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: context.widthPct(0.25),
                      height: 12,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}