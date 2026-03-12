import 'package:connect/features/chat/domain/repositories/i_chat_repository.dart';

class ReceiveOnlineStatusStreamUseCase {
  final IChatRepository repository;

  ReceiveOnlineStatusStreamUseCase(this.repository);

  Stream<Map<String, dynamic>> call() {
    return repository.receiveOnlineStatusStream();
  }
}