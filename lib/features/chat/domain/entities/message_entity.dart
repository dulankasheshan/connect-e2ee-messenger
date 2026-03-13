import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String decryptedText; // We only keep decrypted text in the UI layer
  final String? mediaUrl;
  final String? mediaType;
  final String status; // 'sent', 'delivered', 'read'
  final String? replyToMsgId;
  final bool isEdited;
  final bool isDeleted;
  final DateTime createdAt;
  final String? clientTempId; // To identify pending messages before server confirms

  const MessageEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.decryptedText,
    this.mediaUrl,
    this.mediaType,
    required this.status,
    this.replyToMsgId,
    this.isEdited = false,
    this.isDeleted = false,
    required this.createdAt,
    this.clientTempId,
  });

  @override
  List<Object?> get props => [
    id,
    senderId,
    receiverId,
    decryptedText,
    mediaUrl,
    mediaType,
    status,
    replyToMsgId,
    isEdited,
    isDeleted,
    createdAt,
    clientTempId,
  ];
}