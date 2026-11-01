import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/data/llm_service.dart';
import 'package:tibyan/data/network_client.dart';

import '../support/dio_adapter.dart';

void main() {
  Future<Map<String, dynamic>> complete(LlmService service) => service.complete(
    baseUrl: Uri.parse('https://proxy.example/v1/messages'),
    model: 'proxy-model',
    messages: [
      {'role': 'user', 'content': 'question'},
    ],
    tools: [],
    requireTool: true,
  );

  test(
    'Claude uses Dio and keeps the Messages API contract and no embedded key',
    () async {
      final dio = createDio();
      final adapter = StubDioAdapter((request) {
        expect(request.uri.toString(), 'https://proxy.example/v1/messages');
        expect(request.headers.containsKey('x-api-key'), isFalse);
        expect(request.headers['anthropic-version'], '2023-06-01');
        final body = request.data as Map;
        expect(body['tool_choice'], {'type': 'any'});
        expect(body['system'], contains('Never invent'));
        return ResponseBody.fromString(
          '{"content":[{"type":"text","text":"ok"}]}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      dio.httpClientAdapter = adapter;
      final service = LlmService(dio: dio);
      expect((await complete(service))['content'][0]['text'], 'ok');
      service.close();
      expect(adapter.closed, isTrue);
    },
  );

  test('Dio propagates proxy HTTP errors without retrying', () async {
    var calls = 0;
    final dio = createDio()
      ..httpClientAdapter = StubDioAdapter((_) {
        calls++;
        return ResponseBody.fromString(
          '{"error":"unavailable"}',
          503,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
    final service = LlmService(dio: dio);
    addTearDown(service.close);
    await expectLater(
      complete(service),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          503,
        ),
      ),
    );
    expect(calls, 1);
  });

  test('invalid successful model responses are rejected', () async {
    final dio = createDio()
      ..httpClientAdapter = StubDioAdapter(
        (_) => ResponseBody.fromString(
          '{"wrong":"shape"}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
    final service = LlmService(dio: dio);
    addTearDown(service.close);
    await expectLater(complete(service), throwsFormatException);
  });
}
