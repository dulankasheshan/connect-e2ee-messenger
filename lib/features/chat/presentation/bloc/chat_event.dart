import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:connect/features/chat/domain/entities/message_entity.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ConnectSocketRequested extends ChatEvent {}

class DisconnectSocketRequested extends ChatEvent {}

class LoadChatHistoryRequested extends ChatEvent {
  final String userId;
  final bool isOnline;

  const LoadChatHistoryRequested({
    required this.userId,
    this.isOnline = false,
  });

  @override
  List<Object> get props => [userId, isOnline];
}

class SendMessageRequested extends ChatEvent {
  final MessageEntity message;
  final String receiverPublicKey;

  const SendMessageRequested({
    required this.message,
    required this.receiverPublicKey,
  });

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

  const SendTypingStatusRequested({
    required this.receiverId,
    required this.isTyping,
  });

  @override
  List<Object> get props => [receiverId, isTyping];
}

class EditModeToggled extends ChatEvent {
  final String? messageId;
  const EditModeToggled({this.messageId});
  @override
  List<Object?> get props => [messageId];
}

class EditMessageRequested extends ChatEvent {
  final String messageId;
  final String newPlaintext;
  final String receiverPublicKey;

  const EditMessageRequested({
    required this.messageId,
    required this.newPlaintext,
    required this.receiverPublicKey,
  });

  @override
  List<Object> get props => [messageId, newPlaintext, receiverPublicKey];
}

class DeleteMessageRequested extends ChatEvent {
  final String messageId;

  const DeleteMessageRequested({required this.messageId});

  @override
  List<Object> get props => [messageId];
}

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

class OnlineStatusReceived extends ChatEvent {
  final Map<String, dynamic> statusData;
  const OnlineStatusReceived({required this.statusData});
  @override
  List<Object> get props => [statusData];
}

class EditedMessageReceived extends ChatEvent {
  final Map<String, dynamic> editData;
  const EditedMessageReceived({required this.editData});
  @override
  List<Object> get props => [editData];
}

class DeletedMessageReceived extends ChatEvent {
  final Map<String, dynamic> deleteData;
  const DeletedMessageReceived({required this.deleteData});
  @override
  List<Object> get props => [deleteData];
}

class ClearAllChatHistoryRequested extends ChatEvent {
  final String chatUserId;
  const ClearAllChatHistoryRequested({required this.chatUserId});
  @override
  List<Object> get props => [chatUserId];
}

class ReplyToMessageSelected extends ChatEvent {
  final MessageEntity message;

  const ReplyToMessageSelected({required this.message});

  @override
  List<Object> get props => [message];
}

class ReplyCanceled extends ChatEvent {}

class SendMediaMessageRequested extends ChatEvent {
  final File mediaFile;
  final String? caption;
  final String receiverPublicKey;
  final String receiverId;
  final String senderId;
  final String? replyToMsgId;

  const SendMediaMessageRequested({
    required this.mediaFile,
    this.caption,
    required this.receiverPublicKey,
    required this.receiverId,
    required this.senderId,
    this.replyToMsgId,
  });

  @override
  List<Object?> get props => [mediaFile, caption, receiverPublicKey, receiverId, senderId, replyToMsgId];
}