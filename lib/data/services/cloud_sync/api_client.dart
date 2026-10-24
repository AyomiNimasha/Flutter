import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.statusCode);
  final int statusCode;
}

// Access tokens are supplied by the future authenticated session layer.
// Never put JWTs or database credentials in --dart-define or source control.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.accessToken,
    http.Client? client,
  }) : _client = client ?? http.Client();
  final Uri baseUrl;
  final Future<String?> Function() accessToken;
  final http.Client _client;

  Future<http.Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, baseUrl.resolve(path));
    final token = await accessToken();
    request.headers['Accept'] = path.endsWith('.pdf')
        ? 'application/pdf'
        : 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final response = await http.Response.fromStream(
      await _client.send(request).timeout(const Duration(seconds: 20)),
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode);
    }
    return response;
  }

  Future<Object?> json(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _request(method, path, body: body);
    return response.body.isEmpty
        ? null
        : jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<Uint8List> certificate(String petId) async {
    final response = await _request(
      'GET',
      '/pets/${Uri.encodeComponent(petId)}/certificate.pdf',
    );
    if (!response.headers['content-type'].toString().contains(
          'application/pdf',
        ) ||
        !utf8
            .decode(response.bodyBytes.take(5).toList(), allowMalformed: true)
            .startsWith('%PDF-')) {
      throw const FormatException('Invalid PDF response');
    }
    return response.bodyBytes;
  }

  void close() => _client.close();
}
