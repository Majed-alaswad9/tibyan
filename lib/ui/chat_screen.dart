import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tibyan/data/chat_repository.dart';
import 'package:tibyan/data/conversation_repository.dart';
import 'package:tibyan/data/database.dart';
import 'package:tibyan/models/retrieval.dart';
import 'package:tibyan/ui/archive_screen.dart';
import 'package:tibyan/ui/common.dart';
import 'package:tibyan/ui/view_models.dart';
import 'package:tibyan/ui/source_presentation.dart';
import 'package:tibyan/ui/source_excerpt.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, this.initialQuestion = '', this.conversation});
  final String initialQuestion;
  final Conversation? conversation;
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => ChatViewModel(
      context.read<ChatRepository>(),
      context.read<SettingsViewModel>().config.withMode(
        conversation?.mode ?? context.read<SettingsViewModel>().config.mode,
      ),
      initialQuestion: initialQuestion,
      conversationId: conversation?.id,
    ),
    child: const _ActivePage(),
  );
}

class _ActivePage extends StatefulWidget {
  const _ActivePage();
  @override
  State<_ActivePage> createState() => _ActivePageState();
}

class _ActivePageState extends State<_ActivePage> {
  late final ChatViewModel _vm;
  late final TextEditingController _input;
  late final AppLifecycleListener _lifecycle;
  final _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    _vm = context.read<ChatViewModel>();
    _input = TextEditingController(text: _vm.initialQuestion);
    _vm.touch();
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden ||
            state == AppLifecycleState.detached) {
          unawaited(_vm.end());
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final question = _input.text;
    if (question.trim().isEmpty || _vm.busy || _vm.ended) return;
    await _vm.send(question);
    // Retain the draft if local persistence failed before a message was inserted.
    if (mounted && _vm.id != null) {
      final history = await _vm.repository.conversations.history(_vm.id!);
      if (mounted &&
          _input.text == question &&
          history.any(
            (m) => m.role == 'user' && m.content == question.trim(),
          )) {
        _input.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) unawaited(_vm.end());
    },
    child: Listener(
      onPointerDown: (_) => _vm.touch(),
      child: PageFrame(
        title: Text(
          _vm.config.mode == 'search'
              ? context.l10n.searchSources
              : context.l10n.askWithSources,
        ),
        child: Column(
          children: [
            Expanded(
              child: Selector<ChatViewModel, Stream<List<StoredMessage>>?>(
                selector: (_, vm) => vm.messages,
                builder: (context, stream, _) {
                  if (stream == null) return const _QuestionIntro();
                  return MessageList(
                    stream: stream,
                    onRetry: (message) =>
                        _vm.send(message.content, retryMessageId: message.id),
                  );
                },
              ),
            ),
            Consumer<ChatViewModel>(
              builder: (context, vm, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (vm.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Text(
                        vm.error!.message(context.l10n),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (vm.busy && !vm.ended)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(context.l10n.retrievingSources),
                        ],
                      ),
                    ),
                  if (vm.ended)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(context.l10n.savedConversation),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: vm.busy ? null : vm.resume,
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: Text(context.l10n.continueConversation),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _input,
                              focusNode: _focus,
                              enabled: !vm.busy,
                              minLines: 1,
                              maxLines: 5,
                              maxLength: 4000,
                              onChanged: (_) => vm.touch(),
                              textInputAction: TextInputAction.newline,
                              decoration: InputDecoration(
                                labelText: context.l10n.yourQuestion,
                                hintText: context.l10n.questionHint,
                                counterText: '',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: vm.busy ? null : _send,
                            tooltip: context.l10n.sendQuestion,
                            icon: const Icon(Icons.arrow_upward),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _QuestionIntro extends StatelessWidget {
  const _QuestionIntro();
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(32),
    child: Column(
      children: [
        const SizedBox(height: 32),
        Icon(
          Icons.auto_stories_outlined,
          size: 56,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          context.l10n.beginWithQuestion,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(context.l10n.questionIntroduction, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Text(context.l10n.archiveOnLeaveNotice, textAlign: TextAlign.center),
      ],
    ),
  );
}

class SavedConversationScreen extends StatefulWidget {
  const SavedConversationScreen({super.key, required this.conversation});
  final Conversation conversation;
  @override
  State<SavedConversationScreen> createState() =>
      _SavedConversationScreenState();
}

class _SavedConversationScreenState extends State<SavedConversationScreen> {
  late final _messages = context.read<ConversationRepository>().watchMessages(
    widget.conversation.id,
  );
  late final _conversation = context
      .read<ConversationRepository>()
      .dao
      .watchConversation(widget.conversation.id);
  @override
  Widget build(BuildContext context) => StreamBuilder<Conversation?>(
    stream: _conversation,
    initialData: widget.conversation,
    builder: (context, snapshot) {
      final conversation = snapshot.data ?? widget.conversation;
      return PageFrame(
        title: Text(
          conversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          ConversationMenu(
            conversation: conversation,
            onDeleted: () {
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Chip(
                avatar: const Icon(Icons.offline_pin_outlined, size: 18),
                label: Text(context.l10n.savedOffline),
              ),
            ),
            Expanded(child: MessageList(stream: _messages)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatScreen(conversation: conversation),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(context.l10n.continueConversation),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class MessageList extends StatefulWidget {
  const MessageList({super.key, required this.stream, this.onRetry});
  final Stream<List<StoredMessage>> stream;
  final void Function(Message)? onRetry;
  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  late Stream<List<MessageEntry>> _entries;
  @override
  void initState() {
    super.initState();
    _entries = widget.stream.map(MessageEntry.group);
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _entries = widget.stream.map(MessageEntry.group);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<MessageEntry>>(
    stream: _entries,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text(AppFailure.storage.message(context.l10n)));
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final items = snapshot.data!;
      return ListView.builder(
        reverse: true,
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final entry = items[items.length - 1 - index];
          final item = entry.item;
          final message = item.message;
          if (entry.source != null) {
            return _MessageBubble(
              key: ValueKey(message.id),
              isUser: false,
              child: _SourceCard(presentation: entry.source!),
            );
          }
          final user = message.role == 'user';
          return _MessageBubble(
            key: ValueKey(message.id),
            isUser: user,
            child: Card(
              color: user
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user
                          ? context.l10n.yourQuestion
                          : context.l10n.assistantWording,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      message.content,
                      textDirection: contentDirection(message.content),
                    ),
                    if (user)
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () => openNewQuestion(
                              context,
                              question: message.content,
                              replace: true,
                            ),
                            icon: const Icon(Icons.copy_outlined, size: 16),
                            label: Text(context.l10n.copyQuestion),
                          ),
                          if (message.status == 'failed')
                            Text(
                              context.l10n.noCompleteReplySaved,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (widget.onRetry != null &&
                              message.status == 'failed' &&
                              index == 0)
                            Consumer<ChatViewModel>(
                              builder: (context, vm, _) => TextButton(
                                onPressed: vm.busy || vm.ended
                                    ? null
                                    : () => widget.onRetry!(message),
                                child: Text(context.l10n.retry),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({super.key, required this.isUser, required this.child});
  final bool isUser;
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: isUser
        ? AlignmentDirectional.centerStart
        : AlignmentDirectional.centerEnd,
    child: Padding(
      padding: EdgeInsetsDirectional.only(
        start: isUser ? 0 : 32,
        end: isUser ? 32 : 0,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: child,
      ),
    ),
  );
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.presentation});
  final SourcePresentation presentation;
  @override
  Widget build(BuildContext context) => Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  presentation.texts.isEmpty && presentation.excerpts.isEmpty
                      ? context.l10n.searchResults
                      : context.l10n.retrievedVerbatim,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final excerpt in presentation.excerpts)
            SourceExcerptCard(excerpt: excerpt),
          for (final text in presentation.texts)
            SelectableText(
              text,
              textDirection: contentDirection(text),
              style: const TextStyle(height: 1.9, letterSpacing: 0),
            ),
          if (presentation.sources.isEmpty)
            Text(
              context.l10n.noLinkedSourceReturned,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          for (final source in presentation.remainingSources)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: () => openSource(context, source.sourceUrl),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.referenceLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      source.sourceUrl,
                      textDirection: TextDirection.ltr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
