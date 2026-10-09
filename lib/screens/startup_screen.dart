import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentfix/connection/connection_cubit.dart';
import 'package:sentfix/screens/running_app.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _enterIfReady();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _enterIfReady() {
    if (_entered || !mounted) {
      return;
    }
    if (_controller.status != AnimationStatus.completed) {
      return;
    }
    if (context.read<ConnectionCubit>().state != ConnectionStatus.online) {
      return;
    }
    _entered = true;
    context.read<ConnectionCubit>().watch();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const RunningApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocListener<ConnectionCubit, ConnectionStatus>(
      listener: (context, status) {
        if (status == ConnectionStatus.checking) {
          _controller.forward(from: 0);
        }
        _enterIfReady();
      },
      child: Scaffold(
        body: Center(
          child: BlocBuilder<ConnectionCubit, ConnectionStatus>(
            builder: (context, status) {
              return FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sentfix',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 28),
                      if (status == ConnectionStatus.offline) ...[
                        Icon(Icons.cloud_off, color: scheme.error, size: 36),
                        const SizedBox(height: 12),
                        Text(
                          'Ollama is not running on localhost.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.read<ConnectionCubit>().check(),
                          child: const Text('Try again'),
                        ),
                      ] else
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
