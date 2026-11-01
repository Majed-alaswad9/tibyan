import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_dart/mcp_dart.dart' hide RequestOptions;
import 'package:tibyan/data/chat_repository.dart';
import 'package:tibyan/data/conversation_repository.dart';
import 'package:tibyan/data/database.dart';
import 'package:tibyan/data/llm_service.dart';
import 'package:tibyan/data/mcp_client_service.dart';
import 'package:tibyan/models/retrieval.dart';
import 'package:tibyan/models/settings.dart';

final searchTool = Tool.fromJson({
  'name': 'find_sources',
  'description': 'Search published texts',
  'inputSchema': {
    'type': 'object',
    'properties': {
      'keywords': {'type': 'string', 'description': 'Search query'},
      'language': {'type': 'string'},
    },
    'required': ['keywords'],
  },
});
const sourceBlock = RetrievedBlock(
  toolName: 'find_sources',
  rawText: '  Exact source\nhttps://example.org/reference  ',
  links: [SourceLink('https://example.org/reference', 'Reference')],
);

class FakeMcp implements McpGateway {
  final calls = <Map<String, dynamic>>[];
  bool fail = false;
  bool empty = false;
  int closed = 0;
  Completer<Retrieval>? pending;
  @override
  Future<List<Tool>> listTools() async => [searchTool];
  @override
  Future<Retrieval> callTool(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    calls.add({'name': name, 'arguments': arguments});
    if (fail) throw AppFailure.network;
    if (pending != null) return pending!.future;
    return Retrieval({}, empty ? [] : [sourceBlock]);
  }

  @override
  Future<void> close() async {
    closed++;
  }
}

class FakeLlm implements LlmProvider {
  int calls = 0;
  final requests = <Map<String, dynamic>>[];
  bool ignoreTools = false;
  String answer = 'Attributed answer https://example.org/reference';
  Object? failure;
  @override
  Future<Map<String, dynamic>> complete({
    required Uri baseUrl,
    required String model,
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
    required bool requireTool,
  }) async {
    if (failure != null) throw failure!;
    requests.add(
      jsonDecode(
        jsonEncode({
          'messages': messages,
          'tools': tools,
          'requireTool': requireTool,
        }),
      ) as Map<String, dynamic>,
    );
    if (calls++ == 0 && !ignoreTools) {
      return {
        'stop_reason': 'tool_use',
        'content': [
          {
            'type': 'tool_use',
            'id': 'call_1',
            'name': searchTool.name,
            'input': {'keywords': 'question'},
          },
        ],
      };
    }
    return {
      'stop_reason': 'end_turn',
      'content': [
        {'type': 'text', 'text': answer},
      ],
    };
  }

  @override
  void close() {}
}

