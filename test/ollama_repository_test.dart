import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sentfix/data/ollama_repository.dart';
import 'package:sentfix/writing/writing_task.dart';

class _ScriptedClient extends http.BaseClient {
  _ScriptedClient(this._handler);

  final Future<http.Response> Function(http.Request request) _handler;
  http.Request? last;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    last = request as http.Request;
    final response = await _handler(last!);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
    );
  }
}

class _DownClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw http.ClientException('down');
  }
}

void main() {
  test('isRunning is true only when tags returns 200', () async {
    final up = OllamaRepository(
      client: _ScriptedClient(
        (_) async => http.Response('{"models":[]}', 200),
      ),
    );
    final down = OllamaRepository(
      client: _ScriptedClient((_) async => http.Response('no', 500)),
    );
    final unreachable = OllamaRepository(client: _DownClient());

    expect(await up.isRunning(), isTrue);
    expect(await down.isRunning(), isFalse);
    expect(await unreachable.isRunning(), isFalse);
  });

  test('models skips internal llamacpp hash names', () async {
    final client = _ScriptedClient(
      (_) async => http.Response(
        jsonEncode({
          'models': [
            {'name': 'llama3.2:3b'},
            {'name': 'llama3.2:3b'},
            {
              'name':
                  'llamacpp:9ba9cc2b4e02463b933096090530aef679d534dd91ecc9afadfb2dbfdc59f3c5',
            },
          ],
        }),
        200,
      ),
    );
    final repository = OllamaRepository(client: client);

    expect(await repository.models(), ['llama3.2:3b']);
  });

  test('revise sends the chosen model and returns the reply', () async {
    final client = _ScriptedClient(
      (_) async => http.Response(
        jsonEncode({
          'message': {'role': 'assistant', 'content': '  shorter text  '},
        }),
        200,
      ),
    );
    final repository = OllamaRepository(client: client);

    final reply = await repository.revise(
      text: 'what is the capital of france?',
      task: WritingTask.concise,
      teach: false,
      model: 'llama3.2:3b',
    );

    expect(reply, 'shorter text');
    final body = jsonDecode(client.last!.body) as Map<String, dynamic>;
    expect(body['model'], 'llama3.2:3b');
    final user = (body['messages'] as List).last as Map<String, dynamic>;
    expect(user['content'], contains('Do not answer it'));
    expect(user['content'], contains('what is the capital of france?'));
    expect(user['content'], contains('<text>'));
  });

  test('revise throws the Ollama error message', () async {
    final repository = OllamaRepository(
      client: _ScriptedClient(
        (_) async => http.Response(
          jsonEncode({'error': 'model not found'}),
          404,
        ),
      ),
    );

    expect(
      repository.revise(
        text: 'hello',
        task: WritingTask.fixEnglish,
        teach: false,
      ),
      throwsA(
        isA<OllamaException>().having(
          (error) => error.message,
          'message',
          'model not found',
        ),
      ),
    );
  });
}
