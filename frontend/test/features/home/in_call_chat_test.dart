import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/home/domain/entities/chat_message.dart';
import 'package:frontend/features/home/presentation/widget/in_call_chat_sheet.dart';

void main() {
  group('ChatMessage Entity Tests', () {
    test('serializes and deserializes from JSON correctly', () {
      final now = DateTime.now();
      final msg = ChatMessage(
        id: 'msg_1',
        roomId: 'room_abc',
        senderId: 'user_1',
        senderName: 'Alice',
        text: 'Hello, World!',
        timestamp: now,
      );

      final json = msg.toJson();
      expect(json['id'], 'msg_1');
      expect(json['roomId'], 'room_abc');
      expect(json['text'], 'Hello, World!');

      final parsed = ChatMessage.fromJson(json);
      expect(parsed.id, 'msg_1');
      expect(parsed.text, 'Hello, World!');
      expect(parsed.senderName, 'Alice');
    });

    test('isFromUser correctly identifies sender', () {
      final msg = ChatMessage(
        id: 'msg_1',
        roomId: 'room_abc',
        senderId: 'user_123',
        senderName: 'Alice',
        text: 'Testing',
        timestamp: DateTime.now(),
      );

      expect(msg.isFromUser('user_123', 'OtherName'), isTrue);
      expect(msg.isFromUser('diff_user', 'Alice'), isTrue);
      expect(msg.isFromUser('diff_user', 'Bob'), isFalse);
    });
  });

  group('InCallChatSheet Widget Tests', () {
    testWidgets('renders Google Meet styled header, notice banner, and empty state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InCallChatSheet(
              messages: const [],
              currentUserId: 'me_id',
              currentUserName: 'Me',
              onSendMessage: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );

      // Verify Google Meet header and notice banner
      expect(find.text('In-call messages'), findsOneWidget);
      expect(
        find.textContaining('Messages can only be seen by people in the call'),
        findsOneWidget,
      );

      // Verify empty state
      expect(find.text('No messages yet'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders outgoing and incoming message bubbles correctly',
        (WidgetTester tester) async {
      final messages = [
        ChatMessage(
          id: '1',
          roomId: 'room_1',
          senderId: 'me_id',
          senderName: 'Me',
          text: 'My message to the team',
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: '2',
          roomId: 'room_1',
          senderId: 'other_id',
          senderName: 'Sarah',
          text: 'Hey everyone!',
          timestamp: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InCallChatSheet(
              messages: messages,
              currentUserId: 'me_id',
              currentUserName: 'Me',
              onSendMessage: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('My message to the team'), findsOneWidget);
      expect(find.text('Hey everyone!'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Sarah'), findsOneWidget);
    });

    testWidgets('sends message when text entered and send button tapped',
        (WidgetTester tester) async {
      String? sentText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InCallChatSheet(
              messages: const [],
              currentUserId: 'me_id',
              currentUserName: 'Me',
              onSendMessage: (text) => sentText = text,
              onClose: () {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Hello in video call');
      await tester.pump();

      final sendButton = find.widgetWithIcon(IconButton, Icons.send_rounded);
      await tester.tap(sendButton);
      await tester.pump();

      expect(sentText, 'Hello in video call');
    });

    testWidgets('triggers onClose when close button tapped',
        (WidgetTester tester) async {
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InCallChatSheet(
              messages: const [],
              currentUserId: 'me_id',
              currentUserName: 'Me',
              onSendMessage: (_) {},
              onClose: () => closed = true,
            ),
          ),
        ),
      );

      final closeButton = find.widgetWithIcon(IconButton, Icons.close_rounded);
      await tester.tap(closeButton);
      await tester.pump();

      expect(closed, isTrue);
    });
  });
}
