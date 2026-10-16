 import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/home/data/services/chat_socket_service.dart';
import 'package:frontend/features/home/domain/entities/chat_message.dart';

void main() {
  test('ChatSocketService connects to local backend and sends/receives message', () async {
    final service = ChatSocketService();
    final completer = Completer<ChatMessage>();

    service.onConnectionStateChanged = (connected) {
      // ignore: avoid_print
      print('[Test] Connection state: $connected');
    };

    service.onRoomHistory = (history) {
      // ignore: avoid_print
      print('[Test] Room history count: ${history.length}');
    };

    service.onMessageReceived = (msg) {
      // ignore: avoid_print
      print('[Test] onMessageReceived: ${msg.text} from ${msg.senderName}');
      if (msg.text == 'Hello from dart test!') {
        if (!completer.isCompleted) {
          completer.complete(msg);
        }
      }
    };

    service.init();
    service.joinRoom(
      roomId: 'test-room-dart',
      userId: 'user_dart',
      userName: 'Dart Tester',
    );

    // Give it a second to connect and join room, then send message
    await Future.delayed(const Duration(milliseconds: 1500));
    service.sendMessage(
      roomId: 'test-room-dart',
      text: 'Hello from dart test!',
      senderId: 'user_dart',
      senderName: 'Dart Tester',
    );

    final received = await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw TimeoutException('Timed out waiting for message'),
    );

    expect(received.text, 'Hello from dart test!');
    expect(received.senderName, 'Dart Tester');

    service.dispose();
  });
}
