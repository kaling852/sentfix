import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentfix/connection/connection_cubit.dart';
import 'package:sentfix/data/ollama_repository.dart';
import 'package:sentfix/screens/home_page.dart';
import 'package:sentfix/writing/writing_cubit.dart';

class RunningApp extends StatelessWidget {
  const RunningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WritingCubit(context.read<OllamaRepository>()),
      child: BlocBuilder<ConnectionCubit, ConnectionStatus>(
        builder: (context, status) {
          return Column(
            children: [
              if (status == ConnectionStatus.offline)
                const Material(
                  color: Color(0xFFB3261E),
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Text(
                          'Ollama is not running on localhost.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              const Expanded(child: MyHomePage()),
            ],
          );
        },
      ),
    );
  }
}
