import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tibyan/data/conversation_repository.dart';
import 'package:tibyan/data/database.dart';
import 'package:tibyan/models/retrieval.dart';
import 'package:tibyan/ui/chat_screen.dart';
import 'package:tibyan/ui/common.dart';
import 'package:tibyan/ui/settings_screen.dart';
import 'package:tibyan/ui/view_models.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) =>
        ArchiveViewModel(context.read<ConversationRepository>()),
    child: const _ArchivePage(),
  );
}

Future<void> openNewQuestion(
  BuildContext context, {
  String question = '',
  bool replace = false,
}) async {
  await context.read<ChatViewModel?>()?.end();
  if (!context.mounted) return;
  final route = MaterialPageRoute<void>(
    builder: (_) => ChatScreen(initialQuestion: question),
  );
  if (replace) {
    Navigator.of(context).pushReplacement(route);
  } else {
    Navigator.of(context).push(route);
  }
}

class _ArchivePage extends StatelessWidget {
  const _ArchivePage();
  @override
  Widget build(BuildContext context) => PageFrame(
    title: Text(
      context.l10n.appName,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    actions: [
      IconButton(
        tooltip: context.l10n.settings,
        icon: const Icon(Icons.tune_rounded),
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
      ),
    ],
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => openNewQuestion(context),
      icon: const Icon(Icons.add),
      label: Text(context.l10n.newQuestion),
    ),
    child: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.archiveHeading,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700, height: 1.6),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.archiveDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  onChanged: context.read<ArchiveViewModel>().search,
                  decoration: InputDecoration(
                    labelText: context.l10n.searchArchive,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),
                Selector<ArchiveViewModel, bool>(
                  selector: (_, vm) => vm.pinnedOnly,
                  builder: (context, pinned, _) => Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(context.l10n.allSaved),
                        selected: !pinned,
                        onSelected: (_) => context
                            .read<ArchiveViewModel>()
                            .filterPinned(false),
                      ),
                      ChoiceChip(
                        label: Text(context.l10n.pinned),
                        avatar: const Icon(Icons.push_pin_outlined, size: 16),
                        selected: pinned,
                        onSelected: (_) =>
                            context.read<ArchiveViewModel>().filterPinned(true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Consumer<ArchiveViewModel>(
          builder: (context, vm, _) {
            if (vm.loading) {
              return const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (vm.error != null) {
              return SliverToBoxAdapter(
                child: Center(child: Text(vm.error!.message(context.l10n))),
              );
            }
            final items = vm.conversations
                .where((c) => !vm.pinnedOnly || c.isPinned)
                .toList();
            if (items.isEmpty) {
              return const SliverToBoxAdapter(child: _EmptyArchive());
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              sliver: SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  final day = DateUtils.dateOnly(item.updatedAt);
                  final newDay =
                      i == 0 ||
                      DateUtils.dateOnly(items[i - 1].updatedAt) != day;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (newDay)
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Text(
                            DateFormat.yMMMMd(context.l10n.localeName)
                                .format(day),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      Card(
                        child: ListTile(
                          contentPadding: const EdgeInsetsDirectional.only(
                            start: 16,
                            end: 4,
                            top: 8,
                            bottom: 8,
                          ),
                          leading: Icon(
                            item.mode == 'chat'
                                ? Icons.chat_bubble_outline
                                : Icons.manage_search,
                          ),
                          title: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(context.l10n.savedOffline),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.isPinned)
                                const Icon(Icons.push_pin, size: 16),
                              ConversationMenu(conversation: item),
                            ],
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  SavedConversationScreen(conversation: item),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    ),
  );
}

class _EmptyArchive extends StatelessWidget {
  const _EmptyArchive();
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
    child: Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/images/logo.png',
            width: 112,
            height: 112,
            cacheWidth: 336,
            semanticLabel: context.l10n.logoSemantics,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          context.l10n.emptyArchiveTitle,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(context.l10n.emptyArchiveDescription, textAlign: TextAlign.center),
      ],
    ),
  );
}

class ConversationMenu extends StatelessWidget {
  const ConversationMenu({
    super.key,
    required this.conversation,
    this.onDeleted,
  });
  final Conversation conversation;
  final VoidCallback? onDeleted;
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: context.l10n.conversationActions,
    onSelected: (action) async {
      final repository = context.read<ConversationRepository>();
      try {
        switch (action) {
          case 'pin':
            await repository.pin(conversation.id, !conversation.isPinned);
          case 'rename':
            final name = await showDialog<String>(
              context: context,
              builder: (_) => _RenameDialog(title: conversation.title),
            );
            if (name != null) await repository.rename(conversation.id, name);
          case 'export':
            final text = await repository.exportText(
              conversation.id,
              language: context.l10n.localeName,
            );
            if (!context.mounted) return;
            final box = context.findRenderObject() as RenderBox?;
            await SharePlus.instance.share(
              ShareParams(
                text: text,
                title: conversation.title,
                sharePositionOrigin: box == null
                    ? null
                    : box.localToGlobal(Offset.zero) & box.size,
              ),
            );
          case 'delete':
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(context.l10n.deleteConversationTitle),
                content: Text(context.l10n.deleteConversationDescription),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(context.l10n.delete),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await repository.delete(conversation.id);
              onDeleted?.call();
            }
        }
      } catch (_) {
        if (context.mounted) await showFailure(context, AppFailure.storage);
      }
    },
    itemBuilder: (context) => [
      PopupMenuItem(
        value: 'pin',
        child: Text(
          conversation.isPinned ? context.l10n.unpin : context.l10n.pin,
        ),
      ),
      PopupMenuItem(value: 'rename', child: Text(context.l10n.rename)),
      PopupMenuItem(value: 'export', child: Text(context.l10n.exportAsText)),
      PopupMenuItem(value: 'delete', child: Text(context.l10n.delete)),
    ],
  );
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.title});
  final String title;
  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.title);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.renameConversation),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLength: 120,
      decoration: InputDecoration(labelText: context.l10n.title),
      onSubmitted: (v) => Navigator.pop(context, v),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text),
        child: Text(context.l10n.save),
      ),
    ],
  );
}
