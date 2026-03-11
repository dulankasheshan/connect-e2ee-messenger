import 'dart:async';

import 'package:connect/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:connect/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/message_model.dart';

class ChatRemoteDatasourceImpl implements IChatRemoteDatasource{
  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;
  IO.Socket? _socket;

  // Stream Controllers
  final _messageStreamController = StreamController<MessageModel>.broadcast();
  final _messageStatusStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingStreamController = StreamController<Map<String, dynamic>>.broadcast();

  ChatRemoteDatasourceImpl({
    required this.apiClient,
    required this.secureStorage,
  });

  @override
  Future<void> connectSocket() async {
    try {
      // 1. Get the auth token
      final token = await secureStorage.read(key: 'access_token');
      if (token == null) throw ServerException('Authentication token not found');

      // 2. Initialize Socket
      _socket = IO.io(
        ApiEndpoints.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket']) // Force WebSocket only
            .disableAutoConnect() // We will connect manually
            .setAuth({'token': token}) // Send JWT token for authentication
            .build(),
      );

      // --- 3. Connection Event Listeners ---
      _socket!.onConnect((_) {
        print('✅ Socket Connected');
        // TRANSLATOR: Must emit this immediately after connect according to backend docs
        _socket!.emit('join_chat');
      });

      _socket!.onConnectError((err) {
        print('❌ Socket Connection Error: $err');
      });

      _socket!.onDisconnect((_) {
        print('⚠️ Socket Disconnected');
      });

      // --- 4. Business Event Listeners (Piping to Streams) ---

      // When a new message arrives
      _socket!.on('receive_message', (data) {
        try {
          final message = MessageModel.fromJson(data);
          _messageStreamController.add(message);
        } catch (e) {
          print('Error parsing received message: $e');
        }
      });

      // When message status changes (sent -> delivered -> read)
      _socket!.on('msg_status_update', (data) {
        _messageStatusStreamController.add(Map<String, dynamic>.from(data));
      });

      // When someone starts typing
      _socket!.on('typing', (data) {
        final typingData = Map<String, dynamic>.from(data);
        typingData['isTyping'] = true; // Add our own flag to make it easier for UI
        _typingStreamController.add(typingData);
      });

      // When someone stops typing
      _socket!.on('stop_typing', (data) {
        final typingData = Map<String, dynamic>.from(data);
        typingData['isTyping'] = false; // Add our own flag
        _typingStreamController.add(typingData);
      });

      // 5. Finally, make the connection!
      _socket!.connect();

    } catch (e) {
      throw ServerException('Failed to initialize socket connection.');
    }
  }

  @override
  Future<void> disconnectSocket() async {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }


  @override
  Future<void> sendMessage(MessageModel message, String receiverPublicKey) async {
    if (_socket == null || !_socket!.connected) {
      throw ServerException('Socket is not connected.');
    }

    //  Here message.decryptedText holds the ALREADY ENCRYPTED ciphertext
    // from the Domain layer. We just pass it to the server.
    _socket!.emit('send_message', {
      'receiver_id': message.receiverId,
      'encrypted_text': message.decryptedText,
      'media_url': message.mediaUrl,
      'media_type': message.mediaType,
      'reply_to_msg_id': message.replyToMsgId,
      'client_temp_id': message.clientTempId,
    });
  }

  @override
  Future<void> sendReadReceipt(String messageId) async {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('msg_read', {'message_id': messageId});
    }
  }

  @override
  Future<void> sendTypingStatus(String receiverId, bool isTyping) async {
    if (_socket != null && _socket!.connected) {
      final eventName = isTyping ? 'typing' : 'stop_typing';
      _socket!.emit(eventName, {'receiver_id': receiverId});
    }
  }

  //Dio
  @override
  Future<List<MessageModel>> syncOfflineMessages() async {
    try {
      final response = await apiClient.dio.get(ApiEndpoints.getOfflineMessage);

      final List<dynamic> messagesJson = response.data['data']['messages'];
      return messagesJson
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to sync offline messages.';
      throw ServerException(message);
    } catch (e) {
      throw ServerException('An unexpected error occurred during sync.');
    }
  }

  @override
  Future<List<MessageModel>> getChatHistory(String userId, {int limit = 20, int offset = 0}) async {
    try {
      final response = await apiClient.dio.get(
        '${ApiEndpoints.getChatHistory}$userId',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      final List<dynamic> messagesJson = response.data['data']['messages'];
      return messagesJson
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to load chat history.';
      throw ServerException(message);
    } catch (e) {
      throw ServerException('An unexpected error occurred while loading history.');
    }
  }


// --- Stream Getters ---
  @override
  Stream<MessageModel> receiveMessagesStream() => _messageStreamController.stream;

  @override
  Stream<Map<String, dynamic>> receiveMessageStatusStream() => _messageStatusStreamController.stream;

  @override
  Stream<Map<String, dynamic>> receiveTypingStream() => _typingStreamController.stream;


}