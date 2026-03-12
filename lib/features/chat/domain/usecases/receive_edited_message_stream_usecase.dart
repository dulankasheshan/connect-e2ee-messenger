import 'package:connect/features/chat/domain/repositories/i_chat_repository.dart';

class ReceiveEditedMessageStreamUseCase {
  final IChatRepository repository;

  ReceiveEditedMessageStreamUseCase(this.repository);

  Stream<Map<String, dynamic>> call() {
    return repository.receiveEditedMessageStream();
  }
}