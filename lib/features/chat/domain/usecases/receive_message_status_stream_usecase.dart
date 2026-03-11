import '../repositories/i_chat_repository.dart';

class ReceiveMessageStatusStreamUseCase {
  final IChatRepository repository;

  ReceiveMessageStatusStreamUseCase({required this.repository});

  Stream<Map<String, dynamic>> call(){
    return repository.receiveMessageStatusStream();
  }
}