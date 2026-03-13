import 'package:connect/features/chat/domain/repositories/i_chat_repository.dart';

class ReceiveDeletedMessageStreamUseCase {
  final IChatRepository repository;

  ReceiveDeletedMessageStreamUseCase(this.repository);

  Stream<Map<String, dynamic>> call() {
    return repository.receiveDeletedMessageStream();
  }
}