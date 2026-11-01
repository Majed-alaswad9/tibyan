import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get mode =>
      text().customConstraint("NOT NULL CHECK (mode IN ('search', 'chat'))")();
  TextColumn get state => text().customConstraint(
    "NOT NULL DEFAULT 'active' CHECK (state IN ('active', 'archived'))",
  )();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
}

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId =>
      integer().references(Conversations, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => text().customConstraint(
    "NOT NULL CHECK (role IN ('user', 'assistant', 'tool'))",
  )();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get status => text().customConstraint(
    "NOT NULL CHECK (status IN ('sent', 'failed'))",
  )();
}

class MessageSources extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get messageId =>
      integer().references(Messages, #id, onDelete: KeyAction.cascade)();
  TextColumn get toolName => text()();
  TextColumn get sourceUrl => text()();
  TextColumn get referenceLabel => text()();
  TextColumn get rawText => text()();
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [Conversations, Messages, MessageSources, AppSettings],
  daos: [ConversationDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'tibyan'));
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX messages_conversation ON messages (conversation_id, id)',
      );
      await customStatement(
        'CREATE INDEX sources_message ON message_sources (message_id)',
      );
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

class StoredMessage {
  const StoredMessage(this.message, this.sources);
  final Message message;
  final List<MessageSource> sources;
}

@DriftAccessor(tables: [Conversations, Messages, MessageSources, AppSettings])
class ConversationDao extends DatabaseAccessor<AppDatabase>
    with _$ConversationDaoMixin {
  ConversationDao(super.db);

  Stream<List<Conversation>> watchArchive(String query) {
    final search = query.trim();
    final statement = select(conversations)
      ..where((c) => c.state.equals('archived'));
    if (search.isNotEmpty) {
      final matchingMessages = selectOnly(messages)
        ..addColumns([messages.conversationId])
        ..where(messages.content.contains(search));
      statement.where(
        (c) => c.title.contains(search) | c.id.isInQuery(matchingMessages),
      );
    }
    return (statement..orderBy([
          (c) => OrderingTerm.desc(c.updatedAt),
          (c) => OrderingTerm.desc(c.id),
        ]))
        .watch();
  }

  Future<Conversation> conversation(int id) =>
      (select(conversations)..where((c) => c.id.equals(id))).getSingle();
  Stream<Conversation?> watchConversation(int id) => (select(
    conversations,
  )..where((c) => c.id.equals(id))).watchSingleOrNull();

  Stream<List<StoredMessage>> watchMessages(int id) {
    final query =
        select(messages).join([
            leftOuterJoin(
              messageSources,
              messageSources.messageId.equalsExp(messages.id),
            ),
          ])
          ..where(messages.conversationId.equals(id))
          ..orderBy([
            OrderingTerm.asc(messages.id),
            OrderingTerm.asc(messageSources.id),
          ]);
    return query.watch().map((rows) {
      final result = <int, StoredMessage>{};
      for (final row in rows) {
        final message = row.readTable(messages);
        final item = result.putIfAbsent(
          message.id,
          () => StoredMessage(message, []),
        );
        final source = row.readTableOrNull(messageSources);
        if (source != null) item.sources.add(source);
      }
      return result.values.toList();
    });
  }

  Future<List<Message>> history(int id) =>
      (select(messages)
            ..where((m) => m.conversationId.equals(id))
            ..orderBy([(m) => OrderingTerm.asc(m.id)]))
          .get();

  Future<void> requireActive(int id) async {
    if ((await conversation(id)).state != 'active') {
      throw StateError('Archive is read-only');
    }
  }

  Future<void> recoverInterrupted() => transaction(() async {
    // A process kill cannot run lifecycle hooks; recover incomplete turns on launch.
    await (update(conversations)..where((c) => c.state.equals('active'))).write(
      const ConversationsCompanion(state: Value('archived')),
    );
  });
}
