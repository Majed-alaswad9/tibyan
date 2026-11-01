import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tibyan/models/retrieval.dart';
import 'package:tibyan/models/settings.dart';
import 'package:tibyan/ui/common.dart';
import 'package:tibyan/ui/view_models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _form = GlobalKey<FormState>();
  final _saving = ValueNotifier(false);
  late String _mode;
  late String _language;
  late String _theme;
  late final TextEditingController _proxy;
  late final TextEditingController _model;
  late final TextEditingController _history;
  @override
  void initState() {
    super.initState();
    final config = context.read<SettingsViewModel>().config;
    _mode = config.mode;
    _language = config.language;
    _theme = config.theme;
    _proxy = TextEditingController(text: config.proxyUrl);
    _model = TextEditingController(text: config.model);
    _history = TextEditingController(text: '${config.historyLimit}');
  }

  @override
  void dispose() {
    _saving.dispose();
    _proxy.dispose();
    _model.dispose();
    _history.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving.value || !_form.currentState!.validate()) return;
    _saving.value = true;
    try {
      await context.read<SettingsViewModel>().save(
        AppConfig(
          mode: _mode,
          language: _language,
          theme: _theme,
          proxyUrl: _proxy.text.trim(),
          model: _model.text.trim(),
          historyLimit: int.parse(_history.text),
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) await showFailure(context, AppFailure.storage);
    } finally {
      if (mounted) _saving.value = false;
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: Text(context.l10n.settings),
    child: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            context.l10n.readingExperience,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _language,
            decoration: InputDecoration(labelText: context.l10n.language),
            items: [
              DropdownMenuItem(
                value: 'ar',
                child: Text(context.l10n.arabicLanguage),
              ),
              DropdownMenuItem(
                value: 'en',
                child: Text(context.l10n.englishLanguage),
              ),
            ],
            onChanged: (v) => _language = v!,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _theme,
            decoration: InputDecoration(labelText: context.l10n.appearance),
            items: [
              for (final entry in {
                'system': context.l10n.systemTheme,
                'light': context.l10n.lightTheme,
                'dark': context.l10n.darkTheme,
              }.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (v) => _theme = v!,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _mode,
            decoration: InputDecoration(
              labelText: context.l10n.newConversationMode,
            ),
            items: [
              DropdownMenuItem(
                value: 'search',
                child: Text(context.l10n.directSearchMode),
              ),
              DropdownMenuItem(
                value: 'chat',
                child: Text(context.l10n.chatMode),
              ),
            ],
            onChanged: (v) => _mode = v!,
          ),
          const SizedBox(height: 8),
          Text(context.l10n.settingsScopeNotice),
          const SizedBox(height: 32),
          Text(
            context.l10n.claudeConnection,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(context.l10n.proxyDescription),
          const SizedBox(height: 16),
          TextFormField(
            controller: _proxy,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: context.l10n.proxyMessagesUrl,
              hintText: context.l10n.proxyUrlHint,
            ),
            validator: (v) {
              if (v!.trim().isEmpty && _mode != 'chat') return null;
              final uri = Uri.tryParse(v.trim());
              return uri != null &&
                      uri.scheme == 'https' &&
                      uri.host.isNotEmpty &&
                      uri.userInfo.isEmpty
                  ? null
                  : context.l10n.invalidProxyUrl;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _model,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: context.l10n.claudeModelId,
              hintText: context.l10n.modelIdHint,
            ),
            validator: (v) => _mode == 'chat' && v!.trim().isEmpty
                ? context.l10n.modelIdRequired
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _history,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: context.l10n.historyLimit),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              return n != null && n >= 1 && n <= 50
                  ? null
                  : context.l10n.invalidHistoryLimit;
            },
          ),
          const SizedBox(height: 24),
          ValueListenableBuilder<bool>(
            valueListenable: _saving,
            builder: (context, busy, _) => FilledButton(
              onPressed: busy ? null : _save,
              child: Text(
                busy ? context.l10n.saving : context.l10n.saveSettings,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
