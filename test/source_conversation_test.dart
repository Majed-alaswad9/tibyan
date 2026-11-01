import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:provider/provider.dart';
import 'package:tibyan/data/chat_repository.dart';
import 'package:tibyan/data/conversation_repository.dart';
import 'package:tibyan/data/database.dart';
import 'package:tibyan/main.dart';
import 'package:tibyan/models/retrieval.dart';
import 'package:tibyan/models/settings.dart';
import 'package:tibyan/ui/chat_screen.dart';
import 'package:tibyan/ui/view_models.dart';
import 'package:tibyan/ui/source_presentation.dart';

import 'repositories/chat_repository_test.dart' show FakeMcp, FakeLlm;

Future<void> settleDatabase(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 40)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'saved search shows readable results and can continue the same conversation',
    (tester) async {
      await initializeDateFormatting('ar');
      final db = AppDatabase(NativeDatabase.memory());
      final conversations = ConversationRepository(db);
      final mcp = FakeMcp();
      final llm = FakeLlm();
      final payload = jsonDecode(
        File('test/fixtures/search_response.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final retrieval = Retrieval.fromMcp(
        'search',
        CallToolResult.fromJson(payload),
      );
      final rawJson = (payload['content'] as List).first['text'] as String;
      final id = (await tester.runAsync(() async {
        final id = await conversations.create('الصبر', 'search');
        final question = await conversations.saveQuestion(id, 'الصبر');
        await conversations.saveReply(id, question, '', retrieval.blocks);
        await conversations.archive(id);
        return id;
      }))!;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: conversations),
            Provider.value(value: ChatRepository(conversations, mcp, llm)),
            ChangeNotifierProvider(
              create: (_) =>
                  SettingsViewModel(conversations, const AppConfig()),
            ),
          ],
          child: const TibyanApp(),
        ),
      );
      await settleDatabase(tester);
      await tester.tap(find.text('الصبر'));
      await settleDatabase(tester);
      expect(find.byType(SavedConversationScreen), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is SelectableText && widget.data == rawJson,
        ),
        findsNothing,
        reason: 'Wire-format JSON must not appear as the answer.',
      );
      expect(find.textContaining('Every result you carry'), findsNothing);
      expect(find.text('متابعة المحادثة'), findsOneWidget);
      expect(mcp.calls, isEmpty);
      await tester.tap(find.text('متابعة المحادثة'));
      await settleDatabase(tester);
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(
        mcp.calls,
        isEmpty,
        reason: 'Opening the composer should stay offline.',
      );
      await tester.enterText(find.byType(TextField), 'وما الدليل؟');
      await tester.tap(find.byTooltip('إرسال السؤال'));
      await settleDatabase(tester);
      expect(mcp.calls.length, 1);
      final storedSources = (await tester.runAsync(
        () => conversations.history(id),
      ))!;
      expect(
        storedSources.where((m) => m.role == 'tool').map((m) => m.content),
        contains(rawJson),
      );
      final history = (await tester.runAsync(() => conversations.history(id)))!;
      expect(history.where((m) => m.role == 'user').map((m) => m.content), [
        'الصبر',
        'وما الدليل؟',
      ]);
      expect(
        (await tester.runAsync(() => db.select(db.conversations).get()))!
            .length,
        1,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settleDatabase(tester);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('متابعة المحادثة'), findsOneWidget);
      await tester.tap(find.text('متابعة المحادثة'));
      await settleDatabase(tester);
      expect(find.byType(TextField), findsOneWidget);
      expect(mcp.calls.length, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      final closing = db.close();
      await tester.pumpAndSettle();
      await closing;
    },
  );
  test(
    'source presentation groups each turn and preserves exact source wording',
    () {
      final now = DateTime(2026);
      StoredMessage item(
        int id,
        String role,
        String content, [
        List<MessageSource> sources = const [],
      ]) => StoredMessage(
        Message(
          id: id,
          conversationId: 1,
          role: role,
          content: content,
          createdAt: now,
          status: 'sent',
        ),
        sources,
      );
      const exact = '  Exact source wording.\n\n';
      const raw = '$exact──────── CITE ────────\nInstructions for clients.';
      final source = MessageSource(
        id: 1,
        messageId: 2,
        toolName: 'search',
        sourceUrl: 'https://example.org/source',
        referenceLabel: 'Reference',
        rawText: raw,
      );
      final messages = [
        item(1, 'user', 'first question'),
        item(
          2,
          'tool',
          '{"results":[{"title":"Reference","url":"https://example.org/source"}]}',
          [source],
        ),
        item(3, 'tool', raw, [source]),
        item(4, 'user', 'follow-up'),
        item(5, 'tool', '{"text":"Exact fetched text."}', [source]),
      ];
      final entries = MessageEntry.group(messages);
      expect(entries.length, 4);
      final first = entries[1].source!;
      expect(first.texts, [exact]);
      expect(first.sources.length, 1);
      expect(messages[2].message.content, raw);
      expect(entries.last.source!.texts, ['Exact fetched text.']);
    },
  );
}
