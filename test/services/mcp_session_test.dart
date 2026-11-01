import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/data/mcp_client_service.dart';

void main() {
  test(
    'session 404 initializes without an ID and retries the same request once',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final requests = <Map<String, dynamic>>[];
      var initializations = 0;
      var toolLists = 0;
      server.listen((request) async {
        if (request.method == 'GET') {
          request.response.statusCode = 405;
          await request.response.close();
          return;
        }
        if (request.method == 'DELETE') {
          request.response.statusCode = 200;
          await request.response.close();
          return;
        }
        final body = jsonDecode(
          await utf8.decoder.bind(request).join(),
        ) as Map<String, dynamic>;
        requests.add({
          'body': body,
          'session': request.headers.value('mcp-session-id'),
        });
        final response = request.response;
        response.headers.contentType = ContentType.json;
        if (body['method'] == 'notifications/initialized') {
          response.statusCode = 202;
          await response.close();
          return;
        }
        Object result;
        if (body['method'] == 'initialize') {
          initializations++;
          response.headers.set('mcp-session-id', 'session-$initializations');
          result = {
            'protocolVersion': '2025-06-18',
            'capabilities': {'tools': {}},
            'serverInfo': {'name': 'test', 'version': '1'},
          };
        } else {
          toolLists++;
          if (toolLists == 1) {
            response.statusCode = 404;
            response.write('Session not found');
            await response.close();
            return;
          }
          result = {'tools': []};
        }
        response.write(
          jsonEncode({'jsonrpc': '2.0', 'id': body['id'], 'result': result}),
        );
        await response.close();
      });
      final service = McpClientService(
        endpoint: Uri.parse('http://127.0.0.1:${server.port}/mcp'),
      );
      try {
        expect(await service.listTools(), isEmpty);
        expect(initializations, 2);
        expect(toolLists, 2);
        final initializes = requests.where(
          (r) => r['body']['method'] == 'initialize',
        );
        expect(initializes.every((r) => r['session'] == null), isTrue);
        final lists = requests
            .where((r) => r['body']['method'] == 'tools/list')
            .toList();
        expect(lists.first['session'], 'session-1');
        expect(lists.last['session'], 'session-2');
        expect(lists.first['body']['params'], lists.last['body']['params']);
      } finally {
        await service.close();
        await server.close(force: true);
      }
    },
  );

  test('a second session 404 is surfaced instead of looping', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var initializes = 0;
    var lists = 0;
    server.listen((request) async {
      final response = request.response;
      if (request.method != 'POST') {
        response.statusCode = 405;
        await response.close();
        return;
      }
      final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
      if (body['method'] == 'initialize') {
        initializes++;
        response.headers.contentType = ContentType.json;
        response.headers.set('mcp-session-id', 'session-$initializes');
        response.write(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': body['id'],
            'result': {
              'protocolVersion': '2025-06-18',
              'capabilities': {'tools': {}},
              'serverInfo': {'name': 'test', 'version': '1'},
            },
          }),
        );
      } else if (body['method'] == 'notifications/initialized') {
        response.statusCode = 202;
      } else {
        lists++;
        response.statusCode = 404;
        response.write('Session expired');
      }
      await response.close();
    });
    final service = McpClientService(
      endpoint: Uri.parse('http://127.0.0.1:${server.port}/mcp'),
    );
    try {
      await expectLater(service.listTools(), throwsA(anything));
      expect(initializes, 2);
      expect(lists, 2);
    } finally {
      await service.close();
      await server.close(force: true);
    }
  });
}
