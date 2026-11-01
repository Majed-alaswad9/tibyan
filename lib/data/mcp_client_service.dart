import 'dart:async';

import 'package:mcp_dart/mcp_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:tibyan/models/retrieval.dart';

abstract interface class McpGateway {
  Future<List<Tool>> listTools();
  Future<Retrieval> callTool(String name, Map<String, dynamic> arguments);
  Future<void> close();
}

class McpClientService implements McpGateway {
  McpClientService({Uri? endpoint})
    : endpoint = endpoint ?? Uri.parse('https://mcp.islamiccontent.org/mcp');
  final Uri endpoint;
  McpClient? _client;
  StreamableHttpClientTransport? _transport;
  Future<void>? _connecting;
  int _generation = 0;
  static const timeout = Duration(seconds: 40);

  Future<void> _connect() {
    final existing = _connecting;
    if (existing != null) return existing;
    late final Future<void> pending;
    pending = _initialize().whenComplete(() {
      if (identical(_connecting, pending)) _connecting = null;
    });
    return _connecting = pending;
  }

  Future<void> _initialize() async {
    if (_client != null) return;
    final generation = _generation;
    final client = McpClient(
      const Implementation(name: 'tibyan', version: '1.0.0'),
      options: const McpClientOptions(protocolVersion: '2025-06-18'),
    );
    final transport = StreamableHttpClientTransport(endpoint);
    _client = client;
    _transport = transport;
    try {
      await client.connect(transport).timeout(timeout);
      if (generation != _generation) throw AppFailure.cancelled;
    } catch (_) {
      if (identical(_client, client)) {
        _client = null;
        _transport = null;
      }
      await client.close();
      rethrow;
    }
  }

  Future<T> _request<T>(
    String operation,
    Future<T> Function(McpClient) action,
  ) async {
    final timer = kDebugMode ? (Stopwatch()..start()) : null;
    if (kDebugMode) debugPrint('[MCP] $operation started');
    try {
      final generation = _generation;
      await _connect();
      if (generation != _generation) throw AppFailure.cancelled;
      // The SDK re-initializes stale sessions and retries once; do not retry again.
      final result = await action(_client!).timeout(timeout);
      if (kDebugMode) {
        debugPrint(
          '[MCP] $operation completed ${timer!.elapsedMilliseconds}ms',
        );
      }
      return result;
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[MCP] $operation failed ${error.runtimeType} ${timer!.elapsedMilliseconds}ms',
        );
      }
      rethrow;
    } finally {
      timer?.stop();
    }
  }

  @override
  Future<List<Tool>> listTools() => _request('tools/list', (client) async {
    final tools = <Tool>[];
    String? cursor;
    final seen = <String>{};
    do {
      final page = await client.listTools(
        params: ListToolsRequest(cursor: cursor),
      );
      tools.addAll(page.tools);
      cursor = page.nextCursor;
      if (cursor != null && !seen.add(cursor)) throw AppFailure.tool;
    } while (cursor != null);
    return tools;
  });

  @override
  Future<Retrieval> callTool(String name, Map<String, dynamic> arguments) =>
      _request('tools/call:$name', (client) async {
        final result = await client.callTool(
          CallToolRequest(name: name, arguments: arguments),
        );
        return Retrieval.fromMcp(name, result);
      });

  @override
  Future<void> close() async {
    _generation++;
    _connecting = null;
    await _disconnect();
  }

  Future<void> _disconnect() async {
    final client = _client;
    final transport = _transport;
    _client = null;
    _transport = null;
    // Session deletion is best-effort; closing the client cancels pending work.
    if (transport != null) {
      try {
        await transport.terminateSession().timeout(const Duration(seconds: 3));
      } catch (_) {
        /* Server may already have ended it. */
      }
    }
    await client?.close();
  }
}

/// Select by the discovered schema; never assume the server's parameter names.
class SearchTool {
  const SearchTool(this.tool, this.queryKey);
  final Tool tool;
  final String queryKey;

  static SearchTool discover(List<Tool> tools) {
    for (final tool in tools) {
      if (tool.annotations?.readOnlyHint == false ||
          !'${tool.name} ${tool.description}'.toLowerCase().contains(
            'search',
          )) {
        continue;
      }
      final schema = tool.inputSchema.toJson();
      final properties = (schema['properties'] as Map?) ?? {};
      for (final entry in properties.entries) {
        final field = entry.value as Map;
        if (field['type'] != 'string' ||
            !RegExp(
              'query|search|keyword',
              caseSensitive: false,
            ).hasMatch('${entry.key} ${field['description']}')) {
          continue;
        }
        final required = (schema['required'] as List?) ?? [];
        if (required.any((key) => key != entry.key && key != 'language')) {
          continue;
        }
        return SearchTool(tool, entry.key.toString());
      }
    }
    throw AppFailure.noSearchTool;
  }

  Map<String, dynamic> arguments(String question, String language) {
    final properties = tool.inputSchema.toJson()['properties'] as Map? ?? {};
    return {
      queryKey: question,
      if ((properties['language'] as Map?)?['type'] == 'string')
        'language': language,
    };
  }
}
