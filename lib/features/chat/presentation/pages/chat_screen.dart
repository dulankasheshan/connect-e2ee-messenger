import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:connect/core/utils/responsive_extension.dart';
import 'package:connect/features/chat/domain/entities/message_entity.dart';
import 'package:connect/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:connect/features/chat/presentation/bloc/chat_event.dart';
import 'package:connect/features/chat/presentation/bloc/chat_state.dart';
import 'package:connect/features/profile/domain/entities/user_profile_entity.dart';
// TRANSLATOR: Assuming you use SearchUserEntity from discover feature for the receiver
import 'package:connect/features/discover/domain/entities/search_user_entity.dart';

class ChatScreen extends StatefulWidget {
  final UserProfileEntity currentUser;
  final SearchUserEntity receiverUser;
  final String receiverPublicKey;

  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.receiverUser,
    required this.receiverPublicKey,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late ChatBloc _chatBloc;

  // To track typing status and avoid sending too many socket events
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();

    // Connect to sockets
    context.read<ChatBloc>().add(ConnectSocketRequested());
    // oad History
    context.read<ChatBloc>().add(LoadChatHistoryRequested(userId: widget.receiverUser.id));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Disconnect socket when leaving screen
    context.read<ChatBloc>().add(DisconnectSocketRequested());
    _chatBloc.add(DisconnectSocketRequested());
    super.dispose();
  }

  void _onTyping(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      context.read<ChatBloc>().add(
          SendTypingStatusRequested(receiverId: widget.receiverUser.id, isTyping: true)
      );
    } else if (text.isEmpty && _isTyping) {
      _isTyping = false;
      context.read<ChatBloc>().add(
          SendTypingStatusRequested(receiverId: widget.receiverUser.id, isTyping: false)
      );
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final tempId = const Uuid().v4();
    final message = MessageEntity(
      id: tempId, // Temporary ID until server responds
      senderId: widget.currentUser.id,
      receiverId: widget.receiverUser.id,
      decryptedText: text,
      status: 'sent',
      createdAt: DateTime.now(),
      clientTempId: tempId,
    );

    context.read<ChatBloc>().add(
      SendMessageRequested(
        message: message,
        receiverPublicKey: widget.receiverPublicKey,
      ),
    );

    _messageController.clear();
    _onTyping(''); // Stop typing
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: widget.receiverUser.profilePicUrl != null
                  ? NetworkImage(widget.receiverUser.profilePicUrl!)
                  : null,
              child: widget.receiverUser.profilePicUrl == null
                  ? Icon(Icons.person, color: colorScheme.onPrimaryContainer)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverUser.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      if (state is ChatLoaded && state.isTyping) {
                        return Text(
                          'typing...',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }
                      return Text(
                        widget.receiverUser.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.receiverUser.isOnline
                              ? Colors.green
                              : colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // --- Chat Messages List ---
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ChatError) {
                  return Center(child: Text(state.message, style: TextStyle(color: colorScheme.error)));
                } else if (state is ChatLoaded) {
                  final messages = state.messages;

                  if (messages.isEmpty) {
                    return Center(
                      child: Text('Say hi to ${widget.receiverUser.name} 👋',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true, // IMPORTANT: Shows newest at the bottom!
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == widget.currentUser.id;

                      return _buildMessageBubble(message, isMe, colorScheme);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // --- Bottom Input Area ---
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: colorScheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: _onTyping,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageEntity message, bool isMe, ColorScheme colorScheme) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.decryptedText,
              style: TextStyle(
                color: isMe ? colorScheme.onPrimary : colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: isMe ? colorScheme.onPrimary.withOpacity(0.7) : colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.status == 'read'
                        ? Icons.done_all
                        : (message.status == 'delivered' ? Icons.done_all : Icons.check),
                    size: 14,
                    color: message.status == 'read'
                        ? Colors.blue.shade200 // Show blue ticks if read
                        : colorScheme.onPrimary.withOpacity(0.7),
                  ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }
}