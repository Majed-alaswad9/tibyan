import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/data/network_client.dart';

import '../support/dio_adapter.dart';

void main() {
  for (final status in [200, 503]) {
    test(
      'logs $status metadata without headers, payloads, credentials or query values',
      () async {
        final logs = <String>[];
        final dio = createDio();
        dio.interceptors.clear();
        dio.interceptors.add(NetworkLogInterceptor(log: logs.add));
        dio.httpClientAdapter = StubDioAdapter((options) {
          expect(options.headers['authorization'], 'Bearer private-token');
          expect((options.data as Map)['question'], 'private-question');
          return ResponseBody.fromString('private-reply', status);
        });
        addTearDown(() => dio.close(force: true));
        final response = dio.postUri<Object?>(
          Uri.parse(
            'https://private-user:private-password@proxy.example/private-path?key=private-query',
          ),
          data: {'question': 'private-question'},
          options: Options(
            headers: {
              'authorization': 'Bearer private-token',
              'mcp-session-id': 'private-session',
            },
          ),
        );
        if (status == 200) {
          await response;
        } else {
          await expectLater(response, throwsA(isA<DioException>()));
        }
        expect(logs.length, 2);
        final text = logs.join('\n');
        expect(text, contains('POST https://proxy.example'));
        expect(text, contains('$status'));
        expect(text, contains('ms'));
        for (final secret in [
          'private-token',
          'private-question',
          'private-reply',
          'private-user',
          'private-password',
          'private-query',
          'private-session',
          'private-path',
        ]) {
          expect(text, isNot(contains(secret)));
        }
      },
    );
  }
}
