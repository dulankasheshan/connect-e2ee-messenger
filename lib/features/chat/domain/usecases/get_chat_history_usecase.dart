import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/chat/domain/entities/message_entity.dart';
import 'package:connect/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:dartz/dartz.dart';

class GetChatHistoryUseCase {
  final IChatRepository repository;

  GetChatHistoryUseCase({required this.repository});

  Future<Either<Failures, List<MessageEntity>>> call(String userID, {int limit = 20, int offset = 0}){
    return repository.getChatHistory(userID, limit: limit, offset: offset);
  }
}