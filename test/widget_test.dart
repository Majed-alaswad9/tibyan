import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:tibyan/data/chat_repository.dart';
import 'package:tibyan/data/conversation_repository.dart';
import 'package:tibyan/data/database.dart';
import 'package:tibyan/main.dart';
import 'package:tibyan/models/settings.dart';
import 'package:tibyan/ui/chat_screen.dart';
import 'package:tibyan/ui/view_models.dart';

import 'repositories/chat_repository_test.dart' show FakeMcp, FakeLlm;

void main() {
  testWidgets('Arabic archive opens entirely offline without a composer', (
    tester,
  ) async {
    await initializeDateFormatting('ar');
    final db = AppDatabase(NativeDatabase.memory());
    final repository = ConversationRepository(db);
    final mcp = FakeMcp();
    final llm = FakeLlm();
    await tester.runAsync(() async {
      final id = await repository.create('سؤال محفوظ', 'search');
      await repository.saveQuestion(id, 'سؤال محفوظ');
      await repository.archive(id);
      return id;
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: repository),
          Provider.value(value: ChatRepository(repository, mcp, llm)),
          ChangeNotifierProvider(
            create: (_) => SettingsViewModel(repository, const AppConfig()),
          ),
        ],
        child: const TibyanApp(),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('سؤال محفوظ'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SavedConversationScreen), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('سؤال محفوظ'), findsNWidgets(2));
    expect(mcp.calls, isEmpty);
    expect(llm.calls, 0);
    expect(
      Directionality.of(tester.element(find.byType(SavedConversationScreen))),
      TextDirection.rtl,
    );
    await tester.tap(find.text('نسخ السؤال'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'سؤال محفوظ',
    );
    expect(mcp.calls, isEmpty);
    expect(llm.calls, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    final closing = db.close();
    await tester.pumpAndSettle();
    await closing;
  });
  testWidgets(
    'archive scrolls on small screens and large text in both themes',
    (tester) async {
      await initializeDateFormatting('ar');
      final db = AppDatabase(NativeDatabase.memory());
      final repository = ConversationRepository(db);
      await tester.runAsync(() => repository.settings());
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.devicePixelRatio = 1;
      for (final theme in ['light', 'dark']) {
        for (final size in [
          const Size(320, 568),
          const Size(390, 844),
          const Size(1024, 768),
        ]) {
          tester.view.physicalSize = size;
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          await tester.pumpWidget(
            MultiProvider(
              key: UniqueKey(),
              providers: [
                Provider.value(value: repository),
                Provider.value(
                  value: ChatRepository(repository, FakeMcp(), FakeLlm()),
                ),
                ChangeNotifierProvider(
                  create: (_) =>
                      SettingsViewModel(repository, AppConfig(theme: theme)),
                ),
              ],
              child: const TibyanApp(),
            ),
          );
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$theme $size');
          expect(find.text('سؤال جديد'), findsOneWidget);
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      final closing = db.close();
      await tester.pumpAndSettle();
      await closing;
    },
  );
  testWidgets('changing the saved language updates app strings and direction', (
    tester,
  ) async {
    await initializeDateFormatting('ar');
    final db = AppDatabase(NativeDatabase.memory());
    final repository = ConversationRepository(db);
    final settings = SettingsViewModel(
      repository,
      const AppConfig(language: 'en'),
    );
    await tester.runAsync(() => repository.settings());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: repository),
          Provider.value(
            value: ChatRepository(repository, FakeMcp(), FakeLlm()),
          ),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: const TibyanApp(),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pumpAndSettle();
    expect(find.text('New question'), findsOneWidget);
    expect(find.text('سؤال جديد'), findsNothing);
    expect(
      Directionality.of(tester.element(find.text('New question'))),
      TextDirection.ltr,
    );
    await tester.runAsync(() => settings.save(const AppConfig(language: 'ar')));
    await tester.pumpAndSettle();
    expect(find.text('سؤال جديد'), findsOneWidget);
    expect(find.text('New question'), findsNothing);
    expect(
      Directionality.of(tester.element(find.text('سؤال جديد'))),
      TextDirection.rtl,
    );
    expect((await tester.runAsync(repository.settings))!['language'], 'ar');
    await tester.pumpWidget(const SizedBox.shrink());
    settings.dispose();
    final closing = db.close();
    await tester.pumpAndSettle();
    await closing;
  });
}
