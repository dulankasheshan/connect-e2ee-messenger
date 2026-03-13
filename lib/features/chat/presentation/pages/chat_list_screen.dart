import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dartz/dartz.dart' as dartz;

import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/chat/presentation/bloc/chat_list/chat_list_bloc.dart';
import 'package:connect/features/chat/presentation/bloc/chat_list/chat_list_event.dart';
import 'package:connect/features/chat/presentation/bloc/chat_list/chat_list_state.dart';
import 'package:connect/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:connect/features/profile/presentation/bloc/profile_state.dart';
import 'package:connect/features/discover/presentation/bloc/discover_bloc.dart';
import 'package:connect/features/discover/presentation/bloc/discover_event.dart';
import 'package:connect/features/discover/presentation/bloc/discover_state.dart';
import 'package:connect/features/discover/domain/entities/search_user_entity.dart';

import '../../../../service_locator.dart';
import '../../../chat/domain/repositories/i_chat_repository.dart';
import '../../domain/usecases/receive_messages_stream_usecase.dart';
import '../../domain/usecases/receive_message_status_stream_usecase.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  StreamSubscription? _incomingMessageSub;
  StreamSubscription? _statusUpdateSub;

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(ConnectSocketRequested());
    context.read<ChatListBloc>().add(LoadRecentChatsRequested());

    // Refresh list on incoming messages
    _incomingMessageSub = sl<ReceiveMessagesStreamUseCase>().call().listen((_) {
      if (mounted) {
        context.read<ChatListBloc>().add(LoadRecentChatsRequested());
      }
    });

    // Refresh list on message status updates
    _statusUpdateSub = sl<ReceiveMessageStatusStreamUseCase>().call().listen((_) {
      if (mounted) {
        context.read<ChatListBloc>().add(LoadRecentChatsRequested());
      }
    });
  }

  @override
  void dispose() {
    _incomingMessageSub?.cancel();
    _statusUpdateSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<ChatListBloc, ChatListState>(
        builder: (context, state) {
          if (state is ChatListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChatListLoaded) {
            final chats = state.recentChats;

            if (chats.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ChatListBloc>().add(LoadRecentChatsRequested());
              },
              child: ListView.separated(
                itemCount: chats.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 76,
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                ),
                itemBuilder: (context, index) {
                  final message = chats[index];
                  final profileState = context.watch<ProfileBloc>().state;
                  final myId = profileState is ProfileLoaded ? profileState.profileEntity.id : '';

                  final chatUserId = message.senderId == myId
                      ? message.receiverId
                      : message.senderId;

                  return FutureBuilder<dartz.Either<Failures, Map<String, dynamic>?>>(
                    future: sl<IChatRepository>().getCachedUser(chatUserId),
                    builder: (context, snapshot) {
                      String displayName = chatUserId.substring(0, 8);
                      String username = chatUserId;
                      String? avatarUrl;

                      if (snapshot.hasData) {
                        snapshot.data!.fold(
                              (failure) => null,
                              (userData) {
                            if (userData != null) {
                              displayName = userData['name'] as String;
                              username = userData['username'] as String;
                              avatarUrl = userData['profilePicUrl'] as String?;
                            }
                          },
                        );
                      }

                      final isUnreadIncoming = message.status != 'read' && message.senderId != myId;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: colorScheme.primaryContainer,
                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                          child: avatarUrl == null
                              ? Icon(Icons.person, color: colorScheme.onPrimaryContainer)
                              : null,
                        ),
                        title: Text(
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          message.decryptedText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: isUnreadIncoming ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTime(message.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: isUnreadIncoming
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: isUnreadIncoming ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isUnreadIncoming)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          if (profileState is! ProfileLoaded) return;
                          final currentUser = profileState.profileEntity;

                          final targetUser = SearchUserEntity(
                            id: chatUserId,
                            name: displayName,
                            username: username,
                            profilePicUrl: avatarUrl,
                            isOnline: false,
                            lastSeenVisibility: true,
                          );

                          final chatListBloc = context.read<ChatListBloc>();

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (dialogContext) {
                              return BlocProvider<DiscoverBloc>(
                                create: (context) => sl<DiscoverBloc>()..add(GetPublicKeyRequested(userId: chatUserId)),
                                child: BlocListener<DiscoverBloc, DiscoverState>(
                                  listener: (innerContext, discoverState) {
                                    if (discoverState is DiscoverPublicKeyLoaded) {
                                      Navigator.of(dialogContext).pop();

                                      context.push('/chat', extra: {
                                        'currentUser': currentUser,
                                        'receiverUser': targetUser,
                                        'receiverPublicKey': discoverState.publicKey,
                                      }).then((_) {
                                        // Refresh list after returning from chat
                                        chatListBloc.add(LoadRecentChatsRequested());
                                      });
                                    } else if (discoverState is DiscoverError) {
                                      Navigator.of(dialogContext).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(discoverState.message)),
                                      );
                                    }
                                  },
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            );
          }

          if (state is ChatListError) {
            return Center(child: Text(state.message, style: TextStyle(color: colorScheme.error)));
          }

          return _buildEmptyState(context);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'No recent chats yet.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Go to Discover to find your friends!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    }
    return "${time.month}/${time.day}";
  }
}