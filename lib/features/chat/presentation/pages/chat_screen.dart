import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:swipe_to/swipe_to.dart';

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
    String? replyId;

    if (currentState is ChatLoaded) {
      // Handle Editing
      if (currentState.editingMessageId != null) {
        _chatBloc.add(EditMessageRequested(
          messageId: currentState.editingMessageId!,
          newPlaintext: text,
          receiverPublicKey: widget.receiverPublicKey,
        ));
        _messageController.clear();
        return;
      }
      // Get Reply ID if exists
      replyId = currentState.replyingToMessage?.id;
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
      replyToMsgId: replyId,
    );

    _chatBloc.add(
      SendMessageRequested(
        message: message,
        receiverPublicKey: widget.receiverPublicKey,
      ),
    );

    _messageController.clear();
    _typingTimer?.cancel();
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      final currentState = _chatBloc.state;
      String? replyId;

      if (currentState is ChatLoaded) {
        replyId = currentState.replyingToMessage?.id;
      }

      _chatBloc.add(
        SendMediaMessageRequested(
          mediaFile: imageFile,
          caption: '📷 Photo',
          receiverPublicKey: widget.receiverPublicKey,
          receiverId: widget.receiverUser.id,
          senderId: widget.currentUser.id,
          replyToMsgId: replyId,
        ),
      );

      _chatBloc.add(ReplyCanceled());
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
                    const PopupMenuDivider(),
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

                          // We find the replied message once here
                          MessageEntity? repliedMessage;
                          if (message.replyToMsgId != null) {
                            try {
                              repliedMessage = messages.firstWhere((m) => m.id == message.replyToMsgId);
                            } catch (_) {
                              repliedMessage = null;
                            }
                          }

                          return SwipeTo(
                            key: ValueKey(message.id), // CRITICAL: Stop widget recycling issues
                            onRightSwipe: (details) {
                              _chatBloc.add(ReplyToMessageSelected(message: message));
                            },
                            child: GestureDetector(
                              onLongPress: () => _showMessageOptions(context, message, isMe),
                              child: _buildMessageBubble(message, isMe, colorScheme, repliedMessage),
                            ),
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
                      bool isReplying = state is ChatLoaded && state.replyingToMessage != null;

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

                            // Show Reply Preview if user is replying to a message
                            if (isReplying)
                              _buildReplyPreview((state as ChatLoaded).replyingToMessage!, colorScheme),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              color: colorScheme.surface,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.attach_file, color: colorScheme.primary),
                                    onPressed: _pickAndSendImage, // Trigger image picker
                                  ),

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

  Widget _buildReplyPreview(MessageEntity message, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border(
          left: BorderSide(color: colorScheme.primary, width: 4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Replying to",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  message.decryptedText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => _chatBloc.add(ReplyCanceled()),
          ),
        ],
      ),
    );
  }
  Widget _buildMessageBubble(
      MessageEntity message,
      bool isMe,
      ColorScheme colorScheme,
      MessageEntity? repliedMessage) {

    bool isDeleted = message.decryptedText.contains('🚫');
    final size = MediaQuery.of(context).size;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: IntrinsicWidth(
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
          constraints: BoxConstraints(
            maxWidth: size.width * 0.75,
            minWidth: 60,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDeleted
                ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
                : (isMe ? colorScheme.primary : colorScheme.surfaceContainerHighest),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align internal content to start
            children: [
              if (repliedMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.black.withOpacity(0.1) : colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: isMe ? Colors.white70 : colorScheme.primary,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        repliedMessage.senderId == widget.currentUser.id ? "You" : widget.receiverUser.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isMe ? Colors.white : colorScheme.primary,
                        ),
                      ),
                      Text(
                        repliedMessage.decryptedText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe ? Colors.white70 : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

              // --- Image Rendering Block ---
              if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty && !isDeleted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      message.mediaUrl!, // Backend absolute URL
                      width: size.width * 0.65,
                      height: size.width * 0.65,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: size.width * 0.65,
                          height: size.width * 0.65,
                          color: colorScheme.surfaceContainerHighest,
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: size.width * 0.65,
                        height: size.width * 0.65,
                        color: colorScheme.surfaceContainerHighest,
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                      ),
                    ),
                  ),
                ),

              // --- Text Rendering Block ---
              // Only show text if it's not the default image placeholder, or if it's deleted
              if (message.mediaUrl == null || message.mediaUrl!.isEmpty || message.decryptedText != '📷 Photo' || isDeleted)
                Text(
                  message.decryptedText,
                  style: TextStyle(
                    fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                    color: isMe ? colorScheme.onPrimary : colorScheme.onSurface,
                    fontSize: 15,
                  ),
                ),

              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Push metadata to the bottom right
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isMe ? colorScheme.onPrimary.withOpacity(0.7) : colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  if (isMe && !isDeleted) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.status == 'read' ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.status == 'read' ? Colors.blue.shade200 : colorScheme.onPrimary.withOpacity(0.7),
                    ),
                  ]
                ],
              )
            ],
          ),
        ),
      ),
    );
  }}