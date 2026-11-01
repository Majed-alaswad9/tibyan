import 'package:flutter/material.dart';
import 'package:tibyan/models/retrieval.dart';
import 'package:tibyan/l10n/localization.dart';

export 'package:tibyan/l10n/localization.dart';
import 'package:url_launcher/url_launcher.dart';

class Notice extends StatelessWidget {
  const Notice({super.key});
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsetsDirectional.only(end: 10, top: 3),
              child: Icon(Icons.info_outline, size: 18),
            ),
            Expanded(
              child: Text(
                context.l10n.retrievalNotice,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
  });
  final Widget title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: title, actions: actions),
    body: SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: child,
        ),
      ),
    ),
    bottomNavigationBar: const Notice(),
    floatingActionButton: floatingActionButton,
  );
}

Future<void> showFailure(BuildContext context, AppFailure failure) async {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(failure.message(context.l10n))));
}

Future<void> openSource(BuildContext context, String url) async {
  try {
    if (!isWebUrl(url) ||
        !await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        )) {
      if (context.mounted) await showFailure(context, AppFailure.network);
    }
  } catch (_) {
    if (context.mounted) await showFailure(context, AppFailure.network);
  }
}

TextDirection contentDirection(String text) =>
    RegExp(r'[\u0600-\u06ff]').hasMatch(text)
    ? TextDirection.rtl
    : TextDirection.ltr;
