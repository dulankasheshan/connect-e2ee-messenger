import 'dart:io';

import 'package:connect/core/crypto/crypto_service.dart';
import 'package:connect/core/errors/exceptions.dart';
import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:connect/features/chat/data/datasources/chat_local_datasource.dart';
import 'package:connect/features/chat/data/models/message_model.dart';
import 'package:connect/features/chat/data/models/message_local_model.dart';
import 'package:connect/features/chat/domain/entities/message_entity.dart';
import 'package:connect/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:dartz/dartz.dart';

import '../models/user_local_model.dart';

class ChatRepositoryImpl implements IChatRepository {
  final CryptoService cryptoService;
  final IChatRemoteDatasource remoteDatasource;
  final IChatLocalDatasource localDatasource;

  ChatRepositoryImpl({
    required this.cryptoService,
    required this.remoteDatasource,
    required this.localDatasource,
  });

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
      await localDatasource.updateMessageStatus(messageId, 'read');
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
    return remoteDatasource.receiveMessageStatusStream().map((statusData) {
      // Backend uses 'messageId' (CamelCase) for this specific event
      final realMessageId = statusData['messageId'] as String?;
      final status = statusData['status'] as String?;
      final tempId = statusData['client_temp_id'] as String?;

      if (realMessageId != null && status != null) {
        // Swap the temporary ID with the Real Server ID in the Local Database
        localDatasource.updateMessageIdAndStatus(tempId ?? realMessageId, realMessageId, status);
      }
      return statusData;
    });
  }

  @override
  Stream<Map<String, dynamic>> receiveTypingStream() {
    return remoteDatasource.receiveTypingStream();
  }

  @override
  Stream<Map<String, dynamic>> receiveOnlineStatusStream() {
    return remoteDatasource.receiveOnlineStatusStream();
  }

  @override
  Stream<Map<String, dynamic>> receiveEditedMessageStream() {
    return remoteDatasource.receiveEditedMessageStream().asyncMap((data) async {
      final messageId = data['messageId'] as String?;
      final newEncryptedText = data['newEncryptedText'] as String?;

      if (messageId != null && newEncryptedText != null) {
        try {
          final decryptedText = await cryptoService.decryptMessage(newEncryptedText);
          data['newEncryptedText'] = decryptedText;
          await localDatasource.updateMessageText(messageId, decryptedText);
        } catch (e) {
          data['newEncryptedText'] = '🔒 [Encrypted Message]';
        }
      }
      return data;
    });
  }

  @override
  Stream<Map<String, dynamic>> receiveDeletedMessageStream() {
    return remoteDatasource.receiveDeletedMessageStream().map((data) {
      final messageId = data['messageId'] as String?;
      if (messageId != null) {
        localDatasource.deleteMessage(messageId);
      }
      return data;
    });
  }

  @override
  Future<Either<Failures, Unit>> sendMessage(MessageEntity message, String receiverPublicKey) async {
    try {
      final encryptedText = await cryptoService.encryptMessage(
        message.decryptedText,
        receiverPublicKey,
      );

      final messageModel = MessageModel(
        id: message.id,
        senderId: message.senderId,
        receiverId: message.receiverId,
        decryptedText: encryptedText,
        status: message.status,
        createdAt: message.createdAt,
        clientTempId: message.clientTempId,
        isDeleted: message.isDeleted,
        isEdited: message.isEdited,
        mediaType: message.mediaType,
        mediaUrl: message.mediaUrl,
        replyToMsgId: message.replyToMsgId,
      );

      final localModel = _mapEntityToLocalModel(message, message.receiverId);
      await localDatasource.saveMessage(localModel);

      await remoteDatasource.sendMessage(messageModel, receiverPublicKey);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('Failed to send encrypted message.'));
    }
  }



  @override
  Stream<MessageEntity> receiveMessagesStream() {
    return remoteDatasource.receiveMessagesStream().asyncMap((model) async {
      String decryptedText;
      try {
        decryptedText = await cryptoService.decryptMessage(model.decryptedText);
      } catch (e) {
        decryptedText = '🔒 [Encrypted Message]';
      }

      final entity = _mapModelToEntity(model, decryptedText);

      final localModel = _mapEntityToLocalModel(entity, entity.senderId);
      await localDatasource.saveMessage(localModel);

      return entity;
    });
  }

  @override
  Future<Either<Failures, List<MessageEntity>>> getChatHistory(String userId, {int limit = 20, int offset = 0}) async {
    try {
      // Fetch directly from the local Isar database for faster and offline-first performance
      final localModels = await localDatasource.getChatHistory(userId, limit: limit, offset: offset);
      final entities = localModels.map(_mapLocalModelToEntity).toList();
      return Right(entities);
    } catch (e) {
      return const Left(ServerFailure('Failed to load chat history.'));
    }
  }

  @override
  Future<Either<Failures, List<MessageEntity>>> syncOfflineMessages() async {
    try {
      final models = await remoteDatasource.syncOfflineMessages();
      final entities = await _decryptMessageList(models);

      // Save all synced messages locally
      if (entities.isNotEmpty) {
        final localModels = entities.map((e) => _mapEntityToLocalModel(e, e.senderId)).toList();
        await localDatasource.saveMessages(localModels);
      }

      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('Failed to sync messages.'));
    }
  }

  @override
  Future<Either<Failures, void>> editMessage(String messageId, String newPlaintext, String receiverPublicKey) async {
    try {
      final encryptedText = await cryptoService.encryptMessage(newPlaintext, receiverPublicKey);

      await remoteDatasource.editMessage(messageId, encryptedText);
      await localDatasource.updateMessageText(messageId, newPlaintext);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failures, void>> deleteMessage(String messageId) async {
    try {
      await remoteDatasource.deleteMessage(messageId);
      await localDatasource.deleteMessage(messageId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }



  @override
  Future<Either<Failures, Unit>> saveCachedUser({
    required String id,
    required String name,
    required String username,
    String? profilePicUrl,
  }) async {
    try {
      final userModel = UserLocalModel()
        ..userId = id
        ..name = name
        ..username = username
        ..profilePicUrl = profilePicUrl
        ..lastUpdated = DateTime.now();

      await localDatasource.saveUserLocally(userModel);
      return const Right(unit);
    } catch (e) {
      return const Left(ServerFailure('Failed to cache user data.'));
    }
  }

  @override
  Future<Either<Failures, Map<String, dynamic>?>> getCachedUser(String userId) async {
    try {
      final user = await localDatasource.getUserLocally(userId);
      if (user != null) {
        return Right({
          'id': user.userId,
          'name': user.name,
          'username': user.username,
          'profilePicUrl': user.profilePicUrl,
          'isOnline': user.isOnline,
          'lastSeen': user.lastSeen,
        });
      }
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Failed to load cached user.'));
    }
  }

  @override
  Future<Either<Failures, List<MessageEntity>>> getRecentChats() async {
    try {
      final localModels = await localDatasource.getRecentChats();
      final entities = localModels.map(_mapLocalModelToEntity).toList();
      return Right(entities);
    } catch (e) {
      return const Left(ServerFailure('Failed to load recent chats.'));
    }
  }

  @override
  Future<Either<Failures, Map<String, dynamic>>> uploadMedia(File file) async {
    try {
      final mediaData = await remoteDatasource.uploadMedia(file);
      return Right(mediaData);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred during upload.'));
    }
  }

  @override
  Future<Either<Failures, void>> clearAllChatHistory(String chatUserId) async {
    try {
      await localDatasource.clearAllChatHistory(chatUserId);
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Failed to clear chat history locally.'));
    }
  }
  
  Future<List<MessageEntity>> _decryptMessageList(List<MessageModel> models) async {
    List<MessageEntity> entities = [];
    for (var model in models) {
      try {
        final decryptedText = await cryptoService.decryptMessage(model.decryptedText);
        entities.add(_mapModelToEntity(model, decryptedText));
      } catch (e) {
        entities.add(_mapModelToEntity(model, '🔒 [Encrypted Message]'));
      }
    }
    return entities;
  }

  MessageEntity _mapModelToEntity(MessageModel model, String decryptedText) {
    return MessageEntity(
      id: model.id,
      senderId: model.senderId,
      receiverId: model.receiverId,
      decryptedText: decryptedText,
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

  MessageEntity _mapLocalModelToEntity(MessageLocalModel localModel) {
    return MessageEntity(
      id: localModel.messageId,
      senderId: localModel.senderId,
      receiverId: localModel.receiverId,
      decryptedText: localModel.decryptedText,
      status: localModel.status,
      createdAt: localModel.createdAt,
      clientTempId: localModel.clientTempId,
      isDeleted: localModel.isDeleted,
      isEdited: localModel.isEdited,
      mediaType: localModel.mediaType,
      mediaUrl: localModel.mediaUrl,
      replyToMsgId: localModel.replyToMsgId,
    );
  }

  MessageLocalModel _mapEntityToLocalModel(MessageEntity entity, String chatUserId) {
    return MessageLocalModel()
      ..messageId = entity.id
      ..senderId = entity.senderId
      ..receiverId = entity.receiverId
      ..chatUserId = chatUserId
      ..decryptedText = entity.decryptedText
      ..status = entity.status
      ..createdAt = entity.createdAt
      ..clientTempId = entity.clientTempId
      ..mediaUrl = entity.mediaUrl
      ..mediaType = entity.mediaType
      ..replyToMsgId = entity.replyToMsgId
      ..isDeleted = entity.isDeleted
      ..isEdited = entity.isEdited;
  }
}