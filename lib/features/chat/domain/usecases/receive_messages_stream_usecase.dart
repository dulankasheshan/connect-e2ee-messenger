import 'package:connect/features/chat/domain/entities/message_entity.dart';
import 'package:connect/features/chat/domain/repositories/i_chat_repository.dart';

class ReceiveMessagesStreamUseCase {

  final IChatRepository repository;

  ReceiveMessagesStreamUseCase({required this.repository});

  Stream<MessageEntity> call(){
    return repository.receiveMessagesStream();
  }
}