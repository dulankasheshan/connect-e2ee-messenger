import 'package:connect/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import '../repositories/i_chat_repository.dart';

class ClearAllChatHistoryUseCase {
  final IChatRepository repository;

  ClearAllChatHistoryUseCase(this.repository);

  Future<Either<Failures, void>> call(String chatUserId) async {
    return await repository.clearAllChatHistory(chatUserId);
  }
}