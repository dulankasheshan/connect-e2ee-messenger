import 'package:equatable/equatable.dart';
import 'package:connect/features/chat/domain/entities/message_entity.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

// --- User Actions ---
class ConnectSocketRequested extends ChatEvent {}

class DisconnectSocketRequested extends ChatEvent {}

class LoadChatHistoryRequested extends ChatEvent {
  final String userId;
  const LoadChatHistoryRequested({required this.userId});
  @override
  List<Object> get props => [userId];
}

class SendMessageRequested extends ChatEvent {
  final MessageEntity message;
  final String receiverPublicKey;
  const SendMessageRequested({required this.message, required this.receiverPublicKey});
  @override
  List<Object> get props => [message, receiverPublicKey];
}

class SendReadReceiptRequested extends ChatEvent {
  final String messageId;
  const SendReadReceiptRequested({required this.messageId});
  @override
  List<Object> get props => [messageId];
}

class SendTypingStatusRequested extends ChatEvent {
  final String receiverId;
  final bool isTyping;
  const SendTypingStatusRequested({required this.receiverId, required this.isTyping});
  @override
  List<Object> get props => [receiverId, isTyping];
}

// --- Stream Events (Triggered internally by Streams) ---
class MessageReceived extends ChatEvent {
  final MessageEntity message;
  const MessageReceived({required this.message});
  @override
  List<Object> get props => [message];
}

class MessageStatusUpdated extends ChatEvent {
  final Map<String, dynamic> statusData;
  const MessageStatusUpdated({required this.statusData});
  @override
  List<Object> get props => [statusData];
}

class TypingStatusReceived extends ChatEvent {
  final Map<String, dynamic> typingData;
  const TypingStatusReceived({required this.typingData});
  @override
  List<Object> get props => [typingData];
}