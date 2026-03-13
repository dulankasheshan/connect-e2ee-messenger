import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connect/features/chat/domain/entities/message_entity.dart';
import 'package:uuid/uuid.dart';

import '../../domain/usecases/clear_all_chat_history_usecase.dart';
import '../../domain/usecases/connect_socket_usecase.dart';
import '../../domain/usecases/disconnect_socket_usecase.dart';
import '../../domain/usecases/get_chat_history_usecase.dart';
import '../../domain/usecases/receive_deleted_message_stream_usecase.dart';
import '../../domain/usecases/receive_edited_message_stream_usecase.dart';
import '../../domain/usecases/receive_message_status_stream_usecase.dart';
import '../../domain/usecases/receive_messages_stream_usecase.dart';
import '../../domain/usecases/receive_typing_stream_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/send_read_receipt_usecase.dart';
import '../../domain/usecases/send_typing_status_usecase.dart';
import '../../domain/usecases/sync_offline_messages_usecase.dart';
import '../../domain/usecases/receive_online_status_stream_usecase.dart';
import '../../domain/usecases/edit_message_usecase.dart';
import '../../domain/usecases/delete_message_usecase.dart';

import '../../domain/usecases/upload_media_usecase.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ConnectSocketUseCase connectSocketUseCase;
  final DisconnectSocketUseCase disconnectSocketUseCase;
  final GetChatHistoryUseCase getChatHistoryUseCase;
  final ReceiveMessageStatusStreamUseCase receiveMessageStatusStreamUseCase;
  final ReceiveMessagesStreamUseCase receiveMessagesStreamUseCase;
  final ReceiveTypingStreamUseCase receiveTypingStreamUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final SendReadReceiptUseCase sendReadReceiptUseCase;
  final SendTypingStatusUseCase sendTypingStatusUseCase;
  final SyncOfflineMessagesUseCase syncOfflineMessagesUseCase;
  final ReceiveOnlineStatusStreamUseCase receiveOnlineStatusStreamUseCase;
  final EditMessageUseCase editMessageUseCase;
  final DeleteMessageUseCase deleteMessageUseCase;
  final ReceiveEditedMessageStreamUseCase receiveEditedMessageStreamUseCase;
  final ReceiveDeletedMessageStreamUseCase receiveDeletedMessageStreamUseCase;
  final ClearAllChatHistoryUseCase clearAllChatHistoryUseCase;
  final UploadMediaUseCase uploadMediaUseCase;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _onlineStatusSubscription;
  StreamSubscription? _editedMessageSubscription;
  StreamSubscription? _deletedMessageSubscription;

  ChatBloc({
    required this.connectSocketUseCase,
    required this.disconnectSocketUseCase,
    required this.getChatHistoryUseCase,
    required this.receiveMessageStatusStreamUseCase,
    required this.receiveMessagesStreamUseCase,
    required this.receiveTypingStreamUseCase,
    required this.sendMessageUseCase,
    required this.sendReadReceiptUseCase,
    required this.sendTypingStatusUseCase,
    required this.syncOfflineMessagesUseCase,
    required this.receiveOnlineStatusStreamUseCase,
    required this.editMessageUseCase,
    required this.deleteMessageUseCase,
    required this.receiveEditedMessageStreamUseCase,
    required this.receiveDeletedMessageStreamUseCase,
    required this.clearAllChatHistoryUseCase,
    required this.uploadMediaUseCase,
  }) : super(ChatInitial()) {

    on<ConnectSocketRequested>(_onConnectSocket);
    on<DisconnectSocketRequested>(_onDisconnectSocket);
    on<LoadChatHistoryRequested>(_onLoadChatHistory);
    on<SendMessageRequested>(_onSendMessage);
    on<SendReadReceiptRequested>(_onSendReadReceipt);
    on<SendTypingStatusRequested>(_onSendTypingStatus);
    on<EditModeToggled>(_onEditModeToggled);
    on<EditMessageRequested>(_onEditMessage);
    on<DeleteMessageRequested>(_onDeleteMessage);

    on<MessageReceived>(_onMessageReceived);
    on<MessageStatusUpdated>(_onMessageStatusUpdated);
    on<TypingStatusReceived>(_onTypingStatusReceived);
    on<OnlineStatusReceived>(_onOnlineStatusReceived);
    on<EditedMessageReceived>(_onEditedMessageReceived);
    on<DeletedMessageReceived>(_onDeletedMessageReceived);
    on<ClearAllChatHistoryRequested>(_onClearAllChatHistory);
    on<ReplyToMessageSelected>(_onReplyToMessageSelected);
    on<ReplyCanceled>(_onReplyCanceled);
    on<SendMediaMessageRequested>(_onSendMediaMessage);
  }

  Future<void> _onConnectSocket(ConnectSocketRequested event, Emitter<ChatState> emit) async {
    final result = await connectSocketUseCase();
    result.fold(
          (failure) => emit(ChatError(message: failure.message)),
          (_) {
        _messageSubscription = receiveMessagesStreamUseCase().listen(
              (message) => add(MessageReceived(message: message)),
        );
        _statusSubscription = receiveMessageStatusStreamUseCase().listen(
              (statusData) => add(MessageStatusUpdated(statusData: statusData)),
        );
        _typingSubscription = receiveTypingStreamUseCase().listen(
              (typingData) => add(TypingStatusReceived(typingData: typingData)),
        );
        _onlineStatusSubscription = receiveOnlineStatusStreamUseCase().listen(
              (statusData) => add(OnlineStatusReceived(statusData: statusData)),
        );
        _editedMessageSubscription = receiveEditedMessageStreamUseCase().listen(
              (data) => add(EditedMessageReceived(editData: data)),
        );
        _deletedMessageSubscription = receiveDeletedMessageStreamUseCase().listen(
              (data) => add(DeletedMessageReceived(deleteData: data)),
        );
      },
    );
  }

  Future<void> _onDisconnectSocket(DisconnectSocketRequested event, Emitter<ChatState> emit) async {
    await disconnectSocketUseCase();
    _cancelSubscriptions();
    emit(ChatInitial());
  }

  Future<void> _onLoadChatHistory(LoadChatHistoryRequested event, Emitter<ChatState> emit) async {
    bool currentOnline = false;
    if (state is ChatLoaded) {
      currentOnline = (state as ChatLoaded).isOnline;
    }

    final finalIsOnline = currentOnline || event.isOnline;

    emit(ChatLoading());

    await syncOfflineMessagesUseCase();

    final result = await getChatHistoryUseCase(event.userId);
    result.fold(
          (failure) => emit(ChatError(message: failure.message)),
          (messages) => emit(ChatLoaded(messages: messages, isOnline: finalIsOnline)),
    );
  }

  Future<void> _onSendMessage(SendMessageRequested event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final updatedMessages = List<MessageEntity>.from(currentState.messages)..insert(0, event.message);

      // Clear the replyingToMessage state after sending
      emit(currentState.copyWith(
        messages: updatedMessages,
        clearReplyingTo: true,
      ));
    }

    await sendMessageUseCase(event.message, event.receiverPublicKey);
  }

  void _onEditModeToggled(EditModeToggled event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      emit(currentState.copyWith(
          editingMessageId: event.messageId,
          clearEditing: event.messageId == null
      ));
    }
  }

  Future<void> _onEditMessage(EditMessageRequested event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final updatedMessages = currentState.messages.map((m) {
        if (m.id == event.messageId) {
          return MessageEntity(
            id: m.id,
            senderId: m.senderId,
            receiverId: m.receiverId,
            decryptedText: event.newPlaintext,
            status: m.status,
            createdAt: m.createdAt,
            clientTempId: m.clientTempId,
          );
        }
        return m;
      }).toList();
      emit(currentState.copyWith(messages: updatedMessages, clearEditing: true));
    }
    await editMessageUseCase(event.messageId, event.newPlaintext, event.receiverPublicKey);
  }

  Future<void> _onDeleteMessage(DeleteMessageRequested event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final updatedMessages = currentState.messages.map((m) {
        if (m.id == event.messageId) {
          return MessageEntity(
            id: m.id,
            senderId: m.senderId,
            receiverId: m.receiverId,
            decryptedText: '🚫 This message was deleted',
            status: m.status,
            createdAt: m.createdAt,
            clientTempId: m.clientTempId,
          );
        }
        return m;
      }).toList();
      emit(currentState.copyWith(messages: updatedMessages));
    }
    await deleteMessageUseCase(event.messageId);
  }

  Future<void> _onSendReadReceipt(SendReadReceiptRequested event, Emitter<ChatState> emit) async {
    await sendReadReceiptUseCase(event.messageId);
  }

  Future<void> _onSendTypingStatus(SendTypingStatusRequested event, Emitter<ChatState> emit) async {
    await sendTypingStatusUseCase(event.receiverId, event.isTyping);
  }

  void _onMessageReceived(MessageReceived event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final updatedMessages = List<MessageEntity>.from(currentState.messages)..insert(0, event.message);
      emit(currentState.copyWith(messages: updatedMessages));
      add(SendReadReceiptRequested(messageId: event.message.id));
    }
  }


  void _onMessageStatusUpdated(MessageStatusUpdated event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final statusData = event.statusData;

      final realId = statusData['messageId']; // Backend ID
      final tempId = statusData['client_temp_id'];

      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == realId || msg.clientTempId == tempId) {
          return MessageEntity(
            id: realId ?? msg.id, // Update the message ID to the REAL ID!
            senderId: msg.senderId,
            receiverId: msg.receiverId,
            decryptedText: msg.decryptedText,
            status: statusData['status'],
            createdAt: msg.createdAt,
            clientTempId: msg.clientTempId,
            isDeleted: msg.isDeleted,
            isEdited: msg.isEdited,
            mediaType: msg.mediaType,
            mediaUrl: msg.mediaUrl,
            replyToMsgId: msg.replyToMsgId,
          );
        }
        return msg;
      }).toList();

      emit(currentState.copyWith(messages: updatedMessages));
    }
  }



  void _onTypingStatusReceived(TypingStatusReceived event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final isTyping = event.typingData['isTyping'] as bool;
      emit(currentState.copyWith(isTyping: isTyping));
    }
  }

  void _onOnlineStatusReceived(OnlineStatusReceived event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final isOnline = event.statusData['isOnline'] as bool;

      DateTime? parsedLastSeen;
      if (!isOnline && event.statusData['lastSeen'] != null) {
        parsedLastSeen = DateTime.tryParse(event.statusData['lastSeen'] as String);
      }

      emit(currentState.copyWith(
        isOnline: isOnline,
        lastSeen: parsedLastSeen ?? currentState.lastSeen,
      ));
    }
  }

  void _onEditedMessageReceived(EditedMessageReceived event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final messageId = event.editData['messageId'];

      final newText = event.editData['newEncryptedText'];

      final updatedMessages = currentState.messages.map((m) {
        if (m.id == messageId) {
          return MessageEntity(
            id: m.id,
            senderId: m.senderId,
            receiverId: m.receiverId,
            decryptedText: newText,
            status: m.status,
            createdAt: m.createdAt,
            clientTempId: m.clientTempId,
          );
        }
        return m;
      }).toList();

      emit(currentState.copyWith(messages: updatedMessages));
    }
  }

  void _onDeletedMessageReceived(DeletedMessageReceived event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final messageId = event.deleteData['messageId'];

      final updatedMessages = currentState.messages.map((m) {
        if (m.id == messageId) {
          return MessageEntity(
            id: m.id,
            senderId: m.senderId,
            receiverId: m.receiverId,
            decryptedText: '🚫 This message was deleted',
            status: m.status,
            createdAt: m.createdAt,
            clientTempId: m.clientTempId,
          );
        }
        return m;
      }).toList();

      emit(currentState.copyWith(messages: updatedMessages));
    }
  }


  Future<void> _onClearAllChatHistory(ClearAllChatHistoryRequested event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;

      // Optimistically clear the UI
      emit(currentState.copyWith(messages: []));

      // Clear the local database
      await clearAllChatHistoryUseCase(event.chatUserId);
    }
  }



  void _onReplyToMessageSelected(ReplyToMessageSelected event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      // Set the selected message and clear any editing state
      emit(currentState.copyWith(
        replyingToMessage: event.message,
        clearEditing: true,
      ));
    }
  }

  void _onReplyCanceled(ReplyCanceled event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      emit(currentState.copyWith(clearReplyingTo: true));
    }
  }


  Future<void> _onSendMediaMessage(SendMediaMessageRequested event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;

      // Upload the media file to the server
      final uploadResult = await uploadMediaUseCase(event.mediaFile);

      await uploadResult.fold(
              (failure) async {
            // You might want to handle failures here (e.g., emit an error state)
            print('Media upload failed: ${failure.message}');
          },
              (mediaData) async {
            // On success, create the message with the returned URL and MIME type
            final tempId = const Uuid().v4();
            final message = MessageEntity(
              id: tempId,
              senderId: event.senderId,
              receiverId: event.receiverId,
              decryptedText: event.caption ?? '📷 Photo',
              status: 'sent',
              createdAt: DateTime.now(),
              clientTempId: tempId,
              mediaUrl: mediaData['url'],
              mediaType: mediaData['mimeType'],
              replyToMsgId: event.replyToMsgId,
            );

            // Optimistically update the UI
            final updatedMessages = List<MessageEntity>.from(currentState.messages)..insert(0, message);
            emit(currentState.copyWith(
              messages: updatedMessages,
              clearReplyingTo: true,
            ));

            // Send the message payload via Socket
            await sendMessageUseCase(message, event.receiverPublicKey);
          }
      );
    }
  }

  void _cancelSubscriptions() {
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    _typingSubscription?.cancel();
    _onlineStatusSubscription?.cancel();
    _editedMessageSubscription?.cancel();
    _deletedMessageSubscription?.cancel();
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}