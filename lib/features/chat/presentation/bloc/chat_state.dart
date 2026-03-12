// lib/features/chat/presentation/bloc/chat_state.dart

import 'package:equatable/equatable.dart';
import 'package:connect/features/chat/domain/entities/message_entity.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<MessageEntity> messages;
  final bool isTyping;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? editingMessageId;

  const ChatLoaded({
    required this.messages,
    this.isTyping = false,
    this.isOnline = false,
    this.lastSeen,
    this.editingMessageId,
  });

  ChatLoaded copyWith({
    List<MessageEntity>? messages,
    bool? isTyping,
    bool? isOnline,
    DateTime? lastSeen,
    String? editingMessageId,
    bool clearEditing = false,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      editingMessageId: clearEditing ? null : (editingMessageId ?? this.editingMessageId),
    );
  }

  @override
  List<Object?> get props => [messages, isTyping, isOnline, lastSeen, editingMessageId];
}

class ChatError extends ChatState {
  final String message;
  const ChatError({required this.message});
  @override
  List<Object> get props => [message];
}