import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pawshots/data/services/cloud_sync/api_client.dart';

void main() {
  test('sends authenticated JSON and handles 204 without decoding', () async {
    final api = ApiClient(
      baseUrl: Uri.parse('https://example.invalid/'),
      accessToken: () async => 'test-token',
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test-token');
        expect(request.url.path, '/pets/p');
        expect(request.body, '{"name":"Milo"}');
        return http.Response('', 204);
      }),
    );
    addTearDown(api.close);
    expect(await api.json('PUT', '/pets/p', body: {'name': 'Milo'}), isNull);
  });
  test(
    'rejects authorization errors and non-PDF certificate responses',
    () async {
      final denied = ApiClient(
        baseUrl: Uri.parse('https://example.invalid'),
        accessToken: () async => null,
        client: MockClient((_) async => http.Response('{}', 403)),
      );
      addTearDown(denied.close);
      await expectLater(
        denied.json('GET', '/pets'),
        throwsA(isA<ApiException>()),
      );
      final invalid = ApiClient(
        baseUrl: Uri.parse('https://example.invalid'),
        accessToken: () async => 'test-token',
        client: MockClient(
          (_) async => http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      addTearDown(invalid.close);
      await expectLater(invalid.certificate('p'), throwsFormatException);
    },
  );
}
