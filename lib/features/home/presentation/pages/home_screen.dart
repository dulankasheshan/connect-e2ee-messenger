import 'package:connect/features/chat/presentation/pages/chat_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:connect/features/discover/presentation/pages/discover_screen.dart';
import 'package:connect/features/profile/presentation/pages/profile_screen.dart';
import 'package:connect/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:connect/features/profile/presentation/bloc/profile_event.dart';

import '../../../chat/presentation/bloc/chat_list/chat_list_bloc.dart';
import '../../../chat/presentation/bloc/chat_list/chat_list_event.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Tabs screens list
  final List<Widget> _pages = [
    const ChatListScreen(),  // 0: Chat Feature
    const DiscoverScreen(),  // 1: Discover Feature
    const ProfileScreen(),   // 2: Profile Feature
  ];

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(GetMyProfileRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });

          // Refresh the Chat List whenever the user navigates to the Chat tab
          if (index == 0) {
            context.read<ChatListBloc>().add(LoadRecentChatsRequested());
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}