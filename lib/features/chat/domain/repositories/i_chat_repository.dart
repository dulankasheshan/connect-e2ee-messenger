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

  // --- REST Actions (History & Sync) ---
  Future<Either<Failures, List<MessageEntity>>> syncOfflineMessages();
  Future<Either<Failures, List<MessageEntity>>> getChatHistory(String userId, {int limit = 20, int offset = 0});

  // --- Streams (Listening to Server) ---
  Stream<MessageEntity> receiveMessagesStream();
  Stream<Map<String, dynamic>> receiveMessageStatusStream();
  Stream<Map<String, dynamic>> receiveTypingStream();
}