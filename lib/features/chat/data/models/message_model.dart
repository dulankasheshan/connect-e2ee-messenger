import 'package:connect/features/chat/domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.decryptedText,
    required super.status,
    required super.createdAt,
    super.clientTempId,
    super.isDeleted = false,
    super.isEdited = false,
    super.mediaType,
    super.mediaUrl,
    super.replyToMsgId,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      // We store the incoming encrypted text here temporarily.
      // The Domain layer (UseCase) will replace this with decrypted text later.
      decryptedText: json['encrypted_text'] as String,
      status: json['status'] as String,
      // createdAt is required in the entity, so we parse it directly
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),

      // Convert backend 1/0 to boolean
      isDeleted: json['is_deleted'] == 1,
      isEdited: json['is_edited'] == 1,

      // These can be null, so we use 'as String?'
      mediaType: json['media_type'] as String?,
      mediaUrl: json['media_url'] as String?,
      replyToMsgId: json['reply_to_msg_id'] as String?,
      clientTempId: json['client_temp_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'encrypted_text': decryptedText,
      'status': status,
      'created_at': createdAt.toUtc().toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'is_edited': isEdited ? 1 : 0,
      'media_type': mediaType,
      'media_url': mediaUrl,
      'reply_to_msg_id': replyToMsgId,
      'client_temp_id': clientTempId,
    };
  }
}