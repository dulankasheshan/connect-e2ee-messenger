import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:connect/core/utils/responsive_extension.dart';
import 'package:connect/features/chat/domain/entities/message_entity.dart';
import 'package:connect/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:connect/features/chat/presentation/bloc/chat_event.dart';
import 'package:connect/features/chat/presentation/bloc/chat_state.dart';
import 'package:connect/features/profile/domain/entities/user_profile_entity.dart';
import 'package:connect/features/discover/domain/entities/search_user_entity.dart';

import '../../../../service_locator.dart';
import '../../../discover/presentation/bloc/discover_bloc.dart';
import '../../../discover/presentation/bloc/discover_event.dart';
import '../../../discover/presentation/bloc/discover_state.dart';

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
  late DiscoverBloc _discoverBloc;

  bool _isTyping = false;
  bool _isBlockedByMe = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _discoverBloc = sl<DiscoverBloc>();

    _chatBloc.add(
        LoadChatHistoryRequested(
          userId: widget.receiverUser.id,
          isOnline: widget.receiverUser.isOnline,
        )
    );
  }

  @override
  void dispose() {
    _typingTimer?.cancel();

    if (_isTyping) {
      _chatBloc.add(
          SendTypingStatusRequested(receiverId: widget.receiverUser.id, isTyping: false)
      );
    }

    _messageController.dispose();
    _scrollController.dispose();
    _discoverBloc.close();
    super.dispose();
  }

  void _onTyping(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _chatBloc.add(
          SendTypingStatusRequested(receiverId: widget.receiverUser.id, isTyping: true)
      );
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        _chatBloc.add(
            SendTypingStatusRequested(receiverId: widget.receiverUser.id, isTyping: false)
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentState = _chatBloc.state;
    if (currentState is ChatLoaded && currentState.editingMessageId != null) {
      _chatBloc.add(EditMessageRequested(
        messageId: currentState.editingMessageId!,
        newPlaintext: text,
        receiverPublicKey: widget.receiverPublicKey,
      ));
      _messageController.clear();
      return;
    }

    final tempId = const Uuid().v4();
    final message = MessageEntity(
      id: tempId,
      senderId: widget.currentUser.id,
      receiverId: widget.receiverUser.id,
      decryptedText: text,
      status: 'sent',
      createdAt: DateTime.now(),
      clientTempId: tempId,
    );

    _chatBloc.add(
      SendMessageRequested(
        message: message,
        receiverPublicKey: widget.receiverPublicKey,
      ),
    );

    _messageController.clear();

    _typingTimer?.cancel();
    if (_isTyping) {
      _isTyping = false;
      _chatBloc.add(
          SendTypingStatusRequested(receiverId: widget.receiverUser.id, isTyping: false)
      );
    }
  }

  void _showBlockConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Block User?'),
          content: Text('Are you sure you want to block ${widget.receiverUser.name}? You will no longer receive messages from them.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _discoverBloc.add(BlockUserRequested(userId: widget.receiverUser.id));
              },
              child: const Text('Block'),
            ),
          ],
        );
      },
    );
  }

  void _showMessageOptions(BuildContext context, MessageEntity message, bool isMe) {
    if (!isMe || message.decryptedText.contains('🚫')) return;

    showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Message'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _chatBloc.add(EditModeToggled(messageId: message.id));
                    _messageController.text = message.decryptedText;
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete for Everyone', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _chatBloc.add(DeleteMessageRequested(messageId: message.id));
                  },
                ),
              ],
            ),
          );
        }
    );
  }

  void _showClearChatConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Chat?'),
          content: Text('Are you sure you want to delete all messages with ${widget.receiverUser.name} from your device? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Dispatch the event to the ChatBloc
                _chatBloc.add(ClearAllChatHistoryRequested(chatUserId: widget.receiverUser.id));
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _discoverBloc,
      child: BlocListener<DiscoverBloc, DiscoverState>(
        listener: (context, state) {
          if (state is DiscoverActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );

            setState(() {
              if (state.message.toLowerCase().contains('unblock')) {
                _isBlockedByMe = false;
              } else {
                _isBlockedByMe = true;
              }
            });
          } else if (state is DiscoverError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Scaffold(
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
                          if (state is ChatLoaded) {
                            if (state.isTyping) {
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
                              state.isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                fontSize: 12,
                                color: state.isOnline
                                    ? Colors.green
                                    : colorScheme.onSurfaceVariant,
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
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'block') {
                    _showBlockConfirmationDialog(context);
                  } else if (value == 'unblock') {
                    _discoverBloc.add(UnblockUserRequested(userId: widget.receiverUser.id));
                  } else if (value == 'clear_chat') {
                    // Call the new confirmation dialog
                    _showClearChatConfirmationDialog(context);
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: _isBlockedByMe ? 'unblock' : 'block',
                      child: Row(
                        children: [
                          Icon(
                              _isBlockedByMe ? Icons.check_circle_outline : Icons.block,
                              color: _isBlockedByMe ? Colors.green : Colors.red,
                              size: 20
                          ),
                          const SizedBox(width: 8),
                          Text(
                              _isBlockedByMe ? 'Unblock User' : 'Block User',
                              style: TextStyle(color: _isBlockedByMe ? Colors.green : Colors.red)
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(), // Add a divider
                    const PopupMenuItem<String>(
                      value: 'clear_chat',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text('Clear Chat (Local)', style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
          body: Column(
            children: [
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
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == widget.currentUser.id;

                          return GestureDetector(
                            onLongPress: () => _showMessageOptions(context, message, isMe),
                            child: _buildMessageBubble(message, isMe, colorScheme),
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              if (_isBlockedByMe)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  child: Column(
                    children: [
                      Text(
                        'You blocked this user.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          _discoverBloc.add(UnblockUserRequested(userId: widget.receiverUser.id));
                        },
                        child: Text(
                          'Tap to unblock',
                          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                )
              else
                BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      bool isEditing = state is ChatLoaded && state.editingMessageId != null;
                      return SafeArea(
                        child: Column(
                          children: [
                            if (isEditing)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                color: colorScheme.surfaceContainerHighest,
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit, size: 16),
                                    const SizedBox(width: 8),
                                    const Expanded(child: Text('Editing message...')),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      onPressed: () {
                                        _messageController.clear();
                                        _chatBloc.add(const EditModeToggled());
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            Container(
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
                                      icon: Icon(isEditing ? Icons.check : Icons.send_rounded, color: Colors.white),
                                      onPressed: _sendMessage,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageEntity message, bool isMe, ColorScheme colorScheme) {
    bool isDeleted = message.decryptedText.contains('🚫');
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDeleted ? colorScheme.surfaceContainerHighest.withOpacity(0.5) : (isMe ? colorScheme.primary : colorScheme.surfaceContainerHighest),
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
                fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                color: isDeleted ? colorScheme.onSurfaceVariant : (isMe ? colorScheme.onPrimary : colorScheme.onSurface),
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
                    color: isMe && !isDeleted ? colorScheme.onPrimary.withOpacity(0.7) : colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                if (isMe && !isDeleted) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.status == 'read'
                        ? Icons.done_all
                        : (message.status == 'delivered' ? Icons.done_all : Icons.check),
                    size: 14,
                    color: message.status == 'read'
                        ? Colors.blue.shade200
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