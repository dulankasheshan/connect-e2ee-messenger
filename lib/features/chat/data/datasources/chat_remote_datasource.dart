import 'dart:io';

import 'package:connect/features/chat/data/models/message_model.dart';

abstract class IChatRemoteDatasource {
  // --- Socket Connections ---
  Future<void> connectSocket();
  Future<void> disconnectSocket();

  // --- Real-time Actions ---
  Future<void> sendMessage(MessageModel message, String receiverPublicKey);
  Future<void> sendReadReceipt(String messageId);
  Future<void> sendTypingStatus(String receiverId, bool isTyping);

  Future<void> editMessage(String messageId, String newEncryptedText);
  Future<void> deleteMessage(String messageId);

  Future<Map<String, dynamic>> uploadMedia(File file);

  // --- REST Actions (History & Sync) ---
  Future<List<MessageModel>> syncOfflineMessages();
  Future< List<MessageModel>> getChatHistory(String userId, {int limit = 20, int offset = 0});

  // --- Streams (Listening to Server) ---
  Stream<MessageModel> receiveMessagesStream();
  Stream<Map<String, dynamic>> receiveMessageStatusStream();
  Stream<Map<String, dynamic>> receiveTypingStream();
  Stream<Map<String, dynamic>> receiveOnlineStatusStream();
  Stream<Map<String, dynamic>> receiveEditedMessageStream();
  Stream<Map<String, dynamic>> receiveDeletedMessageStream();
}