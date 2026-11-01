import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tibyan/l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:tibyan/data/chat_repository.dart';
import 'package:tibyan/data/conversation_repository.dart';
import 'package:tibyan/data/database.dart';
import 'package:tibyan/data/llm_service.dart';
import 'package:tibyan/data/mcp_client_service.dart';
import 'package:tibyan/models/settings.dart';
import 'package:tibyan/ui/archive_screen.dart';
import 'package:tibyan/ui/view_models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Amiri Quran',
    ], await rootBundle.loadString('assets/fonts/OFL-Amiri.txt'));
  });
  await initializeDateFormatting('ar');
  runApp(const Bootstrap());
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  late final _database = AppDatabase();
  late final _conversations = ConversationRepository(_database);
  final _mcp = McpClientService();
  final _llm = LlmService();
  late final _load = _initialize();
  Future<AppConfig> _initialize() async {
    await _database.conversationDao.recoverInterrupted();
    return AppConfig.fromMap(await _conversations.settings());
  }

  @override
  void dispose() {
    unawaited(_mcp.close());
    _llm.close();
    unawaited(_database.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppConfig>(
    future: _load,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: snapshot.hasError
                    ? Text(
                        AppLocalizations.of(context).localStorageOpenError,
                        textAlign: TextAlign.center,
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
        );
      }
      return MultiProvider(
        providers: [
          Provider.value(value: _conversations),
          Provider(create: (_) => ChatRepository(_conversations, _mcp, _llm)),
          ChangeNotifierProvider(
            create: (_) => SettingsViewModel(_conversations, snapshot.data!),
          ),
        ],
        child: const TibyanApp(),
      );
    },
  );
}

class TibyanApp extends StatelessWidget {
  const TibyanApp({super.key});
  @override
  Widget build(BuildContext context) {
    final config = context.watch<SettingsViewModel>().config;
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: Locale(config.language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: config.themeMode,
      home: const ArchiveScreen(),
    );
  }
}

final _lightTheme = _theme(Brightness.light);
final _darkTheme = _theme(Brightness.dark);

ThemeData _theme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xff006b56),
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    colorScheme: scheme,
    scaffoldBackgroundColor: brightness == Brightness.light
        ? const Color(0xfffaf9f5)
        : scheme.surface,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
}
