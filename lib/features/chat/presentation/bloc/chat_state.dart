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

  const ChatLoaded({
    required this.messages,
    this.isTyping = false,
  });

  // copyWith helps us to update only one variable (e.g. isTyping)
  // without losing the old messages list.
  ChatLoaded copyWith({
    List<MessageEntity>? messages,
    bool? isTyping,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  @override
  List<Object?> get props => [messages, isTyping];
}

class ChatError extends ChatState {
  final String message;
  const ChatError({required this.message});
  @override
  List<Object> get props => [message];
}