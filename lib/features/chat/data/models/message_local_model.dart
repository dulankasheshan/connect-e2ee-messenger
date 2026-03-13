import 'package:isar/isar.dart';

part 'message_local_model.g.dart';

@collection
class MessageLocalModel {
  // Isar requires the property to be exactly named 'id'
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String messageId;

  @Index()
  late String senderId;

  @Index()
  late String receiverId;

  @Index()
  late String chatUserId;

  late String decryptedText;

  late String status;

  @Index()
  late DateTime createdAt;

  String? clientTempId;
  String? mediaUrl;
  String? mediaType;
  String? replyToMsgId;

  bool isDeleted = false;
  bool isEdited = false;
}