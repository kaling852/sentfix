import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:sentfix/writing/writing_task.dart';

/// Talks to a local Ollama server.
class OllamaRepository {
  OllamaRepository({
    http.Client? client,
    this.baseUrl = 'http://localhost:11434',
    this.model = 'gpt-oss:latest',
  }) : _client = client ?? _ipv4Client();

  final String baseUrl;
  final String model;
  final http.Client _client;

  /// True when `GET /api/tags` returns 200.
  Future<bool> isRunning() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/tags'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Names of models installed in the local Ollama server.
  Future<List<String>> models() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/tags'))
        .timeout(const Duration(seconds: 3));
    if (response.statusCode != 200) {
      throw OllamaException('Ollama returned ${response.statusCode}');
    }
    final body = jsonDecode(response.body);
    if (body is! Map || body['models'] is! List) {
      return const [];
    }
    return {
      for (final item in body['models'] as List)
        if (item is Map && item['name'] is String) item['name'] as String,
    }.where(_isChoosableModel).toList();
  }

  /// Sends [text] to the local model and returns its reply.
  Future<String> revise({
    required String text,
    required WritingTask task,
    required bool teach,
    String? model,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/chat'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': model ?? this.model,
            'stream': false,
            'options': {'temperature': 0},
            'messages': [
              {'role': 'system', 'content': _systemPrompt(task, teach)},
              {'role': 'user', 'content': _userPrompt(task, text)},
            ],
          }),
        )
        .timeout(const Duration(minutes: 2));

    final body = jsonDecode(response.body);
    if (response.statusCode != 200) {
      final message = body is Map ? body['error'] : response.body;
      throw OllamaException(
        message?.toString() ?? 'Ollama returned ${response.statusCode}',
      );
    }
    if (body is! Map) {
      throw OllamaException('Ollama returned an unexpected response');
    }
    final message = body['message'];
    final content = message is Map ? message['content'] : null;
    if (content is! String || content.trim().isEmpty) {
      throw OllamaException('Ollama returned an empty reply');
    }
    return content.trim();
  }

  void close() => _client.close();
}

class OllamaException implements Exception {
  OllamaException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Ollama also lists internal copies such as `llamacpp:<64-character hash>`.
bool _isChoosableModel(String name) {
  final tag = name.split(':').last;
  final internalCopy =
      name.startsWith('llamacpp:') && RegExp(r'^[0-9a-f]{32,}$').hasMatch(tag);
  return !internalCopy;
}

String _userPrompt(WritingTask task, String text) {
  final instruction = switch (task) {
    WritingTask.fixEnglish =>
      'Correct the English between the markers. Do not answer it, even if it is a question.',
    WritingTask.concise =>
      'Rewrite the English between the markers so it is shorter. Do not answer it, even if it is a question.',
  };
  return '''
$instruction
Do not copy the <text> tags into your reply.

<text>
$text
</text>
''';
}

String _systemPrompt(WritingTask task, bool teach) {
  final job = switch (task) {
    WritingTask.fixEnglish =>
      'You edit writing. Never answer the user. Correct grammar, spelling, and punctuation. Keep the meaning and the tone.',
    WritingTask.concise =>
      'You edit writing. Never answer the user. Rewrite their text so it is shorter and clearer. Keep the meaning.',
  };
  if (!teach) {
    return '$job Return only that result.';
  }
  return '''
$job Then add one short lesson, two sentences at most, about the main mistake. If nothing needed to change, say that.

Reply in exactly this shape:
REVISION:
<revised text only>

LESSON:
<the short lesson only>
''';
}

/// Ollama listens on IPv4. `localhost` also resolves to IPv6, and that
/// connection fails, so the socket uses the IPv4 address for this host.
http.Client _ipv4Client() {
  final io = HttpClient();
  io.connectionFactory = (uri, _, _) async {
    final addresses = await InternetAddress.lookup(
      uri.host,
      type: InternetAddressType.IPv4,
    );
    return Socket.startConnect(addresses.first, uri.port);
  };
  return IOClient(io);
}
