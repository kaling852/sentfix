import 'package:flutter_test/flutter_test.dart';
import 'package:sentfix/data/ollama_repository.dart';
import 'package:sentfix/main.dart';

class _FakeOllamaRepository extends OllamaRepository {
  _FakeOllamaRepository(this.running);

  bool running;

  @override
  Future<bool> isRunning() async => running;
}

void main() {
  testWidgets('stays on startup when localhost is down', (tester) async {
    await tester.pumpWidget(MyApp(repository: _FakeOllamaRepository(false)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Ollama is not running on localhost.'), findsOneWidget);
    expect(find.text('Sentence or paragraph'), findsNothing);
  });

  testWidgets('enters the app when localhost is up', (tester) async {
    await tester.pumpWidget(MyApp(repository: _FakeOllamaRepository(true)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('Sentence or paragraph'), findsOneWidget);
    expect(find.text('Nothing yet.'), findsOneWidget);
    expect(find.text('Ollama is not running on localhost.'), findsNothing);
  });
}
