import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:dartz/dartz.dart';

class ConnectSocketUseCase {
  final IChatRepository repository;

  ConnectSocketUseCase({required this.repository});

  Future<Either<Failures, Unit>> call() {
     return repository.connectSocket();
  }
}