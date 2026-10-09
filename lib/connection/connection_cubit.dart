import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentfix/data/ollama_repository.dart';

enum ConnectionStatus { checking, online, offline }

class ConnectionCubit extends Cubit<ConnectionStatus> {
  ConnectionCubit(this._repository) : super(ConnectionStatus.checking);

  final OllamaRepository _repository;
  Timer? _timer;
  bool _inFlight = false;

  /// Checks localhost once. Used on startup and when the user retries.
  Future<void> check() => _check(silent: false);

  void watch() {
    _timer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      _check(silent: true);
    });
  }

  Future<void> _check({required bool silent}) async {
    if (_inFlight) {
      return;
    }
    _inFlight = true;
    if (!silent) {
      emit(ConnectionStatus.checking);
    }
    try {
      final running = await _repository.isRunning();
      emit(running ? ConnectionStatus.online : ConnectionStatus.offline);
    } finally {
      _inFlight = false;
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
