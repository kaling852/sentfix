import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Talks to a local Ollama server.
class OllamaRepository {
  OllamaRepository({http.Client? client, this.baseUrl = 'http://localhost:11434'})
    : _client = client ?? _ipv4Client();

  final String baseUrl;
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

  void close() => _client.close();
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
