import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/date_time_formatter.dart';
import 'package:frontend/features/auth/domain/Entities/user_entites.dart';
import 'package:frontend/features/home/presentation/page/homescreen.dart';
import 'package:frontend/features/home/presentation/widget/coming_card_widget.dart';
import 'package:frontend/features/meetings/domain/entities/meeting_entity.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_bloc.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_state.dart';

// Simple mock/stub for MeetingBloc
class FakeMeetingBloc extends Cubit<MeetingState> implements MeetingBloc {
  FakeMeetingBloc({MeetingState? initialState})
      : super(initialState ?? const MeetingState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ComingUpCard Countdown Formatter Tests', () {
    final fixedNow = DateTime(2026, 10, 17, 10, 0, 0);

    test('Formats "Starts in 30 minutes" when meeting is in 30 minutes today',
        () {
      final scheduledTime = DateTime(2026, 10, 17, 10, 30, 0);
      final result =
          ComingUpCard.formatCountdown(scheduledTime, now: fixedNow);
      expect(result, 'Starts in 30 minutes');
    });

    test('Formats "Starts in 2 hours" when meeting is in 2 hours today', () {
      final scheduledTime = DateTime(2026, 10, 17, 12, 0, 0);
      final result =
          ComingUpCard.formatCountdown(scheduledTime, now: fixedNow);
      expect(result, 'Starts in 2 hours');
    });

    test('Formats "Starts in 1 hour" when meeting is in 1 hour today', () {
      final scheduledTime = DateTime(2026, 10, 17, 11, 0, 0);
      final result =
          ComingUpCard.formatCountdown(scheduledTime, now: fixedNow);
      expect(result, 'Starts in 1 hour');
    });

    test('Formats "Starts in 1 minute" when meeting is in 1 minute today', () {
      final scheduledTime = DateTime(2026, 10, 17, 10, 1, 0);
      final result =
          ComingUpCard.formatCountdown(scheduledTime, now: fixedNow);
      expect(result, 'Starts in 1 minute');
    });

    test('Formats "Starts tomorrow" when meeting is scheduled for tomorrow',
        () {
      final scheduledTime = DateTime(2026, 10, 18, 14, 0, 0);
      final result =
          ComingUpCard.formatCountdown(scheduledTime, now: fixedNow);
      expect(result, 'Starts tomorrow');
    });

    test('Formats "Starts in 3 days" when meeting is 3 days ahead', () {
      final scheduledTime = DateTime(2026, 10, 20, 10, 0, 0);
      final result =
          ComingUpCard.formatCountdown(scheduledTime, now: fixedNow);
      expect(result, 'Starts in 3 days');
    });

    test('Formats "Starts now" when meeting scheduled time has arrived', () {
      final scheduledTime = DateTime(2026, 10, 17, 9, 59, 0);
      final result =
          ComingUpCard.formatCountdown(scheduledTime, now: fixedNow);
      expect(result, 'Starts now');
    });
  });

  group('ComingUpCard Scheduled Date & Time Formatter Tests', () {
    final fixedNow = DateTime(2026, 10, 17, 10, 0, 0);

    test('Formats scheduled date as "Today"', () {
      final scheduledTime = DateTime(2026, 10, 17, 14, 30, 0);
      final result =
          ComingUpCard.formatScheduledDate(scheduledTime, now: fixedNow);
      expect(result, 'Today');
    });

    test('Formats scheduled date as "Tomorrow"', () {
      final scheduledTime = DateTime(2026, 10, 18, 10, 0, 0);
      final result =
          ComingUpCard.formatScheduledDate(scheduledTime, now: fixedNow);
      expect(result, 'Tomorrow');
    });

    test('Formats scheduled date as "Oct 22, 2026"', () {
      final scheduledTime = DateTime(2026, 10, 22, 16, 0, 0);
      final result =
          ComingUpCard.formatScheduledDate(scheduledTime, now: fixedNow);
      expect(result, 'Oct 22, 2026');
    });

    test('Formats scheduled time as "2:30 PM"', () {
      final scheduledTime = DateTime(2026, 10, 17, 14, 30, 0);
      final result = ComingUpCard.formatScheduledTime(scheduledTime);
      expect(result, '2:30 PM');
    });

    test('Handles null values safely in all formatters', () {
      expect(ComingUpCard.formatCountdown(null), 'Starts now');
      expect(ComingUpCard.formatScheduledDate(null), '');
      expect(ComingUpCard.formatScheduledTime(null), '');
    });
  });

  group('DateTimeFormatter Core Utility Tests', () {
    final fixedNow = DateTime(2026, 10, 17, 10, 0, 0);

    test('DateTimeFormatter formats countdown, date, and time correctly', () {
      final future = DateTime(2026, 10, 17, 12, 45, 0);
      expect(
        DateTimeFormatter.formatCountdown(future, now: fixedNow),
        'Starts in 2 hours',
      );
      expect(
        DateTimeFormatter.formatScheduledDate(future, now: fixedNow),
        'Today',
      );
      expect(
        DateTimeFormatter.formatScheduledTime(future),
        '12:45 PM',
      );
      expect(
        DateTimeFormatter.formatDateTime(future, now: fixedNow),
        'Today at 12:45 PM',
      );
    });

    test('DateTimeFormatter handles null safely', () {
      expect(DateTimeFormatter.formatCountdown(null), 'Starts now');
      expect(DateTimeFormatter.formatScheduledDate(null), '');
      expect(DateTimeFormatter.formatScheduledTime(null), '');
      expect(DateTimeFormatter.formatDateTime(null), '');
    });

    test('MeetingEntityScheduleFormatting extension getters provide formatted values', () {
      final meeting = MeetingEntity(
        id: 'ext-1',
        name: 'Extension Test',
        accessType: 'public',
        meetingType: 'scheduled',
        scheduledStartTime: DateTime(2026, 10, 17, 15, 30, 0),
      );

      expect(meeting.scheduledTime, '3:30 PM');
      expect(meeting.formatScheduledTime(), '3:30 PM');
    });
  });

  group('MeetingEntity Upcoming vs Current Filtering Tests', () {
    test('Future scheduled public meeting is upcoming and NOT current', () {
      final futureMeeting = MeetingEntity(
        id: 'fut-1',
        name: 'Future Meeting',
        accessType: 'public',
        meetingType: 'scheduled',
        scheduledStartTime: DateTime.now().add(const Duration(minutes: 30)),
      );

      expect(futureMeeting.isUpcoming, isTrue);
      expect(futureMeeting.isCurrent, isFalse);
    });

    test('Private meeting in future is NOT in upcoming public feed', () {
      final privateMeeting = MeetingEntity(
        id: 'priv-1',
        name: 'Private Class',
        accessType: 'private',
        meetingType: 'scheduled',
        scheduledStartTime: DateTime.now().add(const Duration(hours: 2)),
      );

      expect(privateMeeting.isUpcoming, isFalse);
      expect(privateMeeting.isCurrent, isFalse);
    });

    test('Cancelled and completed meetings are neither upcoming nor current', () {
      final cancelledMeeting = MeetingEntity(
        id: 'canc-1',
        name: 'Cancelled Meeting',
        accessType: 'public',
        meetingType: 'scheduled',
        status: 'cancelled',
        scheduledStartTime: DateTime.now().add(const Duration(hours: 2)),
      );

      final completedMeeting = MeetingEntity(
        id: 'comp-1',
        name: 'Completed Meeting',
        accessType: 'public',
        meetingType: 'scheduled',
        status: 'completed',
        scheduledStartTime: DateTime.now().add(const Duration(hours: 2)),
      );

      expect(cancelledMeeting.isUpcoming, isFalse);
      expect(cancelledMeeting.isCurrent, isFalse);
      expect(completedMeeting.isUpcoming, isFalse);
      expect(completedMeeting.isCurrent, isFalse);
    });

    test('Active instant meeting is current and NOT upcoming', () {
      final instantMeeting = const MeetingEntity(
        id: 'inst-1',
        name: 'Instant Sync',
        accessType: 'public',
        meetingType: 'instant',
        scheduledStartTime: null,
      );

      expect(instantMeeting.isCurrent, isTrue);
      expect(instantMeeting.isUpcoming, isFalse);
    });
  });

  group('ComingUpCard Widget Rendering Tests', () {
    testWidgets('Renders card with title, countdown, subtitle and avatars',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComingUpCard(
              meetingName: 'Mobile App Architecture Review',
              description: 'Engineering Team',
              countdown: 'Starts in 2 hours',
              scheduledDate: 'Today',
              startTime: '4:00 PM',
              memberCount: 4,
              memberInitials: const ['A', 'B', 'C', 'D'],
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('UPCOMING'), findsOneWidget);
      expect(find.text('Starts in 2 hours'), findsOneWidget);
      expect(find.text('Mobile App Architecture Review'), findsOneWidget);
      expect(find.text('Engineering Team'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('4:00 PM'), findsOneWidget);
      expect(find.text('4 people invited'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);

      await tester.tap(find.text('Details'));
      expect(tapped, isTrue);
    });

    testWidgets('Renders from MeetingEntity seamlessly',
        (WidgetTester tester) async {
      final meeting = MeetingEntity(
        id: 'meet-101',
        name: 'Weekly Sprint Planning',
        description: 'Sprint planning and retrospective',
        category: 'product',
        meetingType: 'scheduled',
        scheduledStartTime: DateTime.now().add(const Duration(minutes: 30)),
        memberCount: 3,
        memberInitials: const ['S', 'P'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComingUpCard(
              meeting: meeting,
            ),
          ),
        ),
      );

      expect(find.text('UPCOMING'), findsOneWidget);
      expect(find.text('Weekly Sprint Planning'), findsOneWidget);
      expect(find.text('Sprint planning and retrospective'), findsOneWidget);
      expect(find.text('3 people invited'), findsOneWidget);
    });
  });

  group('Homescreen Upcoming Meetings Section Integration Tests', () {
    testWidgets('Homescreen displays both Current and Upcoming sections',
        (WidgetTester tester) async {
      const testUser = UserEntity(
        id: '1',
        name: 'Alex Johnson',
        username: 'alexj',
        email: 'alex@example.com',
      );

      final upcomingMeeting = MeetingEntity(
        id: 'up-1',
        name: 'AI Engineering Sync',
        description: 'Roadmap and model integrations',
        category: 'engineering',
        meetingType: 'scheduled',
        scheduledStartTime: DateTime.now().add(const Duration(hours: 2)),
        accessType: 'public',
        memberCount: 5,
        memberInitials: const ['A', 'E'],
      );

      final fakeMeetingBloc = FakeMeetingBloc(
        initialState: MeetingState(
          meetings: [upcomingMeeting],
        ),
      );

      await tester.pumpWidget(
        BlocProvider<MeetingBloc>.value(
          value: fakeMeetingBloc,
          child: const MaterialApp(
            home: Homescreen(user: testUser),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check section titles
      expect(find.text('Current Meetings'), findsOneWidget);
      expect(find.text('Upcoming Meetings'), findsOneWidget);

      // Check upcoming card is present with AI Engineering Sync using ComingUpCard
      expect(find.byType(ComingUpCard), findsOneWidget);
      expect(find.text('AI Engineering Sync'), findsOneWidget);
      expect(find.text('Roadmap and model integrations'), findsOneWidget);
    });

    testWidgets('Homescreen displays empty state when no upcoming meetings',
        (WidgetTester tester) async {
      const testUser = UserEntity(
        id: '1',
        name: 'Alex Johnson',
        username: 'alexj',
        email: 'alex@example.com',
      );

      final fakeMeetingBloc = FakeMeetingBloc(
        initialState: const MeetingState(
          meetings: [],
        ),
      );

      await tester.pumpWidget(
        BlocProvider<MeetingBloc>.value(
          value: fakeMeetingBloc,
          child: const MaterialApp(
            home: Homescreen(user: testUser),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No upcoming meetings'), findsOneWidget);
      expect(
        find.text(
          'Public meetings scheduled for later will appear here automatically with a live countdown.',
        ),
        findsOneWidget,
      );
    });
  });
}
