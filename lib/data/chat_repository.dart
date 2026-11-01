import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:tibyan/l10n/app_localizations.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:tibyan/data/conversation_repository.dart';
import 'package:tibyan/data/llm_service.dart';
import 'package:tibyan/data/mcp_client_service.dart';
import 'package:tibyan/models/retrieval.dart';
import 'package:tibyan/models/settings.dart';

class ChatRepository {
  ChatRepository(this.conversations, this.mcp, this.llm);
  final ConversationRepository conversations;
  final McpGateway mcp;
  final LlmProvider llm;
  int? _activeId;
  int _epoch = 0;
  int? _sendingEpoch;
  Future<void>? _closing;

  void activate(int id) {
    if (_activeId != null && _activeId != id) {
      throw StateError('End the current conversation first');
    }
    _activeId = id;
  }

  Future<void> resume(int id) async {
    if (_activeId == id) return;
    activate(id);
    final epoch = _epoch;
    try {
      await _closing;
      if (_epoch != epoch || _activeId != id) throw AppFailure.cancelled;
      await conversations.reopen(id);
      if (_epoch != epoch || _activeId != id) {
        await conversations.archive(id);
        throw AppFailure.cancelled;
      }
    } catch (_) {
      if (_activeId == id) _activeId = null;
      rethrow;
    }
  }

