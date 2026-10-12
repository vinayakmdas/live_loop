import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/domain/Entities/user_entites.dart';
import 'package:frontend/features/home/presentation/bloc/home_bloc.dart';
import 'package:frontend/features/home/presentation/bloc/home_event.dart';
import 'package:frontend/features/home/presentation/bloc/home_state.dart';
import 'package:frontend/features/home/presentation/page/homescreen.dart';

void main() {
  group('HomeBloc Tests', () {
    test('Initializes with user data correctly', () {
      const user = UserEntity(
        id: '123',
        name: 'Alex Johnson',
        username: 'alexj',
        email: 'alex@example.com',
      );

      final bloc = HomeBloc(initialUser: user);

      expect(bloc.state, isA<HomeLoaded>());
      expect(bloc.state.isLoggedIn, isTrue);
      expect(bloc.state.userName, 'Alex Johnson');
      expect(bloc.state.userInitial, 'A');
      expect(bloc.state.userEmail, 'alex@example.com');
      bloc.close();
    });

    test('Handles null and empty user data gracefully with fallbacks', () async {
      final bloc = HomeBloc();

      expect(bloc.state, isA<HomeInitial>());
      expect(bloc.state.isLoggedIn, isFalse);
      expect(bloc.state.userName, 'User');
      expect(bloc.state.userInitial, 'U');

      const emptyNameUser = UserEntity(
        id: '456',
        name: '   ',
        username: 'empty',
        email: 'empty@example.com',
      );

      final expectation = expectLater(
        bloc.stream,
        emits(isA<HomeLoaded>().having(
          (s) => s.userName,
          'userName',
          'User',
        )),
      );

      bloc.add(LoadHomeUser(user: emptyNameUser));
      await expectation;
      await bloc.close();
    });

    test('LoadHomeUser and ClearHomeUser transition states correctly', () async {
      final bloc = HomeBloc();

      const user = UserEntity(
        id: '789',
        name: 'Sophia Doe',
        username: 'sophiad',
        email: 'sophia@example.com',
      );

      final loadExpectation = expectLater(
        bloc.stream,
        emits(isA<HomeLoaded>()
            .having((s) => s.userName, 'userName', 'Sophia Doe')
            .having((s) => s.userInitial, 'userInitial', 'S')),
      );

      bloc.add(LoadHomeUser(user: user));
      await loadExpectation;

      final clearExpectation = expectLater(
        bloc.stream,
        emits(isA<HomeUnauthenticated>()),
      );

      bloc.add(ClearHomeUser());
      await clearExpectation;

      await bloc.close();
    });
  });

  group('Homescreen Widget Tests with BLoC', () {
    testWidgets('Displays dynamic user name and initial when user is passed', (
      WidgetTester tester,
    ) async {
      const testUser = UserEntity(
        id: '1',
        name: 'John Wick',
        username: 'johnw',
        email: 'john@example.com',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Homescreen(user: testUser),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Welcome, John Wick! 👋'), findsOneWidget);
      expect(find.text('J'), findsOneWidget);
      expect(find.text('Live Loop'), findsOneWidget);
      expect(find.text('Create Meeting'), findsOneWidget);
    });

    testWidgets('Displays not-logged-in fallback when no user is provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Homescreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('You are not signed in'), findsOneWidget);
      expect(find.text('Go to Login'), findsOneWidget);
    });
  });
}
