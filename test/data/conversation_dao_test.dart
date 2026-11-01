import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/data/conversation_repository.dart';
import 'package:tibyan/data/database.dart';
import 'package:tibyan/models/retrieval.dart';

void main() {
  late AppDatabase db;
  late ConversationRepository repository;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = ConversationRepository(db);
  });
  tearDown(() => db.close());

  test('stores exact source text, exports it, and cascades deletion', () async {
    final id = await repository.create('A question', 'search');
    final message = await repository.saveQuestion(id, 'A question');
    const raw = '  نصّ المصدر\n\nNo whitespace changes.  ';
    await repository.saveReply(id, message, '', [
      const RetrievedBlock(
        toolName: 'lookup',
        rawText: raw,
        links: [SourceLink('https://example.org/source', 'Reference')],
      ),
    ]);
    await repository.archive(id);
    final stored = await repository.watchMessages(id).first;
    expect(stored.first.message.status, 'sent');
    expect(stored.last.message.content, raw);
    expect(stored.last.sources.single.rawText, raw);
    expect(await repository.exportText(id), contains(raw));
    await repository.delete(id);
    expect(await db.select(db.messages).get(), isEmpty);
    expect(await db.select(db.messageSources).get(), isEmpty);
  });

  test(
    'archive is read only; interrupted questions survive restart recovery',
    () async {
      final id = await repository.create('Unanswered', 'chat');
      final questionId = await repository.saveQuestion(id, 'Unanswered');
      await db.conversationDao.recoverInterrupted();
      expect((await db.conversationDao.conversation(id)).state, 'archived');
      expect((await repository.history(id)).single.status, 'failed');
      await expectLater(
        repository.saveQuestion(id, 'Cannot continue'),
        throwsStateError,
      );
      await expectLater(
        repository.saveReply(id, questionId, 'Late reply', []),
        throwsStateError,
      );
      expect((await repository.history(id)).single.content, 'Unanswered');
    },
  );

  test(
    'archive streams search message content and preserve newest ordering',
    () async {
      final first = await repository.create('First', 'search');
      await repository.saveQuestion(first, 'needle in body');
      await repository.archive(first);
      final second = await repository.create('Second', 'chat');
      await repository.archive(second);
      expect((await repository.watchArchive('').first).map((c) => c.id), [
        second,
        first,
      ]);
      expect((await repository.watchArchive('needle').first).single.id, first);
      await repository.rename(first, 'Renamed');
      await repository.pin(first, true);
      final updated = await db.conversationDao.conversation(first);
      expect(updated.title, 'Renamed');
      expect(updated.isPinned, isTrue);
      await repository.saveSettings({'mode': 'chat', 'historyLimit': '4'});
      expect(await repository.settings(), {
        'mode': 'chat',
        'historyLimit': '4',
      });
    },
  );

  test(
    'invalid foreign keys and statuses fail at the storage boundary',
    () async {
      await expectLater(
        db
            .into(db.messages)
            .insert(
              MessagesCompanion.insert(
                conversationId: 999,
                role: 'user',
                content: 'orphan',
                createdAt: DateTime.now(),
                status: 'sent',
              ),
            ),
        throwsA(anything),
      );
      final id = await repository.create('Question', 'search');
      await expectLater(
        db
            .into(db.messages)
            .insert(
              MessagesCompanion.insert(
                conversationId: id,
                role: 'other',
                content: '',
                createdAt: DateTime.now(),
                status: 'sent',
              ),
            ),
        throwsA(anything),
      );
    },
  );
  test('exports localize labels without translating stored content', () async {
    final id = await repository.create('Original question', 'search');
    await repository.saveQuestion(id, 'Original question');
    final english = await repository.exportText(id, language: 'en');
    final arabic = await repository.exportText(id, language: 'ar');
    expect(english, contains('User [Failed]:\nOriginal question'));
    expect(arabic, contains('المستخدم [فشلت]:\nOriginal question'));
    expect((await repository.history(id)).single.content, 'Original question');
  });
}
