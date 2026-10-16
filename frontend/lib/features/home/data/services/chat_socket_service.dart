import 'dart:convert';
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

  final List<Map<String, dynamic>> _pendingMessageQueue = [];

  OnMessageReceived? onMessageReceived;
  OnRoomHistory? onRoomHistory;
  OnUserTyping? onUserTyping;
  OnConnectionStateChanged? onConnectionStateChanged;

  bool get isConnected => _isConnected || (_socket?.connected ?? false);

  void init() {
    if (_socket != null) {
      if (!isConnected) {
        _socket!.connect();
      }
      return;
    }

    final url = ApiConstants.baseUrl;
    debugPrint('[ChatSocket] Initializing Socket.IO with $url');

    _socket = socket_io.io(
      url,
      socket_io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionAttempts(20)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[ChatSocket] Connected to Socket.IO server: ${_socket?.id}');
      _isConnected = true;
      onConnectionStateChanged?.call(true);

      // If room parameters were already registered, rejoin automatically on connect/reconnect
      if (_currentRoomId != null && _currentRoomId!.isNotEmpty) {
        _emitJoinRoom();
      }

      // Dispatch any messages that were queued while connecting or offline
      _flushPendingMessages();
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
      try {
        dynamic parsedData = data;
        if (data is String) {
          parsedData = jsonDecode(data);
        }

        if (parsedData is List) {
          final messages = parsedData
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
      } catch (e, stack) {
        debugPrint('[ChatSocket] Error parsing room_history: $e\n$stack');
      }
    });

    // Listen for incoming messages in real time
    _socket!.on('receive_message', (data) {
      try {
        Map<String, dynamic>? messageMap;
        if (data is Map) {
          messageMap = Map<String, dynamic>.from(data);
        } else if (data is String) {
          final decoded = jsonDecode(data);
          if (decoded is Map) {
            messageMap = Map<String, dynamic>.from(decoded);
          }
        }

        if (messageMap != null) {
          final message = ChatMessage.fromJson(messageMap);
          debugPrint('[ChatSocket] New message from ${message.senderName}: ${message.text}');
          onMessageReceived?.call(message);
        }
      } catch (e, stack) {
        debugPrint('[ChatSocket] Error parsing receive_message: $e\n$stack');
      }
    });

    // Listen for typing indicator
    _socket!.on('user_typing', (data) {
      try {
        Map? map;
        if (data is Map) {
          map = data;
        } else if (data is String) {
          final decoded = jsonDecode(data);
          if (decoded is Map) map = decoded;
        }
        if (map != null) {
          final userName = map['userName']?.toString() ?? 'Someone';
          final isTyping = map['isTyping'] == true;
          onUserTyping?.call(userName, isTyping);
        }
      } catch (_) {}
    });

    // Listen for user join events (optional system notifications)
    _socket!.on('user_joined', (data) {
      try {
        Map? map;
        if (data is Map) {
          map = data;
        } else if (data is String) {
          final decoded = jsonDecode(data);
          if (decoded is Map) map = decoded;
        }
        if (map != null) {
          final userName = map['userName']?.toString() ?? 'Participant';
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
      } catch (_) {}
    });

    _socket!.connect();
  }

  void joinRoom({
    required String roomId,
    required String userId,
    required String userName,
  }) {
    _currentRoomId = roomId.trim();
    _currentUserId = userId.trim();
    _currentUserName = userName.trim();

    if (_socket == null) {
      init();
    } else if (isConnected) {
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
    String? id,
    required String roomId,
    required String text,
    required String senderId,
    required String senderName,
  }) {
    final cleanText = text.trim();
    final cleanRoomId = roomId.trim();
    if (cleanText.isEmpty || cleanRoomId.isEmpty) return;

    final msgId = (id != null && id.isNotEmpty)
        ? id
        : 'msg_${DateTime.now().millisecondsSinceEpoch}_${senderId}';

    final payload = {
      'id': msgId,
      'roomId': cleanRoomId,
      'text': cleanText,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (_socket != null && isConnected) {
      debugPrint('[ChatSocket] Emitting send_message to $cleanRoomId: $cleanText');
      _socket!.emit('send_message', payload);
    } else {
      debugPrint('[ChatSocket] Socket not yet connected. Queueing message for $cleanRoomId: $cleanText');
      _pendingMessageQueue.add(payload);
      _socket?.connect();
    }
  }

  void _flushPendingMessages() {
    if (_pendingMessageQueue.isEmpty || _socket == null) return;
    debugPrint('[ChatSocket] Flushing ${_pendingMessageQueue.length} pending messages');
    final queue = List<Map<String, dynamic>>.from(_pendingMessageQueue);
    _pendingMessageQueue.clear();
    for (final payload in queue) {
      _socket!.emit('send_message', payload);
    }
  }

  void sendTyping({required String roomId, required bool isTyping}) {
    final cleanRoomId = roomId.trim();
    if (_socket == null || !isConnected || cleanRoomId.isEmpty) return;
    _socket!.emit('typing', {
      'roomId': cleanRoomId,
      'isTyping': isTyping,
    });
  }

  void leaveRoom(String roomId) {
    if (_socket == null) return;
    final cleanRoomId = roomId.trim();
    _socket!.emit('leave_room', {'roomId': cleanRoomId});
  }

  void reconnect() {
    if (_socket == null) {
      init();
    } else {
      _socket!.connect();
    }
  }

  void dispose() {
    debugPrint('[ChatSocket] Disposing socket service');
    if (_currentRoomId != null) {
      leaveRoom(_currentRoomId!);
    }
    _pendingMessageQueue.clear();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
