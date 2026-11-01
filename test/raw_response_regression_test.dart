import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/data/database.dart';
import 'package:tibyan/l10n/app_localizations.dart';
import 'package:tibyan/ui/chat_screen.dart';

void main() {
  testWidgets(
    'source cards show readable text without a raw-response expander',
    (tester) async {
      final message = StoredMessage(
        Message(
          id: 1,
          conversationId: 1,
          role: 'tool',
          content: 'Source text',
          createdAt: DateTime(2026),
          status: 'sent',
        ),
        [],
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: MessageList(stream: Stream.value([message]))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('الاستجابة الأصلية'), findsNothing);
      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.byType(SelectableText), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
