import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/data/database.dart';
import 'package:tibyan/l10n/app_localizations.dart';
import 'package:tibyan/ui/chat_screen.dart';

void main() {
  for (final language in ['ar', 'en']) {
    testWidgets('$language aligns questions and all replies on opposite sides', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Content direction must not change the side selected by the UI language.
      final question = language == 'ar'
          ? 'An English question'
          : 'سؤال بالعربية';
      final answer = language == 'ar' ? 'An English answer' : 'جواب بالعربية';
      const source = 'نص المصدر';
      StoredMessage message(int id, String role, String content) =>
          StoredMessage(
            Message(
              id: id,
              conversationId: 1,
              role: role,
              content: content,
              createdAt: DateTime(2026),
              status: 'sent',
            ),
            [],
          );
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: MessageList(
              stream: Stream.value([
                message(1, 'user', question),
                message(2, 'assistant', answer),
                message(3, 'tool', source),
              ]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Rect bubble(String text) => tester.getRect(
        find.ancestor(of: find.text(text), matching: find.byType(Card)),
      );
      final user = bubble(question);
      final assistant = bubble(answer);
      final retrieved = bubble(source);
      if (language == 'ar') {
        expect(user.right, closeTo(424, 1));
        expect(assistant.left, closeTo(16, 1));
        expect(retrieved.left, closeTo(16, 1));
        expect(user.center.dx, greaterThan(assistant.center.dx));
        expect(retrieved.right, lessThanOrEqualTo(392));
      } else {
        expect(user.left, closeTo(16, 1));
        expect(assistant.right, closeTo(424, 1));
        expect(retrieved.right, closeTo(424, 1));
        expect(user.center.dx, lessThan(assistant.center.dx));
        expect(retrieved.left, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);
    });
  }
}
