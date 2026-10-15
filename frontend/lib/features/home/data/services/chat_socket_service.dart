import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:frontend/core/constants/api_constant.dart';
import 'package:frontend/features/home/domain/entities/chat_message.dart';

typedef OnMessageReceived = void Function(ChatMessage message);
typedef OnRoomHistory = void Function(List<ChatMessage> messages);
typedef OnUserTyping = void Function(String userName, bool isTyping);
typedef OnConnectionStateChanged = void Function(bool isConnected);

class ChatSocketService {
  socket_io.Socket? _socket;
  bool _isConnected = false;

  String? _currentRoomId;
  String? _currentUserId;
  String? _currentUserName;

  OnMessageReceived? onMessageReceived;
  OnRoomHistory? onRoomHistory;
  OnUserTyping? onUserTyping;
  OnConnectionStateChanged? onConnectionStateChanged;

  bool get isConnected => _isConnected;

  void init() {
    if (_socket != null) return;

    final url = ApiConstants.baseUrl;
    debugPrint('[ChatSocket] Initializing Socket.IO with $url');

    _socket = socket_io.io(
      url,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1500)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[ChatSocket] Connected to Socket.IO server: ${_socket?.id}');
      _isConnected = true;
      onConnectionStateChanged?.call(true);

      // If room parameters were already registered, rejoin automatically on connect/reconnect
      if (_currentRoomId != null) {
        _emitJoinRoom();
      }
    });

    _socket!.onDisconnect((reason) {
      debugPrint('[ChatSocket] Disconnected from Socket.IO server: $reason');
      _isConnected = false;
      onConnectionStateChanged?.call(false);
    });

    _socket!.onConnectError((err) {
      debugPrint('[ChatSocket] Connect error: $err');
      _isConnected = false;
      onConnectionStateChanged?.call(false);
    });

    _socket!.onError((err) {
      debugPrint('[ChatSocket] Socket error: $err');
    });

    // Listen for room history sent by server upon joining
    _socket!.on('room_history', (data) {
      if (data is List) {
        final messages = data
            .map((item) {
              if (item is Map<String, dynamic>) {
                return ChatMessage.fromJson(item);
              } else if (item is Map) {
                return ChatMessage.fromJson(Map<String, dynamic>.from(item));
              }
              return null;
            })
            .whereType<ChatMessage>()
            .toList();

        debugPrint('[ChatSocket] Received ${messages.length} historical messages');
        onRoomHistory?.call(messages);
      }
    });

    // Listen for incoming messages in real time
    _socket!.on('receive_message', (data) {
      if (data is Map) {
        final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
        debugPrint('[ChatSocket] New message from ${message.senderName}: ${message.text}');
        onMessageReceived?.call(message);
      }
    });

    // Listen for typing indicator
    _socket!.on('user_typing', (data) {
      if (data is Map) {
        final userName = data['userName']?.toString() ?? 'Someone';
        final isTyping = data['isTyping'] == true;
        onUserTyping?.call(userName, isTyping);
      }
    });

    // Listen for user join events (optional system notifications)
    _socket!.on('user_joined', (data) {
      if (data is Map) {
        final userName = data['userName']?.toString() ?? 'Participant';
        final systemMsg = ChatMessage(
          id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
          roomId: _currentRoomId ?? '',
          senderId: 'system',
          senderName: 'System',
          text: '$userName joined the call',
          timestamp: DateTime.now(),
          isSystem: true,
        );
        onMessageReceived?.call(systemMsg);
      }
    });

    _socket!.connect();
  }

  void joinRoom({
    required String roomId,
    required String userId,
    required String userName,
  }) {
    _currentRoomId = roomId;
    _currentUserId = userId;
    _currentUserName = userName;

    if (_socket == null) {
      init();
    } else if (_isConnected) {
      _emitJoinRoom();
    } else {
      _socket?.connect();
    }
  }

  void _emitJoinRoom() {
    if (_currentRoomId == null || _socket == null) return;
    debugPrint(
      '[ChatSocket] Emitting join_room -> room: "$_currentRoomId", user: "$_currentUserName" ($_currentUserId)',
    );
    _socket!.emit('join_room', {
      'roomId': _currentRoomId,
      'userId': _currentUserId,
      'userName': _currentUserName,
    });
  }

  void sendMessage({
    required String roomId,
    required String text,
    required String senderId,
    required String senderName,
  }) {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _socket == null) return;

    final payload = {
      'roomId': roomId,
      'text': cleanText,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': DateTime.now().toIso8601String(),
    };

    debugPrint('[ChatSocket] Emitting send_message to $roomId: $cleanText');
    _socket!.emit('send_message', payload);
  }

  void sendTyping({required String roomId, required bool isTyping}) {
    if (_socket == null || !_isConnected) return;
    _socket!.emit('typing', {
      'roomId': roomId,
      'isTyping': isTyping,
    });
  }

  void leaveRoom(String roomId) {
    if (_socket == null) return;
    _socket!.emit('leave_room', {'roomId': roomId});
  }

  void dispose() {
    debugPrint('[ChatSocket] Disposing socket service');
    if (_currentRoomId != null) {
      leaveRoom(_currentRoomId!);
    }
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
