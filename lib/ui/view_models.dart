import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tibyan/data/chat_repository.dart';
import 'package:tibyan/data/conversation_repository.dart';
import 'package:tibyan/data/database.dart';
import 'package:tibyan/models/retrieval.dart';
import 'package:tibyan/models/settings.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this.repository, this.config);
  final ConversationRepository repository;
  AppConfig config;
  Future<void> save(AppConfig value) async {
    await repository.saveSettings(value.toMap());
    config = value;
    notifyListeners();
  }
}

class ArchiveViewModel extends ChangeNotifier {
  ArchiveViewModel(this.repository) {
    _listen('');
  }
  final ConversationRepository repository;
  StreamSubscription<List<Conversation>>? _subscription;
  Timer? _debounce;
  List<Conversation> conversations = [];
  bool loading = true;
  bool pinnedOnly = false;
  AppFailure? error;
  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _listen(query));
  }

  void _listen(String query) {
    unawaited(_subscription?.cancel());
    _subscription = repository
        .watchArchive(query)
        .listen(
          (value) {
            conversations = value;
            loading = false;
            error = null;
            notifyListeners();
          },
          onError: (Object _) {
            error = AppFailure.storage;
            loading = false;
            notifyListeners();
          },
        );
  }

  void filterPinned(bool value) {
    pinnedOnly = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

class ChatViewModel extends ChangeNotifier {
  ChatViewModel(
    this.repository,
    this.config, {
    this.initialQuestion = '',
    int? conversationId,
  }) : id = conversationId {
    if (conversationId != null) {
      messages = repository.conversations.watchMessages(conversationId);
    }
  }
  final ChatRepository repository;
  final AppConfig config;
  final String initialQuestion;
  int? id;
  bool busy = false;
  bool ended = false;
  AppFailure? error;
  Timer? _idle;
  Future<void>? _ending;
  bool _disposed = false;
  bool _endRequested = false;
  Stream<List<StoredMessage>>? messages;
  void touch() {
    _idle?.cancel();
    if (!ended) {
      _idle = Timer(const Duration(minutes: 5), () => unawaited(end()));
    }
  }

  Future<void> send(String text, {int? retryMessageId}) async {
    final question = text.trim();
    if (busy || ended || question.isEmpty) return;
    busy = true;
    error = null;
    touch();
    notifyListeners();
    try {
      if (id == null) {
        id = await repository.conversations.create(question, config.mode);
        messages = repository.conversations.watchMessages(id!);
        repository.activate(id!);
        _notify();
      } else {
        await repository.resume(id!);
      }
      if (_endRequested || _disposed) {
        await repository.end(id!);
        return;
      }
      await repository.send(
        id!,
        question,
        config,
        retryMessageId: retryMessageId,
      );
    } on AppFailure catch (failure) {
      error = failure;
    } catch (_) {
      error = AppFailure.storage;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> resume() async {
    if (busy || !ended) return;
    await _ending;
    if (_disposed) return;
    _ending = null;
    _endRequested = false;
    ended = false;
    error = null;
    touch();
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> end() {
    _endRequested = true;
    ended = true;
    _idle?.cancel();
    _notify();
    if (id == null) return Future.value();
    return _ending ??= repository.end(id!).catchError((Object _) {
      error = AppFailure.storage;
      _notify();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _idle?.cancel();
    unawaited(end());
    super.dispose();
  }
}
