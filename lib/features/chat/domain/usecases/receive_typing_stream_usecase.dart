import '../repositories/i_chat_repository.dart';

class ReceiveTypingStreamUseCase {
  final IChatRepository repository;

  ReceiveTypingStreamUseCase({required this.repository});

  Stream<Map<String, dynamic>> call(){
    return repository.receiveTypingStream();
  }
}