import 'package:connect/core/errors/failures.dart';
import 'package:dartz/dartz.dart';

import '../repositories/i_chat_repository.dart';

class EditMessageUseCase {
  final IChatRepository repository;

  EditMessageUseCase(this.repository);

  Future<Either<Failures, void>> call(String messageId, String newPlaintext, String receiverPublicKey) async {
    return await repository.editMessage(messageId, newPlaintext, receiverPublicKey);
  }
}