import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/constants/api_service.dart';
import 'package:frontend/core/storage/tocken_storage.dart';
import 'package:frontend/features/auth/data/Data%20Sources/auth_datasource.dart';
import 'package:frontend/features/auth/data/Repository%20Implementations/auth_repo_impl.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/check_session_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/clear_session_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/login_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/register_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/save_session_usecase.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_bloc.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_event.dart';
import 'package:frontend/features/auth/presentation/pages/splash_screen.dart';
import 'package:frontend/features/home/presentation/bloc/home_bloc.dart';
import 'package:frontend/features/meetings/data/datasources/meeting_remote_datasource.dart';
import 'package:frontend/features/meetings/data/repositories/meeting_repository_impl.dart';
import 'package:frontend/features/meetings/domain/usecases/create_meeting.dart';
import 'package:frontend/features/meetings/domain/usecases/get_meetings.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Infrastructure setup
  final prefs = await SharedPreferences.getInstance();
  final sessionLocalDataSource = SessionLocalDataSource(prefs: prefs);
  final apiService = ApiService(sessionLocalDataSource: sessionLocalDataSource);

  // Auth Data layer
  final authRemoteDataSource = AuthRemoteDataSource(
    apiService: apiService,
    sessionLocalDataSource: sessionLocalDataSource,
  );
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    localDataSource: sessionLocalDataSource,
  );

  // Auth Domain use cases
  final loginUseCase = LoginUseCase(repository: authRepository);
  final registerUseCase = RegisterUseCase(repository: authRepository);
  final checkSessionUseCase = CheckSessionUseCase(repository: authRepository);
  final saveSessionUseCase = SaveSessionUseCase(repository: authRepository);
  final clearSessionUseCase = ClearSessionUseCase(repository: authRepository);

  // Meetings Clean Architecture dependencies
  final meetingRemoteDataSource = MeetingRemoteDataSourceImpl(
    apiService: apiService,
    sessionLocalDataSource: sessionLocalDataSource,
  );
  final meetingRepository = MeetingRepositoryImpl(meetingRemoteDataSource);
  final createMeetingUseCase = CreateMeeting(meetingRepository);
  final getMeetingsUseCase = GetMeetings(meetingRepository);

  final authBloc = AuthBloc(
    loginUseCase: loginUseCase,
    registerUseCase: registerUseCase,
    checkSessionUseCase: checkSessionUseCase,
    saveSessionUseCase: saveSessionUseCase,
    clearSessionUseCase: clearSessionUseCase,
  );

  apiService.onSessionExpired = () {
    authBloc.add(SessionExpiredRequested());
  };

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(
          value: authBloc,
        ),
        BlocProvider<HomeBloc>(
          create: (_) => HomeBloc(),
        ),
        BlocProvider<MeetingBloc>(
          create: (_) => MeetingBloc(
            createMeeting: createMeetingUseCase,
            getMeetings: getMeetingsUseCase,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}