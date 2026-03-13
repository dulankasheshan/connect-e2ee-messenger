import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:dartz/dartz.dart';

class SendTypingStatusUseCase {
  final IChatRepository repository;

  SendTypingStatusUseCase({required this.repository});

  Future<Either<Failures, Unit>> call(String receiverId, bool isTyping){
    return repository.sendTypingStatus(receiverId, isTyping);
  }
}