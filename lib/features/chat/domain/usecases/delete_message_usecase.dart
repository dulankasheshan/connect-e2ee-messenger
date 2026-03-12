import 'package:connect/core/errors/failures.dart';
import 'package:dartz/dartz.dart';

import '../repositories/i_chat_repository.dart';

class DeleteMessageUseCase {
  final IChatRepository repository;

  DeleteMessageUseCase(this.repository);

  Future<Either<Failures, void>> call(String messageId) async {
    return await repository.deleteMessage(messageId);
  }
}