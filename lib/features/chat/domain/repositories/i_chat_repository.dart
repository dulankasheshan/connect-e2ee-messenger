import 'package:dartz/dartz.dart';
import 'package:connect/core/errors/failures.dart';
import '../entities/message_entity.dart';

abstract class IChatRepository {
  // --- Socket Connections ---
  Future<Either<Failures, Unit>> connectSocket();
  Future<Either<Failures, Unit>> disconnectSocket();

  // --- Real-time Actions ---
  Future<Either<Failures, Unit>> sendMessage(MessageEntity message, String receiverPublicKey);
  Future<Either<Failures, Unit>> sendReadReceipt(String messageId);
  Future<Either<Failures, Unit>> sendTypingStatus(String receiverId, bool isTyping);

// Edited to include receiverPublicKey for E2EE encryption
  Future<Either<Failures, void>> editMessage(String messageId, String newPlaintext, String receiverPublicKey);
  Future<Either<Failures, void>> deleteMessage(String messageId);

  // --- REST Actions (History & Sync) ---
  Future<Either<Failures, List<MessageEntity>>> syncOfflineMessages();
  Future<Either<Failures, List<MessageEntity>>> getChatHistory(String userId, {int limit = 20, int offset = 0});
  Future<Either<Failures, List<MessageEntity>>> getRecentChats();

  // --- Streams (Listening to Server) ---
  Stream<MessageEntity> receiveMessagesStream();
  Stream<Map<String, dynamic>> receiveMessageStatusStream();
  Stream<Map<String, dynamic>> receiveTypingStream();
  Stream<Map<String, dynamic>> receiveOnlineStatusStream();
  Stream<Map<String, dynamic>> receiveEditedMessageStream();
  Stream<Map<String, dynamic>> receiveDeletedMessageStream();

  // --- User Cache Methods ---
  Future<Either<Failures, Unit>> saveCachedUser({
    required String id,
    required String name,
    required String username,
    String? profilePicUrl,
  });

  // Returns user data as a Map to avoid complex cross-feature domain dependencies
  Future<Either<Failures, Map<String, dynamic>?>> getCachedUser(String userId);

  Future<Either<Failures, void>> clearAllChatHistory(String chatUserId);
}