void main() {
  late AppDatabase db;
  late ConversationRepository conversations;
  late FakeMcp mcp;
  late FakeLlm llm;
  late ChatRepository chat;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    conversations = ConversationRepository(db);
    mcp = FakeMcp();
    llm = FakeLlm();
    chat = ChatRepository(conversations, mcp, llm);
  });
  tearDown(() => db.close());
  Future<int> create(String mode) async {
    final id = await conversations.create('question', mode);
    chat.activate(id);
    return id;
  }

  test('direct mode discovers schema and never calls the model', () async {
    final id = await create('search');
    await chat.send(id, 'question', const AppConfig(language: 'en'));
    expect(mcp.calls.single['arguments'], {
      'keywords': 'question',
      'language': 'en',
    });
    expect(llm.calls, 0);
    final messages = await conversations.watchMessages(id).first;
    expect(messages.last.message.content, sourceBlock.rawText);
    expect(
      messages.last.sources.single.sourceUrl,
      sourceBlock.links.single.url,
    );
    expect(messages.first.message.status, 'sent');
  });
  test(
    'failed question is saved before network and retry does not duplicate it',
    () async {
      final id = await create('search');
      mcp.fail = true;
      await expectLater(
        chat.send(id, 'question', const AppConfig()),
        throwsA(AppFailure.network),
      );
      final failed = (await conversations.history(id)).single;
      expect(failed.status, 'failed');
      mcp.fail = false;
      await chat.send(
        id,
        'question',
        const AppConfig(),
        retryMessageId: failed.id,
      );
      expect(
        (await conversations.history(id)).where((m) => m.role == 'user').length,
        1,
      );
      expect((await conversations.history(id)).first.status, 'sent');
    },
  );
  test(
    'late network response cannot write after archive; reading stays offline',
    () async {
      final id = await create('search');
      mcp.pending = Completer<Retrieval>();
      final sending = chat.send(id, 'question', const AppConfig());
      final outcome = expectLater(sending, throwsA(AppFailure.cancelled));
      while (mcp.calls.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      await chat.end(id);
      mcp.pending!.complete(const Retrieval({}, [sourceBlock]));
      await outcome;
      final count = mcp.calls.length;
      expect((await conversations.history(id)).single.status, 'failed');
      await conversations.watchMessages(id).first;
      expect(mcp.calls.length, count);
      expect(llm.calls, 0);
      expect(mcp.closed, 1);
    },
  );
  test('Claude tool loop uses discovered schema and only this conversation history', () async {
    final oldId = await conversations.create('private old question', 'chat');
    await conversations.saveQuestion(oldId, 'private old question');
    await conversations.archive(oldId);
    final id = await create('chat');
    await chat.send(
      id,
      'question',
      const AppConfig(
        mode: 'chat',
        proxyUrl: 'https://proxy.example/v1/messages',
        model: 'proxy-model',
        historyLimit: 1,
      ),
    );
    expect(llm.calls, 2);
    expect(llm.requests.first['requireTool'], isTrue);
    expect(jsonEncode(llm.requests), isNot(contains('private old question')));
    expect(
      llm.requests.first['tools'][0]['input_schema'],
      searchTool.inputSchema.toJson(),
    );
    final messages = await conversations.watchMessages(id).first;
    expect(messages.map((m) => m.message.role), ['user', 'tool', 'assistant']);
    expect(messages[1].sources.single.rawText, sourceBlock.rawText);
    expect(
      llm.requests.last['messages'].last['content'][0]['type'],
      'tool_result',
    );
  });
  test(
    'an ungrounded model reply is replaced with an empty-results message',
    () async {
      llm.ignoreTools = true;
      final id = await create('chat');
      await chat.send(
        id,
        'question',
        const AppConfig(
          mode: 'chat',
          language: 'en',
          proxyUrl: 'https://proxy.example/v1/messages',
          model: 'proxy-model',
        ),
      );
      expect(
        (await conversations.history(id)).last.content,
        startsWith('No linked sources'),
      );
    },
  );
  test('chat without proxy fails safely and keeps question', () async {
    final id = await create('chat');
    await expectLater(
      chat.send(id, 'question', const AppConfig(mode: 'chat')),
      throwsA(AppFailure.proxyConfiguration),
    );
    expect((await conversations.history(id)).single.status, 'failed');
    expect(llm.calls, 0);
  });
  test('empty direct results are explicit', () async {
    mcp.empty = true;
    final id = await create('search');
    await chat.send(id, 'question', const AppConfig(language: 'en'));
    expect(
      (await conversations.history(id)).last.content,
      startsWith('No linked sources'),
    );
  });
  test(
    'model citations accept sentence punctuation and reject invented links',
    () async {
      final id = await create('chat');
      const config = AppConfig(
        mode: 'chat',
        proxyUrl: 'https://proxy.example/v1/messages',
        model: 'proxy-model',
      );
      llm.answer = 'Attributed answer https://example.org/reference.';
      await chat.send(id, 'question', config);
      expect((await conversations.history(id)).last.content, llm.answer);
      llm.calls = 0;
      llm.answer = 'Invented source https://example.org/other';
      await expectLater(
        chat.send(id, 'another question', config),
        throwsA(AppFailure.model),
      );
      expect((await conversations.history(id)).last.status, 'failed');
    },
  );
  test(
    'ending an old conversation cannot close a newer conversation session',
    () async {
      final first = await create('search');
      await chat.end(first);
      final second = await create('search');
      final closes = mcp.closed;
      await chat.end(first);
      expect(mcp.closed, closes);
      await chat.send(second, 'question', const AppConfig());
      expect((await conversations.history(second)).first.status, 'sent');
    },
  );
  test(
    'empty result text uses the conversation language from generated resources',
    () async {
      mcp.empty = true;
      final id = await create('search');
      await chat.send(id, 'question', const AppConfig(language: 'ar'));
      expect(
        (await conversations.history(id)).last.content,
        'لم يُعثر على مصادر مرتبطة بهذا السؤال. جرّب كلمات بحث أخرى.',
      );
    },
  );
  test(
    'resumed chat sends prior history and appends to the same conversation',
    () async {
      final id = await create('chat');
      const config = AppConfig(
        mode: 'chat',
        language: 'en',
        proxyUrl: 'https://proxy.example/v1/messages',
        model: 'proxy-model',
      );
      await chat.send(id, 'first question', config);
      await chat.end(id);
      final calls = mcp.calls.length;
      await chat.resume(id);
      expect(mcp.calls.length, calls);
      expect((await conversations.dao.conversation(id)).state, 'active');
      llm.calls = 0;
      await chat.send(id, 'follow-up question', config);
      expect(
        jsonEncode(llm.requests[2]['messages']),
        contains('first question'),
      );
      expect(
        jsonEncode(llm.requests[2]['messages']),
        contains('follow-up question'),
      );
      expect(
        (await conversations.history(id)).where((m) => m.role == 'user').length,
        2,
      );
      expect((await db.select(db.conversations).get()).length, 1);
    },
  );
  test('a response from the old session cannot append after resuming the same conversation', () async {
    final id = await create('search');
    final oldResponse = Completer<Retrieval>();
    mcp.pending = oldResponse;
    final oldSend = chat.send(id, 'old question', const AppConfig());
    final outcome = expectLater(oldSend, throwsA(AppFailure.cancelled));
    while (mcp.calls.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    await chat.end(id);
    await chat.resume(id);
    mcp.pending = null;
    await chat.send(id, 'new question', const AppConfig());
    oldResponse.complete(const Retrieval({}, [sourceBlock]));
    await outcome;
    final history = await conversations.history(id);
    expect(history.where((m) => m.role == 'user').map((m) => m.status), [
      'failed',
      'sent',
    ]);
    expect(history.where((m) => m.role == 'tool').length, 1);
  });
  test(
    'Dio failures map to localized error types and retain the saved question',
    () async {
      const config = AppConfig(
        mode: 'chat',
        proxyUrl: 'https://proxy.example/v1/messages',
        model: 'proxy-model',
      );
      final mappings = <DioExceptionType, AppFailure>{
        DioExceptionType.connectionTimeout: AppFailure.timeout,
        DioExceptionType.sendTimeout: AppFailure.timeout,
        DioExceptionType.receiveTimeout: AppFailure.timeout,
        DioExceptionType.transformTimeout: AppFailure.timeout,
        DioExceptionType.cancel: AppFailure.cancelled,
        DioExceptionType.badResponse: AppFailure.model,
        DioExceptionType.connectionError: AppFailure.network,
        DioExceptionType.badCertificate: AppFailure.network,
        DioExceptionType.unknown: AppFailure.network,
      };
      for (final mapping in mappings.entries) {
        final id = await create('chat');
        llm.failure = DioException(
          requestOptions: RequestOptions(
            path: 'https://proxy.example/v1/messages',
          ),
          type: mapping.key,
        );
        await expectLater(
          chat.send(id, 'question', config),
          throwsA(mapping.value),
        );
        final message = (await conversations.history(id)).single;
        expect(message.content, 'question');
        expect(message.status, 'failed');
        await chat.end(id);
      }
      final id = await create('chat');
      llm.failure = DioException(
        requestOptions: RequestOptions(
          path: 'https://proxy.example/v1/messages',
        ),
        error: const FormatException('Invalid JSON'),
      );
      await expectLater(
        chat.send(id, 'question', config),
        throwsA(AppFailure.model),
      );
    },
  );
}
