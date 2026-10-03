import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/constants/api_service.dart';


import 'package:frontend/features/auth/data/Data%20Sources/auth_datasource.dart';
import 'package:frontend/features/auth/data/Repository%20Implementations/auth_repo_impl.dart';

import 'package:frontend/features/auth/domain/Use%20Cases/login_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/register_usecase.dart';


import 'package:frontend/features/auth/presentation/bloc/auth_bloc_bloc.dart';
import 'package:frontend/features/auth/presentation/pages/loginscreen.dart';

void main() {
  final apiService = ApiService();

  final authRemoteDataSource = AuthRemoteDataSource(Dio(),
   apiService: apiService,
  );

  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
  );

  final loginUseCase = LoginUseCase(
    repository: authRepository,
  );

  final registerUseCase = RegisterUseCase(
    repository: authRepository,
  );

  runApp(
    BlocProvider(
      create: (context) => AuthBloc(
        loginUseCase: loginUseCase,
        registerUseCase: registerUseCase,
      ),
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
      home: const Loginscreen(),
    );
  }
}