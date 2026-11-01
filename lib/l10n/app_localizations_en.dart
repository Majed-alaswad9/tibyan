// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get viewSource => 'View source';

  @override
  String get searchSources => 'Search sources';

  @override
  String get askWithSources => 'Ask with sources';

  @override
  String get retrievingSources => 'Retrieving sources…';

  @override
  String get newQuestion => 'New question';

  @override
  String get yourQuestion => 'Your question';

  @override
  String get questionHint => 'Ask a question or a follow-up…';

  @override
  String get sendQuestion => 'Send question';

  @override
  String get beginWithQuestion => 'Begin with a question';

  @override
  String get questionIntroduction =>
      'Explore Qur’an, hadith, and published Islamic texts. Retrieved wording and source links are kept together.';

  @override
  String get archiveOnLeaveNotice =>
      'Your conversation is saved when you leave. You can continue it later.';

  @override
  String get assistantWording => 'Assistant wording';

  @override
  String get copyQuestion => 'Copy question';

  @override
  String get noCompleteReplySaved => 'No complete reply saved';

  @override
  String get retry => 'Retry';

  @override
  String get retrievedVerbatim => 'Retrieved text · Verbatim';

  @override
  String get noLinkedSourceReturned => 'No linked source returned';

  @override
  String get settings => 'Settings';

  @override
  String get readingExperience => 'Your reading experience';

  @override
  String get language => 'Language';

  @override
  String get appearance => 'Appearance';

  @override
  String get systemTheme => 'System';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get newConversationMode => 'New conversation mode';

  @override
  String get directSearchMode => 'Direct search · No AI';

  @override
  String get chatMode => 'Chat · Claude via proxy';

  @override
  String get settingsScopeNotice =>
      'Mode changes apply to new conversations. Saved conversations can be read offline or continued later.';

  @override
  String get claudeConnection => 'Claude connection';

  @override
  String get proxyDescription =>
      'Optional. Use your own HTTPS backend. It must keep the API key on the server and forward the Messages API. Questions and recent messages are sent to this backend in chat mode.';

  @override
  String get proxyMessagesUrl => 'Proxy Messages URL';

  @override
  String get invalidProxyUrl => 'Enter a valid HTTPS proxy URL';

  @override
  String get claudeModelId => 'Claude model ID';

  @override
  String get modelIdRequired => 'Enter a model ID';

  @override
  String get historyLimit => 'Recent messages sent (1–50)';

  @override
  String get invalidHistoryLimit => 'Choose a number from 1 to 50';

  @override
  String get saving => 'Saving…';

  @override
  String get saveSettings => 'Save settings';

  @override
  String get appName => 'Tibyan';

  @override
  String get archiveHeading =>
      'A question. A source.\nKnowledge you can return to.';

  @override
  String get archiveDescription =>
      'Search trusted texts. Keep your discoveries offline.';

  @override
  String get searchArchive => 'Search your archive';

  @override
  String get allSaved => 'All saved';

  @override
  String get pinned => 'Pinned';

  @override
  String get savedOffline => 'Saved · Available offline';

  @override
  String get logoSemantics => 'Tibyan logo';

  @override
  String get emptyArchiveTitle => 'Your discoveries belong here';

  @override
  String get emptyArchiveDescription =>
      'Ask your first question, or try a different archive search.\nEvery saved conversation stays ready to read offline.';

  @override
  String get conversationActions => 'Conversation actions';

  @override
  String get deleteConversationTitle => 'Delete this conversation?';

  @override
  String get deleteConversationDescription =>
      'This permanently removes the saved messages and sources.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get unpin => 'Unpin';

  @override
  String get pin => 'Pin';

  @override
  String get rename => 'Rename';

  @override
  String get exportAsText => 'Export as text';

  @override
  String get renameConversation => 'Rename conversation';

  @override
  String get title => 'Title';

  @override
  String get save => 'Save';

  @override
  String get retrievalNotice =>
      'This app is for search and retrieval, not a source of fatwa. Refer to qualified scholars.';

  @override
  String get appTitle => 'Tibyan · تبيان';

  @override
  String get arabicLanguage => 'العربية';

  @override
  String get englishLanguage => 'English';

  @override
  String get proxyUrlHint => 'https://YOUR-BACKEND.example/v1/messages';

  @override
  String get modelIdHint => 'Your proxy-supported model ID';

  @override
  String get localStorageOpenError =>
      'Could not open local storage. Restart the app.';

  @override
  String get noLinkedSourcesFound =>
      'No linked sources were found. Try different search terms.';

  @override
  String get networkError =>
      'Could not connect. Check your connection and retry.';

  @override
  String get requestTimeoutError => 'The request timed out. You can retry.';

  @override
  String get sourceToolError => 'The source tool failed. Please retry.';

  @override
  String get noSearchToolError => 'The server has no compatible search tool.';

  @override
  String get proxyConfigurationError =>
      'Configure your Claude proxy URL and model in Settings.';

  @override
  String get modelError =>
      'The model could not complete the answer. Please retry.';

  @override
  String get cancelledError =>
      'The question was saved without a complete reply.';

  @override
  String get storageError => 'Could not save data. Check device storage.';

  @override
  String get exportUserRole => 'User';

  @override
  String get exportAssistantRole => 'Assistant';

  @override
  String get exportToolRole => 'Source tool';

  @override
  String get exportSentStatus => 'Sent';

  @override
  String get exportFailedStatus => 'Failed';

  @override
  String exportMessageHeader(String role, String status) {
    return '$role [$status]:';
  }

  @override
  String get continueConversation => 'Continue conversation';

  @override
  String get savedConversation => 'Conversation saved';

  @override
  String get searchResults => 'Search results';
}
