import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentfix/connection/connection_cubit.dart';
import 'package:sentfix/data/ollama_repository.dart';
import 'package:sentfix/screens/startup_screen.dart';
import 'package:sentfix/theme/app_theme.dart';

void main() {
  final repository = OllamaRepository();
  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.repository});

  final OllamaRepository repository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repository,
      child: BlocProvider(
        create: (_) => ConnectionCubit(repository)..check(),
        child: MaterialApp(
          title: 'Sentfix',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          home: const StartupScreen(),
        ),
      ),
    );
  }
}
