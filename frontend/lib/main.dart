import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/constants/api_service.dart';
import 'package:frontend/core/storage/tocken_storage.dart';
import 'package:frontend/features/auth/data/Data%20Sources/auth_datasource.dart';
import 'package:frontend/features/auth/data/Repository%20Implementations/auth_repo_impl.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/check_session_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/clear_session_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/forgot_password_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/google_sign_in_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/login_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/register_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/reset_password_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/save_session_usecase.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_bloc.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_event.dart';
import 'package:frontend/features/auth/presentation/pages/splash_screen.dart';
import 'package:frontend/features/home/presentation/bloc/home_bloc.dart';
import 'package:frontend/features/meetings/data/datasources/meeting_remote_datasource.dart';
import 'package:frontend/features/meetings/data/repositories/meeting_repository_impl.dart';
import 'package:frontend/features/meetings/domain/usecases/create_meeting.dart';
import 'package:frontend/features/meetings/domain/usecases/get_meetings.dart';
import 'package:frontend/features/meetings/domain/usecases/join_meeting.dart';
import 'package:frontend/features/meetings/domain/usecases/search_meetings.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
  final googleSignInUseCase = GoogleSignInUseCase(authRepository);
  final checkSessionUseCase = CheckSessionUseCase(repository: authRepository);
  final saveSessionUseCase = SaveSessionUseCase(repository: authRepository);
  final clearSessionUseCase = ClearSessionUseCase(repository: authRepository);
  final forgotPasswordUseCase = ForgotPasswordUseCase(repository: authRepository);
  final resetPasswordUseCase = ResetPasswordUseCase(repository: authRepository);

  // Meetings Clean Architecture dependencies
  final meetingRemoteDataSource = MeetingRemoteDataSourceImpl(
    apiService: apiService,
    sessionLocalDataSource: sessionLocalDataSource,
  );
  final meetingRepository = MeetingRepositoryImpl(meetingRemoteDataSource);
  final createMeetingUseCase = CreateMeeting(meetingRepository);
  final getMeetingsUseCase = GetMeetings(meetingRepository);
  final joinMeetingUseCase = JoinMeeting(meetingRepository);
  final searchMeetingsUseCase = SearchMeetings(meetingRepository);

  final authBloc = AuthBloc(
    loginUseCase: loginUseCase,
    registerUseCase: registerUseCase,
    googleSignInUseCase: googleSignInUseCase,
    checkSessionUseCase: checkSessionUseCase,
    saveSessionUseCase: saveSessionUseCase,
    clearSessionUseCase: clearSessionUseCase,
    forgotPasswordUseCase: forgotPasswordUseCase,
    resetPasswordUseCase: resetPasswordUseCase,
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
            joinMeeting: joinMeetingUseCase,
            searchMeetings: searchMeetingsUseCase,
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