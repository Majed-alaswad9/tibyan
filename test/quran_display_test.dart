import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/data/database.dart';
import 'package:tibyan/l10n/app_localizations.dart';
import 'package:tibyan/ui/chat_screen.dart';
import 'package:tibyan/ui/source_excerpt.dart';
import 'package:tibyan/ui/source_presentation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final entry in {
      'Cairo': 'Cairo-Regular.ttf',
      'AmiriQuran': 'AmiriQuran.ttf',
    }.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(rootBundle.load('assets/fonts/${entry.value}'));
      await loader.load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  testWidgets(
    'Quran verses are isolated from search metadata and use a Quran font',
    (tester) async {
      final fixture = jsonDecode(
        File('test/fixtures/search_response.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final raw = (fixture['content'][1]['text'] as String).replaceFirst(
        '   https://hadeethenc',
        '   [matched: أحاديث]\n   https://hadeethenc',
      );
      final lines = raw.split('\n');
      final verse = '${lines[2]}\n';
      final message = StoredMessage(
        Message(
          id: 1,
          conversationId: 1,
          role: 'tool',
          content: raw,
          createdAt: DateTime(2026),
          status: 'sent',
        ),
        [
          MessageSource(
            id: 1,
            messageId: 1,
            toolName: 'search',
            sourceUrl:
                fixture['structuredContent']['results'][0]['url'] as String,
            referenceLabel:
                fixture['structuredContent']['results'][0]['title'] as String,
            rawText: raw,
          ),
          MessageSource(
            id: 2,
            messageId: 1,
            toolName: 'search',
            sourceUrl:
                fixture['structuredContent']['results'][1]['url'] as String,
            referenceLabel:
                fixture['structuredContent']['results'][1]['title'] as String,
            rawText: raw,
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: MessageList(stream: Stream.value([message]))),
        ),
      );
      await tester.pumpAndSettle();
      final verseWidget = find.byWidgetPredicate(
        (widget) => widget is SelectableText && widget.data == verse.trim(),
      );
      expect(
        verseWidget,
        findsOneWidget,
        reason: 'A verse must not share a paragraph with URLs, English markers or hadith.',
      );
      final text = tester.widget<SelectableText>(verseWidget);
      expect(text.style!.fontFamily, 'AmiriQuran');
      expect(text.style!.letterSpacing, 0);
      expect(text.textDirection, TextDirection.rtl);
    },
  );
  testWidgets(
    'bundled Quran font renders on narrow screens with large text in both themes',
    (tester) async {
      final fixture = jsonDecode(
        File('test/fixtures/search_response.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final raw = fixture['content'][1]['text'] as String;
      final verse = '${raw.split('\n')[2]}\n';
      final entry =
          fixture['structuredContent']['results'][0] as Map<String, dynamic>;
      final excerpt = SourceExcerpt(
        text: verse,
        isQuran: true,
        source: MessageSource(
          id: 1,
          messageId: 1,
          toolName: 'search',
          sourceUrl: entry['url'] as String,
          referenceLabel: entry['title'] as String,
          rawText: raw,
        ),
      );
      final preview = GlobalKey();
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.devicePixelRatio = 1;
      for (final brightness in Brightness.values) {
        for (final width in [320.0, 440.0]) {
          for (final scale in [1.0, 2.0]) {
            tester.view.physicalSize = Size(width, 900);
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            await tester.pumpWidget(
              RepaintBoundary(
                key: preview,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: const Locale('ar'),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  theme: ThemeData(
                    fontFamily: 'Cairo',
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: const Color(0xff006b56),
                      brightness: brightness,
                    ),
                  ),
                  home: Scaffold(
                    body: SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: SourceExcerptCard(excerpt: excerpt),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '$brightness width=$width scale=$scale',
            );
            expect(
              tester.widget<SelectableText>(find.byType(SelectableText)).data,
              verse.trim(),
            );
            if (const bool.fromEnvironment('CAPTURE_PREVIEW') &&
                width == 440 &&
                scale == 1) {
              await tester.runAsync(() async {
                final boundary =
                    preview.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary;
                final image = await boundary.toImage(pixelRatio: 2);
                final data = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                File('/tmp/tibyan-quran-${brightness.name}.png')
                    .writeAsBytesSync(data!.buffer.asUint8List());
                image.dispose();
              });
            }
          }
        }
      }
    },
  );
  test('source excerpts retain exact Quran code points and matching notes', () {
    final fixture = jsonDecode(
      File('test/fixtures/search_response.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final raw = (fixture['content'][1]['text'] as String).replaceFirst(
      '   https://hadeethenc',
      '   [matched: أحاديث]\n   https://hadeethenc',
    );
    final refs = fixture['structuredContent']['results'] as List;
    final sources = [
      for (var i = 0; i < refs.length; i++)
        MessageSource(
          id: i,
          messageId: 1,
          toolName: 'search',
          sourceUrl: refs[i]['url'] as String,
          referenceLabel: refs[i]['title'] as String,
          rawText: raw,
        ),
    ];
    final message = StoredMessage(
      Message(
        id: 1,
        conversationId: 1,
        role: 'tool',
        content: raw,
        createdAt: DateTime(2026),
        status: 'sent',
      ),
      sources,
    );
    final presentation = SourcePresentation([message]);
    expect(presentation.excerpts.length, 2);
    final quran = presentation.excerpts.first;
    expect(quran.isQuran, isTrue);
    expect(quran.text.runes.toList(), '${raw.split('\n')[2]}\n'.runes.toList());
    expect(quran.source.sourceUrl, refs[0]['url']);
    expect(presentation.excerpts[1].isQuran, isFalse);
    expect(presentation.excerpts[1].notes, '   [matched: أحاديث]\n');
    expect(presentation.texts.single, contains('library: unavailable'));
    expect(presentation.remainingSources, isEmpty);
    expect(message.message.content, raw);
    final unknown = SourcePresentation([
      StoredMessage(message.message, [sources.first]),
    ]);
    expect(
      unknown.excerpts,
      isEmpty,
      reason: 'Do not associate unknown mixed results with a Quran citation.',
    );
    expect(unknown.texts.single, startsWith('1. [quran]'));
  });
}
