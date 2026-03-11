import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/chat/domain/entities/message_entity.dart';
import 'package:connect/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:dartz/dartz.dart';

class SendMessageUseCase {
  final IChatRepository repository;

  SendMessageUseCase({required this.repository});

  Future<Either<Failures, Unit>> call(MessageEntity message, String receiverPublicKey){
    return repository.sendMessage(message, receiverPublicKey);
  }
}