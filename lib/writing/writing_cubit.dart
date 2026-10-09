import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentfix/data/ollama_repository.dart';
import 'package:sentfix/writing/writing_task.dart';

class WritingEntry {
  WritingEntry({
    required this.input,
    required this.output,
    required this.task,
    required this.teach,
    required this.createdAt,
    this.lesson,
  });

  final String input;
  final String output;
  final String? lesson;
  final WritingTask task;
  final bool teach;
  final DateTime createdAt;
}

class WritingState {
  const WritingState({
    this.task = WritingTask.fixEnglish,
    this.teach = false,
    this.busy = false,
    this.error,
    this.history = const [],
    this.models = const [],
    this.model,
  });

  final WritingTask task;
  final bool teach;
  final bool busy;
  final String? error;
  final List<WritingEntry> history;
  final List<String> models;
  final String? model;

  WritingState copyWith({
    WritingTask? task,
    bool? teach,
    bool? busy,
    String? error,
    bool clearError = false,
    List<WritingEntry>? history,
    List<String>? models,
    String? model,
  }) {
    return WritingState(
      task: task ?? this.task,
      teach: teach ?? this.teach,
      busy: busy ?? this.busy,
      error: clearError ? null : error ?? this.error,
      history: history ?? this.history,
      models: models ?? this.models,
      model: model ?? this.model,
    );
  }
}

class WritingCubit extends Cubit<WritingState> {
  WritingCubit(
    this._repository, {
    this.historyLifetime = const Duration(minutes: 2),
    this.pruneEvery = const Duration(seconds: 15),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const WritingState()) {
    unawaited(loadModels());
  }

  final OllamaRepository _repository;
  final Duration historyLifetime;
  final Duration pruneEvery;
  final DateTime Function() _now;
  Timer? _timer;

  void selectTask(WritingTask task) {
    emit(state.copyWith(task: task));
  }

  void setTeach(bool teach) {
    emit(state.copyWith(teach: teach));
  }

  void selectModel(String model) {
    emit(state.copyWith(model: model));
  }

  Future<void> loadModels() async {
    try {
      final models = await _repository.models();
      if (isClosed || models.isEmpty) {
        return;
      }
      final selected = models.contains(_repository.model)
          ? _repository.model
          : models.first;
      emit(state.copyWith(models: models, model: selected));
    } catch (_) {
      // The default model is still used when the list cannot be loaded.
    }
  }

  Future<void> submit(String text) async {
    final input = text.trim();
    if (input.isEmpty || state.busy) {
      return;
    }
    emit(state.copyWith(busy: true, clearError: true));
    try {
      final reply = await _repository.revise(
        text: input,
        task: state.task,
        teach: state.teach,
        model: state.model,
      );
      final parsed = _splitLesson(reply, state.teach);
      final entry = WritingEntry(
        input: input,
        output: parsed.revision,
        lesson: parsed.lesson,
        task: state.task,
        teach: state.teach,
        createdAt: _now(),
      );
      emit(
        state.copyWith(busy: false, history: [entry, ..._fresh(state.history)]),
      );
      _watchHistory();
    } on OllamaException catch (error) {
      emit(state.copyWith(busy: false, error: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          busy: false,
          error: 'Could not reach Ollama on localhost.',
        ),
      );
    }
  }

  void _watchHistory() {
    _timer ??= Timer.periodic(pruneEvery, (_) => _dropExpired());
  }

  void _dropExpired() {
    final history = _fresh(state.history);
    if (history.length == state.history.length) {
      return;
    }
    emit(state.copyWith(history: history));
    if (history.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
  }

  static ({String revision, String? lesson}) _splitLesson(
    String reply,
    bool teach,
  ) {
    if (!teach) {
      return (revision: _clean(reply), lesson: null);
    }
    final match = RegExp(
      r'\nLESSON:\s*',
      caseSensitive: false,
    ).firstMatch(reply);
    if (match == null) {
      return (revision: _clean(reply), lesson: null);
    }
    final revision = _clean(
      reply
          .substring(0, match.start)
          .replaceFirst(RegExp(r'^REVISION:\s*', caseSensitive: false), ''),
    );
    final lesson = _clean(reply.substring(match.end));
    return (
      revision: revision.isEmpty ? _clean(reply) : revision,
      lesson: lesson.isEmpty ? null : lesson,
    );
  }

  static String _clean(String text) {
    final lines = text.split('\n').where((line) {
      final trimmed = line.trim();
      return trimmed != '---' &&
          trimmed != '--' &&
          trimmed != '<text>' &&
          trimmed != '</text>';
    });
    return lines.join('\n').trim();
  }

  List<WritingEntry> _fresh(List<WritingEntry> history) {
    final cutoff = _now().subtract(historyLifetime);
    return [
      for (final entry in history)
        if (entry.createdAt.isAfter(cutoff)) entry,
    ];
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
