import 'dart:async';
import 'dart:io';

import 'package:connect/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:connect/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/message_model.dart';

// Development HTTP overrides for self-signed certificates (Socket.IO)
class _SocketHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class ChatRemoteDatasourceImpl implements IChatRemoteDatasource {
  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;
  IO.Socket? _socket;
  bool _isRefreshingToken = false;

  // Stream Controllers
  final _messageStreamController = StreamController<MessageModel>.broadcast();
  final _messageStatusStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _onlineStatusStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _editedMessageStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _deletedMessageStreamController = StreamController<Map<String, dynamic>>.broadcast();

  ChatRemoteDatasourceImpl({
    required this.apiClient,
    required this.secureStorage,
  });

  @override
  Future<void> connectSocket() async {
    try {
      final token = await secureStorage.read(key: 'access_token');
      if (token == null) throw ServerException('Authentication token not found');

      HttpOverrides.global = _SocketHttpOverrides();

      _socket = IO.io(
        ApiEndpoints.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .setExtraHeaders({'Connection': 'upgrade', 'Upgrade': 'websocket'})
            .build(),
      );

      // --- Connection Event Listeners ---
      _socket!.onConnect((_) {
        _isRefreshingToken = false;
        _socket!.emit('join_chat');
      });

      _socket!.onConnectError((err) async {
        if (err.toString().contains('Token expired') || err.toString().contains('AUTH_INVALID')) {
          if (_isRefreshingToken) return;
          _isRefreshingToken = true;

          try {
            // Trigger interceptor to refresh the token
            await apiClient.dio.get(ApiEndpoints.getMyProfile);

            final newToken = await secureStorage.read(key: 'access_token');
            if (newToken != null && _socket != null) {
              _socket!.disconnect();

              // Correctly update the auth token for the socket instance
              _socket!.auth = {'token': newToken};
              if (_socket!.io.options != null) {
                _socket!.io.options!['auth'] = {'token': newToken};
              }

              _socket!.connect();
            }
          } catch (e) {
            _isRefreshingToken = false;
          } finally {
            // Reset flag after attempt to allow future retries
            Future.delayed(const Duration(seconds: 5), () {
              _isRefreshingToken = false;
            });
          }
        }
      });

      _socket!.onDisconnect((_) {});

      // --- Business Event Listeners ---
      _socket!.on('receive_message', (data) {
        try {
          final message = MessageModel.fromJson(data);
          _messageStreamController.add(message);
        } catch (e, stack) {
          print('❌ Message Parsing Error: $e');
        }
      });

      _socket!.on('msg_status_update', (data) {
        _messageStatusStreamController.add(Map<String, dynamic>.from(data));
      });

      _socket!.on('typing', (data) {
        final typingData = Map<String, dynamic>.from(data);
        typingData['isTyping'] = true;
        _typingStreamController.add(typingData);
      });

      _socket!.on('stop_typing', (data) {
        final typingData = Map<String, dynamic>.from(data);
        typingData['isTyping'] = false;
        _typingStreamController.add(typingData);
      });

      _socket!.on('user_online', (data) {
        final statusData = Map<String, dynamic>.from(data);
        statusData['isOnline'] = true;
        _onlineStatusStreamController.add(statusData);
      });

      _socket!.on('user_offline', (data) {
        final statusData = Map<String, dynamic>.from(data);
        statusData['isOnline'] = false;
        _onlineStatusStreamController.add(statusData);
      });

      _socket!.on('message_edited', (data) {
        _editedMessageStreamController.add(Map<String, dynamic>.from(data));
      });

      _socket!.on('message_deleted', (data) {
        _deletedMessageStreamController.add(Map<String, dynamic>.from(data));
      });


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

  @override
  Future<List<MessageModel>> syncOfflineMessages() async {
    try {
      final response = await apiClient.dio.get(ApiEndpoints.getOfflineMessage);
      final List<dynamic> messagesJson = response.data['data']['messages'];
      return messagesJson.map((json) => MessageModel.fromJson(json as Map<String, dynamic>)).toList();
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
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final List<dynamic> messagesJson = response.data['data']['messages'];
      return messagesJson.map((json) => MessageModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to load chat history.';
      throw ServerException(message);
    } catch (e) {
      throw ServerException('An unexpected error occurred while loading history.');
    }
  }

  @override
  Future<void> editMessage(String messageId, String newEncryptedText) async {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('message_edited', {
        'message_id': messageId,
        'new_encrypted_text': newEncryptedText,
      });
    } else {
      throw ServerException('Socket is not connected.');
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('message_deleted', {
        'message_id': messageId,
      });
    } else {
      throw ServerException('Socket is not connected.');
    }
  }

  @override
  Stream<MessageModel> receiveMessagesStream() => _messageStreamController.stream;

  @override
  Stream<Map<String, dynamic>> receiveMessageStatusStream() => _messageStatusStreamController.stream;

  @override
  Stream<Map<String, dynamic>> receiveTypingStream() => _typingStreamController.stream;

  @override
  Stream<Map<String, dynamic>> receiveOnlineStatusStream() => _onlineStatusStreamController.stream;

  @override
  Stream<Map<String, dynamic>> receiveEditedMessageStream() => _editedMessageStreamController.stream;

  @override
  Stream<Map<String, dynamic>> receiveDeletedMessageStream() => _deletedMessageStreamController.stream;

}