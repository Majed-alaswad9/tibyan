import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:tibyan/l10n/app_localizations.dart';
import 'package:tibyan/data/database.dart';
import 'package:tibyan/models/retrieval.dart';

class ConversationRepository {
  ConversationRepository(this.db);
  final AppDatabase db;
  ConversationDao get dao => db.conversationDao;

  Stream<List<Conversation>> watchArchive(String query) =>
      dao.watchArchive(query);
  Stream<List<StoredMessage>> watchMessages(int id) => dao.watchMessages(id);
  Future<List<Message>> history(int id) => dao.history(id);

  Future<int> create(String question, String mode) {
    final now = DateTime.now();
    return db
        .into(db.conversations)
        .insert(
          ConversationsCompanion.insert(
            title: question.runes.take(60).map(String.fromCharCode).join(),
            createdAt: now,
            updatedAt: now,
            mode: mode,
          ),
        );
  }

  Future<int> saveQuestion(int id, String question) => db.transaction(() async {
    await dao.requireActive(id);
    // Keep failed until the complete reply commits, including across a process kill.
    final messageId = await db
        .into(db.messages)
        .insert(
          MessagesCompanion.insert(
            conversationId: id,
            role: 'user',
            content: question,
            createdAt: DateTime.now(),
            status: 'failed',
          ),
        );
    await _touch(id);
    return messageId;
  });

  Future<void> saveReply(
    int id,
    int questionId,
    String answer,
    List<RetrievedBlock> blocks,
  ) => db.transaction(() async {
    await dao.requireActive(id);
    final question =
        await (db.select(db.messages)..where(
              (m) =>
                  m.id.equals(questionId) &
                  m.conversationId.equals(id) &
                  m.role.equals('user'),
            ))
            .getSingle();
    if (question.status == 'sent') {
      throw StateError('Question already answered');
    }
    for (final block in blocks) {
      final messageId = await db
          .into(db.messages)
          .insert(
            MessagesCompanion.insert(
              conversationId: id,
              role: 'tool',
              content: block.rawText,
              createdAt: DateTime.now(),
              status: 'sent',
            ),
          );
      for (final link in block.links) {
        await db
            .into(db.messageSources)
            .insert(
              MessageSourcesCompanion.insert(
                messageId: messageId,
                toolName: block.toolName,
                sourceUrl: link.url,
                referenceLabel: link.label,
                rawText: block.rawText,
              ),
            );
      }
    }
    if (answer.isNotEmpty) {
      await db
          .into(db.messages)
          .insert(
            MessagesCompanion.insert(
              conversationId: id,
              role: 'assistant',
              content: answer,
              createdAt: DateTime.now(),
              status: 'sent',
            ),
          );
    }
    await (db.update(db.messages)..where((m) => m.id.equals(questionId))).write(
      const MessagesCompanion(status: Value('sent')),
    );
    await _touch(id);
  });

  Future<void> _touch(int id) =>
      (db.update(db.conversations)..where((c) => c.id.equals(id))).write(
        ConversationsCompanion(updatedAt: Value(DateTime.now())),
      );
  Future<void> archive(int id) async {
    await (db.update(db.conversations)
          ..where((c) => c.id.equals(id) & c.state.equals('active')))
        .write(const ConversationsCompanion(state: Value('archived')));
  }

  Future<void> reopen(int id) async {
    await (db.update(db.conversations)..where((c) => c.id.equals(id))).write(
      const ConversationsCompanion(state: Value('active')),
    );
  }

  Future<void> rename(int id, String title) async {
    if (title.trim().isEmpty) return;
    await (db.update(db.conversations)..where((c) => c.id.equals(id))).write(
      ConversationsCompanion(title: Value(title.trim())),
    );
  }

  Future<void> pin(int id, bool value) async {
    await (db.update(db.conversations)..where((c) => c.id.equals(id))).write(
      ConversationsCompanion(isPinned: Value(value)),
    );
  }

  Future<void> delete(int id) async {
    await (db.delete(db.conversations)..where((c) => c.id.equals(id))).go();
  }

  Future<Map<String, String>> settings() async => {
    for (final row in await db.select(db.appSettings).get()) row.key: row.value,
  };
  Future<void> saveSettings(Map<String, String> values) =>
      db.transaction(() async {
        for (final entry in values.entries) {
          await db
              .into(db.appSettings)
              .insertOnConflictUpdate(
                AppSettingsCompanion.insert(key: entry.key, value: entry.value),
              );
        }
      });
  Future<String> exportText(int id, {String language = 'en'}) async {
    final l10n = await AppLocalizations.delegate.load(Locale(language));
    final conversation = await dao.conversation(id);
    final items = await dao.watchMessages(id).first;
    final text = StringBuffer(
      '${conversation.title}\n${conversation.createdAt.toIso8601String()}\n\n',
    );
    for (final item in items) {
      final role = switch (item.message.role) {
        'user' => l10n.exportUserRole,
        'assistant' => l10n.exportAssistantRole,
        _ => l10n.exportToolRole,
      };
      final status = item.message.status == 'sent'
          ? l10n.exportSentStatus
          : l10n.exportFailedStatus;
      text.writeln(
        '${l10n.exportMessageHeader(role, status)}\n${item.message.content}',
      );
      for (final source in item.sources) {
        text.writeln('${source.referenceLabel}: ${source.sourceUrl}');
      }
      text.writeln();
    }
    return text.toString();
  }
}
