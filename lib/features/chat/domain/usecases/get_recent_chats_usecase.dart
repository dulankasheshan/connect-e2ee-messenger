import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/chat/domain/entities/message_entity.dart';
import 'package:connect/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:dartz/dartz.dart';

class GetRecentChatsUseCase {
  final IChatRepository repository;

  GetRecentChatsUseCase(this.repository);

  Future<Either<Failures, List<MessageEntity>>> call() {
    return repository.getRecentChats();
  }
}