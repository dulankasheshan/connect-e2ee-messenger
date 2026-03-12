import 'package:isar/isar.dart';
import 'package:connect/features/chat/data/models/message_local_model.dart';
import 'package:connect/features/chat/data/models/user_local_model.dart';

abstract class IChatLocalDatasource {
  Future<void> saveMessage(MessageLocalModel message);
  Future<void> saveMessages(List<MessageLocalModel> messages);
  Future<List<MessageLocalModel>> getChatHistory(String chatUserId, {int limit = 20, int offset = 0});
  Future<List<MessageLocalModel>> getRecentChats();
  Future<void> updateMessageStatus(String messageId, String status);
  Future<void> updateMessageText(String messageId, String newText);
  Future<void> deleteMessage(String messageId);
  Future<void> updateMessageIdAndStatus(String oldId, String newId, String status);
  Future<void> clearAllChatHistory(String chatUserId);

  Future<void> saveUserLocally(UserLocalModel user);
  Future<UserLocalModel?> getUserLocally(String userId);
}

class ChatLocalDatasourceImpl implements IChatLocalDatasource {
  final Isar isar;

  ChatLocalDatasourceImpl({required this.isar});

  @override
  Future<void> saveMessage(MessageLocalModel message) async {
    await isar.writeTxn(() async {
      await isar.messageLocalModels.put(message);
    });
  }

  @override
  Future<void> saveMessages(List<MessageLocalModel> messages) async {
    await isar.writeTxn(() async {
      await isar.messageLocalModels.putAll(messages);
    });
  }

  @override
  Future<List<MessageLocalModel>> getChatHistory(String chatUserId, {int limit = 20, int offset = 0}) async {
    return await isar.messageLocalModels
        .filter()
        .chatUserIdEqualTo(chatUserId)
        .sortByCreatedAtDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  @override
  Future<List<MessageLocalModel>> getRecentChats() async {
    return await isar.messageLocalModels
        .where()
        .sortByCreatedAtDesc()
        .distinctByChatUserId()
        .findAll();
  }

  @override
  Future<void> updateMessageStatus(String messageId, String status) async {
    await isar.writeTxn(() async {
      final message = await isar.messageLocalModels
          .filter()
          .messageIdEqualTo(messageId)
          .findFirst();

      if (message != null) {
        message.status = status;
        await isar.messageLocalModels.put(message);
      }
    });
  }

  @override
  Future<void> updateMessageText(String messageId, String newText) async {
    await isar.writeTxn(() async {
      final message = await isar.messageLocalModels
          .filter()
          .messageIdEqualTo(messageId)
          .findFirst();

      if (message != null) {
        // Local models store the decrypted (plaintext) data
        message.decryptedText = newText;
        await isar.messageLocalModels.put(message);
      }
    });
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await isar.writeTxn(() async {
      final message = await isar.messageLocalModels
          .filter()
          .messageIdEqualTo(messageId)
          .findFirst();

      if (message != null) {
        message.decryptedText = '🚫 This message was deleted';
        await isar.messageLocalModels.put(message);
      }
    });
  }

  @override
  Future<void> saveUserLocally(UserLocalModel user) async {
    await isar.writeTxn(() async {
      await isar.userLocalModels.put(user);
    });
  }

  @override
  Future<UserLocalModel?> getUserLocally(String userId) async {
    return await isar.userLocalModels
        .filter()
        .userIdEqualTo(userId)
        .findFirst();
  }

  @override
  Future<void> updateMessageIdAndStatus(String oldId, String newId, String status) async {
    await isar.writeTxn(() async {
      final message = await isar.messageLocalModels
          .filter()
          .messageIdEqualTo(oldId) // Find using the temporary ID
          .findFirst();

      if (message != null) {
        message.messageId = newId; //  Swap with the REAL ID from the server
        message.status = status;
        await isar.messageLocalModels.put(message);
      }
    });
  }

  @override
  Future<void> clearAllChatHistory(String chatUserId) async {
    await isar.writeTxn(() async {
      await isar.messageLocalModels
          .filter()
          .chatUserIdEqualTo(chatUserId)
          .deleteAll();
    });
  }
}