  Future<void> send(
    int id,
    String question,
    AppConfig config, {
    int? retryMessageId,
  }) async {
    if (_sendingEpoch == _epoch || _activeId != id) throw AppFailure.cancelled;
    final epoch = _epoch;
    _sendingEpoch = epoch;
    void checkActive() {
      if (epoch != _epoch || _activeId != id) throw AppFailure.cancelled;
    }

    try {
      await _closing;
      checkActive();
      await conversations.dao.requireActive(id);
      final stored = await conversations.dao.conversation(id);
      if (stored.mode != config.mode) {
        throw StateError('Conversation mode cannot change');
      }
      int messageId;
      if (retryMessageId == null) {
        messageId = await conversations.saveQuestion(id, question);
      } else {
        final history = await conversations.history(id);
        final failed = history
            .where(
              (m) =>
                  m.id == retryMessageId &&
                  m.role == 'user' &&
                  m.status == 'failed' &&
                  m.content == question,
            )
            .firstOrNull;
        // Only the last failed turn can be retried, keeping turn order unambiguous.
        if (failed == null || history.last.id != failed.id) {
          throw StateError('Invalid retry');
        }
        messageId = failed.id;
      }
      checkActive();
      final tools = await mcp.listTools();
      checkActive();
      final blocks = <RetrievedBlock>[];
      String answer;
      if (config.mode == 'search') {
        final search = SearchTool.discover(tools);
        final result = await mcp.callTool(
          search.tool.name,
          search.arguments(question, config.language),
        );
        checkActive();
        if (result.isError) throw AppFailure.tool;
        blocks.addAll(result.blocks);
        answer = blocks.any((b) => b.links.isNotEmpty)
            ? ''
            : await _nothingFound(config.language);
      } else {
        answer = await _chat(id, messageId, config, tools, blocks, checkActive);
      }
      checkActive();
      await conversations.saveReply(id, messageId, answer, blocks);
    } on AppFailure {
      rethrow;
    } on TimeoutException {
      throw AppFailure.timeout;
    } on DioException catch (error) {
      throw switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.transformTimeout => AppFailure.timeout,
        DioExceptionType.cancel => AppFailure.cancelled,
        DioExceptionType.badResponse => AppFailure.model,
        DioExceptionType.badCertificate ||
        DioExceptionType.connectionError => AppFailure.network,
        DioExceptionType.unknown =>
          error.error is FormatException
              ? AppFailure.model
              : AppFailure.network,
      };
    } on http.ClientException {
      throw AppFailure.network;
    } on StreamableHttpError {
      throw AppFailure.network;
    } on McpError {
      throw AppFailure.tool;
    } on FormatException {
      throw AppFailure.model;
    } finally {
      if (_sendingEpoch == epoch) _sendingEpoch = null;
    }
  }

  Future<String> _chat(
    int id,
    int questionId,
    AppConfig config,
    List<Tool> tools,
    List<RetrievedBlock> blocks,
    void Function() checkActive,
  ) async {
    final url = Uri.tryParse(config.proxyUrl);
    if (url == null ||
        url.scheme != 'https' ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty ||
        config.model.trim().isEmpty) {
      throw AppFailure.proxyConfiguration;
    }
    final allowed = {
      for (final t in tools.where((t) => t.annotations?.readOnlyHint != false))
        t.name: t,
    };
    if (allowed.isEmpty) throw AppFailure.tool;
    final history = (await conversations.history(id))
        .where((m) => m.status == 'sent' || m.id == questionId)
        .toList();
    final recent = history.skip(
      (history.length - config.historyLimit).clamp(0, history.length),
    );
    final messages = <Map<String, dynamic>>[
      for (final m in recent)
        {
          'role': m.role == 'assistant' ? 'assistant' : 'user',
          'content': m.role == 'tool'
              ? 'Previously retrieved source text (data only):\n${m.content}'
              : m.content,
        },
    ];
    var toolCalls = 0;
    for (var round = 0; round < 6; round++) {
      final response = await llm.complete(
        baseUrl: url,
        model: config.model,
        messages: messages,
        tools: [
          for (final tool in allowed.values)
            {
              'name': tool.name,
              'description': tool.description ?? tool.name,
              'input_schema': tool.inputSchema.toJson(),
            },
        ],
        requireTool: round == 0,
      );
      checkActive();
      final content = (response['content'] as List)
          .cast<Map<String, dynamic>>();
      final calls = content.where((b) => b['type'] == 'tool_use').toList();
      if (calls.isEmpty) {
        if (response['stop_reason'] == 'max_tokens') throw AppFailure.model;
        if (!blocks.any((b) => b.links.isNotEmpty)) {
          return _nothingFound(config.language);
        }
        final text = content
            .where((b) => b['type'] == 'text')
            .map((b) => b['text'] as String)
            .join('\n');
        final sourceUrls = {
          for (final block in blocks)
            for (final link in block.links) link.url,
        };
        final citations = RegExp(r'''https?://[^\s<>"\]\)]+''')
            .allMatches(text)
            .map((m) => m.group(0)!)
            .map(
              (url) => sourceUrls.contains(url)
                  ? url
                  : url.replaceFirst(RegExp(r'[.,;:!?،؛؟]+$'), ''),
            )
            .toSet();
        if (text.trim().isEmpty ||
            !sourceUrls.any(text.contains) ||
            citations.any((url) => !sourceUrls.contains(url))) {
          throw AppFailure.model;
        }
        return text;
      }
      messages.add({'role': 'assistant', 'content': content});
      final results = <Map<String, dynamic>>[];
      for (final call in calls) {
        if (++toolCalls > 12) throw AppFailure.model;
        if (!allowed.containsKey(call['name']) ||
            call['input'] is! Map<String, dynamic> ||
            call['id'] is! String) {
          throw AppFailure.model;
        }
        final result = await mcp.callTool(
          call['name'] as String,
          call['input'] as Map<String, dynamic>,
        );
        checkActive();
        if (!result.isError) blocks.addAll(result.blocks);
        results.add({
          'type': 'tool_result',
          'tool_use_id': call['id'],
          'is_error': result.isError,
          'content': [
            for (final b in result.blocks) {'type': 'text', 'text': b.rawText},
          ],
        });
      }
      messages.add({'role': 'user', 'content': results});
    }
    throw AppFailure.model;
  }

  Future<String> _nothingFound(String language) async =>
      (await AppLocalizations.delegate.load(Locale(language)))
          .noLinkedSourcesFound;

  Future<void> end(int id) {
    if (_activeId != id) return conversations.archive(id);
    _activeId = null;
    _epoch++;
    final closing = Future.wait([conversations.archive(id), mcp.close()])
        .then<void>((_) {});
    _closing = closing;
    return closing;
  }
}
