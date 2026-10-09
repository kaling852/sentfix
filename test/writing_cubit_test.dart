import 'package:flutter_test/flutter_test.dart';
import 'package:sentfix/data/ollama_repository.dart';
import 'package:sentfix/writing/writing_cubit.dart';
import 'package:sentfix/writing/writing_task.dart';

class _FakeOllamaRepository extends OllamaRepository {
  _FakeOllamaRepository({this.reply = 'revised', this.names = const []});

  final String reply;
  final List<String> names;
  String? usedModel;

  @override
  Future<List<String>> models() async => names;

  @override
  Future<String> revise({
    required String text,
    required WritingTask task,
    required bool teach,
    String? model,
  }) async {
    usedModel = model;
    if (reply == 'fail') {
      throw OllamaException('model not found');
    }
    return reply;
  }
}

void main() {
  test('history disappears after 2 minutes', () async {
    var clock = DateTime(2026, 1, 1, 12);
    final cubit = WritingCubit(
      _FakeOllamaRepository(),
      now: () => clock,
      pruneEvery: const Duration(milliseconds: 20),
    );

    await cubit.submit('hello');
    expect(cubit.state.history, hasLength(1));

    clock = clock.add(const Duration(minutes: 2, seconds: 1));
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(cubit.state.history, isEmpty);
    await cubit.close();
  });

  test('blank text is not sent', () async {
    final cubit = WritingCubit(_FakeOllamaRepository());

    await cubit.submit('   ');

    expect(cubit.state.history, isEmpty);
    expect(cubit.state.busy, isFalse);
    await cubit.close();
  });

  test('teach me splits the lesson and drops prompt markers', () async {
    final cubit = WritingCubit(
      _FakeOllamaRepository(
        reply: '''
REVISION:
---
<text>
I should went.
</text>

LESSON:
---
Use "go" after "should".
''',
      ),
    );
    cubit.setTeach(true);

    await cubit.submit('I should went.');

    expect(cubit.state.history.single.output, 'I should went.');
    expect(cubit.state.history.single.lesson, 'Use "go" after "should".');
    await cubit.close();
  });

  test('uses an installed model when the default is missing', () async {
    final repository = _FakeOllamaRepository(names: const ['llama3.2:3b']);
    final cubit = WritingCubit(repository);
    await cubit.loadModels();

    await cubit.submit('hello');

    expect(cubit.state.model, 'llama3.2:3b');
    expect(repository.usedModel, 'llama3.2:3b');
    await cubit.close();
  });

  test('shows the Ollama error and keeps the screen usable', () async {
    final cubit = WritingCubit(_FakeOllamaRepository(reply: 'fail'));

    await cubit.submit('hello');

    expect(cubit.state.error, 'model not found');
    expect(cubit.state.busy, isFalse);
    expect(cubit.state.history, isEmpty);
    await cubit.close();
  });
}
