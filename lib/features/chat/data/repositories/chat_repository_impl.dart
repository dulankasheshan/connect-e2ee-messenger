import 'package:connect/core/crypto/crypto_service.dart';
import 'package:connect/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:connect/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/message_entity.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements IChatRepository {
  final CryptoService cryptoService;
  final IChatRemoteDatasource remoteDatasource;

  ChatRepositoryImpl({
    required this.cryptoService,
    required this.remoteDatasource,
  });

  // ==========================================
  // 1. SIMPLE METHODS
  // ==========================================

  @override
  Future<Either<Failures, Unit>> connectSocket() async {
    try {
      await remoteDatasource.connectSocket();
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failures, Unit>> disconnectSocket() async {
    try {
      await remoteDatasource.disconnectSocket();
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failures, Unit>> sendReadReceipt(String messageId) async {
    try {
      await remoteDatasource.sendReadReceipt(messageId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failures, Unit>> sendTypingStatus(String receiverId, bool isTyping) async {
    try {
      await remoteDatasource.sendTypingStatus(receiverId, isTyping);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Stream<Map<String, dynamic>> receiveMessageStatusStream() {
    return remoteDatasource.receiveMessageStatusStream();
  }

  @override
  Stream<Map<String, dynamic>> receiveTypingStream() {
    return remoteDatasource.receiveTypingStream();
  }


// ==========================================
  // 2. ENCRYPTION (SENDING)
  // ==========================================

  @override
  Future<Either<Failures, Unit>> sendMessage(MessageEntity message, String receiverPublicKey) async {
    try {
      // 1. Encrypt the plaintext message
      final encryptedText = await cryptoService.encryptMessage(
        message.decryptedText,
        receiverPublicKey,
      );

      // 2. Map Entity to Model, replacing plain text with encrypted text
      final messageModel = MessageModel(
        id: message.id,
        senderId: message.senderId,
        receiverId: message.receiverId,
        decryptedText: encryptedText, // This holds the ciphertext for the network!
        status: message.status,
        createdAt: message.createdAt,
        clientTempId: message.clientTempId,
        isDeleted: message.isDeleted,
        isEdited: message.isEdited,
        mediaType: message.mediaType,
        mediaUrl: message.mediaUrl,
        replyToMsgId: message.replyToMsgId,
      );

      // 3. Send to server
      await remoteDatasource.sendMessage(messageModel, receiverPublicKey);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('Failed to send encrypted message.'));
    }
  }



  // ==========================================
  // 3. DECRYPTION (RECEIVING & HISTORY)
  // ==========================================

  @override
  Stream<MessageEntity> receiveMessagesStream() {
    // asyncMap allows us to do async operations (like decryption) on stream events
    return remoteDatasource.receiveMessagesStream().asyncMap((model) async {
      try {
        // Decrypt the incoming ciphertext
        final decryptedText = await cryptoService.decryptMessage(model.decryptedText);

        return _mapModelToEntity(model, decryptedText);
      } catch (e) {
        // If decryption fails, show a placeholder instead of crashing
        return _mapModelToEntity(model, '🔒︎ [Encrypted Message]');
      }
    });
  }

  @override
  Future<Either<Failures, List<MessageEntity>>> syncOfflineMessages() async {
    try {
      final models = await remoteDatasource.syncOfflineMessages();
      final entities = await _decryptMessageList(models);
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('Failed to sync messages.'));
    }
  }

  @override
  Future<Either<Failures, List<MessageEntity>>> getChatHistory(String userId, {int limit = 20, int offset = 0}) async {
    try {
      final models = await remoteDatasource.getChatHistory(userId, limit: limit, offset: offset);
      final entities = await _decryptMessageList(models);
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('Failed to load chat history.'));
    }
  }

  // --- Helper Methods ---

  Future<List<MessageEntity>> _decryptMessageList(List<MessageModel> models) async {
    List<MessageEntity> entities = [];
    for (var model in models) {
      try {
        final decryptedText = await cryptoService.decryptMessage(model.decryptedText);
        entities.add(_mapModelToEntity(model, decryptedText));
      } catch (e) {
        entities.add(_mapModelToEntity(model, '🔒︎ [Encrypted Message]'));
      }
    }
    return entities;
  }

  MessageEntity _mapModelToEntity(MessageModel model, String decryptedText) {
    return MessageEntity(
      id: model.id,
      senderId: model.senderId,
      receiverId: model.receiverId,
      decryptedText: decryptedText, // Real plain text!
      status: model.status,
      createdAt: model.createdAt,
      clientTempId: model.clientTempId,
      isDeleted: model.isDeleted,
      isEdited: model.isEdited,
      mediaType: model.mediaType,
      mediaUrl: model.mediaUrl,
      replyToMsgId: model.replyToMsgId,
    );
  }

}
