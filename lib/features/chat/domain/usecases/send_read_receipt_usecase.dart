import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:dartz/dartz.dart';

class SendReadReceiptUseCase {
  final IChatRepository repository;

  SendReadReceiptUseCase({required this.repository});

  Future<Either<Failures, Unit>> call(String messageId){
    return repository.sendReadReceipt(messageId);
  }
}