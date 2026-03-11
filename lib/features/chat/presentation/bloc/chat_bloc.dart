import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connect/features/chat/domain/entities/message_entity.dart';

// Import all 10 use cases
import '../../domain/usecases/connect_socket_usecase.dart';
import '../../domain/usecases/disconnect_socket_usecase.dart';
import '../../domain/usecases/get_chat_history_usecase.dart';
import '../../domain/usecases/receive_message_status_stream_usecase.dart';
import '../../domain/usecases/receive_messages_stream_usecase.dart';
import '../../domain/usecases/receive_typing_stream_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/send_read_receipt_usecase.dart';
import '../../domain/usecases/send_typing_status_usecase.dart';
import '../../domain/usecases/sync_offline_messages_usecase.dart';

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

  // Stream Subscriptions
  StreamSubscription? _messageSubscription;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _typingSubscription;

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
  }) : super(ChatInitial()) {

    on<ConnectSocketRequested>(_onConnectSocket);
    on<DisconnectSocketRequested>(_onDisconnectSocket);
    on<LoadChatHistoryRequested>(_onLoadChatHistory);
    on<SendMessageRequested>(_onSendMessage);
    on<SendReadReceiptRequested>(_onSendReadReceipt);
    on<SendTypingStatusRequested>(_onSendTypingStatus);

    // Internal Stream Handlers
    on<MessageReceived>(_onMessageReceived);
    on<MessageStatusUpdated>(_onMessageStatusUpdated);
    on<TypingStatusReceived>(_onTypingStatusReceived);
  }

  Future<void> _onConnectSocket(ConnectSocketRequested event, Emitter<ChatState> emit) async {
    final result = await connectSocketUseCase();
    result.fold(
          (failure) => emit(ChatError(message: failure.message)),
          (_) {
        // Once connected, start listening to streams!
        _messageSubscription = receiveMessagesStreamUseCase().listen(
              (message) => add(MessageReceived(message: message)),
        );
        _statusSubscription = receiveMessageStatusStreamUseCase().listen(
              (statusData) => add(MessageStatusUpdated(statusData: statusData)),
        );
        _typingSubscription = receiveTypingStreamUseCase().listen(
              (typingData) => add(TypingStatusReceived(typingData: typingData)),
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
    emit(ChatLoading());

    // 1. First sync offline messages
    await syncOfflineMessagesUseCase();

    // 2. Then load history
    final result = await getChatHistoryUseCase(event.userId);
    result.fold(
          (failure) => emit(ChatError(message: failure.message)),
          (messages) => emit(ChatLoaded(messages: messages)),
    );
  }

  Future<void> _onSendMessage(SendMessageRequested event, Emitter<ChatState> emit) async {
    // Optimistically add the message to the UI first
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final updatedMessages = List<MessageEntity>.from(currentState.messages)..insert(0, event.message);
      emit(currentState.copyWith(messages: updatedMessages));
    }

    final result = await sendMessageUseCase(event.message, event.receiverPublicKey);
    if (result.isLeft()) {
      // Handle error (e.g., mark message as failed in UI)
      // For now, we just print or emit error
    }
  }

  Future<void> _onSendReadReceipt(SendReadReceiptRequested event, Emitter<ChatState> emit) async {
    await sendReadReceiptUseCase(event.messageId);
  }

  Future<void> _onSendTypingStatus(SendTypingStatusRequested event, Emitter<ChatState> emit) async {
    await sendTypingStatusUseCase(event.receiverId, event.isTyping);
  }

  // --- Stream Event Handlers ---

  void _onMessageReceived(MessageReceived event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      // Add new message to the top of the list (index 0)
      final updatedMessages = List<MessageEntity>.from(currentState.messages)..insert(0, event.message);
      emit(currentState.copyWith(messages: updatedMessages));

      // Send read receipt back automatically
      add(SendReadReceiptRequested(messageId: event.message.id));
    }
  }

  void _onMessageStatusUpdated(MessageStatusUpdated event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final statusData = event.statusData;

      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == statusData['messageId'] || msg.clientTempId == statusData['client_temp_id']) {
          return MessageEntity(
            id: msg.id, senderId: msg.senderId, receiverId: msg.receiverId,
            decryptedText: msg.decryptedText, status: statusData['status'],
            createdAt: msg.createdAt, clientTempId: msg.clientTempId,
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

  void _cancelSubscriptions() {
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    _typingSubscription?.cancel();
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}