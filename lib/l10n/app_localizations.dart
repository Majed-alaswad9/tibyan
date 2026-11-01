import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @viewSource.
  ///
  /// In en, this message translates to:
  /// **'View source'**
  String get viewSource;

  /// No description provided for @searchSources.
  ///
  /// In en, this message translates to:
  /// **'Search sources'**
  String get searchSources;

  /// No description provided for @askWithSources.
  ///
  /// In en, this message translates to:
  /// **'Ask with sources'**
  String get askWithSources;

  /// No description provided for @retrievingSources.
  ///
  /// In en, this message translates to:
  /// **'Retrieving sources…'**
  String get retrievingSources;

  /// No description provided for @newQuestion.
  ///
  /// In en, this message translates to:
  /// **'New question'**
  String get newQuestion;

  /// No description provided for @yourQuestion.
  ///
  /// In en, this message translates to:
  /// **'Your question'**
  String get yourQuestion;

  /// No description provided for @questionHint.
  ///
  /// In en, this message translates to:
  /// **'Ask a question or a follow-up…'**
  String get questionHint;

  /// No description provided for @sendQuestion.
  ///
  /// In en, this message translates to:
  /// **'Send question'**
  String get sendQuestion;

  /// No description provided for @beginWithQuestion.
  ///
  /// In en, this message translates to:
  /// **'Begin with a question'**
  String get beginWithQuestion;

  /// No description provided for @questionIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Explore Qur’an, hadith, and published Islamic texts. Retrieved wording and source links are kept together.'**
  String get questionIntroduction;

  /// No description provided for @archiveOnLeaveNotice.
  ///
  /// In en, this message translates to:
  /// **'Your conversation is saved when you leave. You can continue it later.'**
  String get archiveOnLeaveNotice;

  /// No description provided for @assistantWording.
  ///
  /// In en, this message translates to:
  /// **'Assistant wording'**
  String get assistantWording;

  /// No description provided for @copyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Copy question'**
  String get copyQuestion;

  /// No description provided for @noCompleteReplySaved.
  ///
  /// In en, this message translates to:
  /// **'No complete reply saved'**
  String get noCompleteReplySaved;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @retrievedVerbatim.
  ///
  /// In en, this message translates to:
  /// **'Retrieved text · Verbatim'**
  String get retrievedVerbatim;

  /// No description provided for @noLinkedSourceReturned.
  ///
  /// In en, this message translates to:
  /// **'No linked source returned'**
  String get noLinkedSourceReturned;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @readingExperience.
  ///
  /// In en, this message translates to:
  /// **'Your reading experience'**
  String get readingExperience;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @newConversationMode.
  ///
  /// In en, this message translates to:
  /// **'New conversation mode'**
  String get newConversationMode;

  /// No description provided for @directSearchMode.
  ///
  /// In en, this message translates to:
  /// **'Direct search · No AI'**
  String get directSearchMode;

  /// No description provided for @chatMode.
  ///
  /// In en, this message translates to:
  /// **'Chat · Claude via proxy'**
  String get chatMode;

  /// No description provided for @settingsScopeNotice.
  ///
  /// In en, this message translates to:
  /// **'Mode changes apply to new conversations. Saved conversations can be read offline or continued later.'**
  String get settingsScopeNotice;

  /// No description provided for @claudeConnection.
  ///
  /// In en, this message translates to:
  /// **'Claude connection'**
  String get claudeConnection;

  /// No description provided for @proxyDescription.
  ///
  /// In en, this message translates to:
  /// **'Optional. Use your own HTTPS backend. It must keep the API key on the server and forward the Messages API. Questions and recent messages are sent to this backend in chat mode.'**
  String get proxyDescription;

  /// No description provided for @proxyMessagesUrl.
  ///
  /// In en, this message translates to:
  /// **'Proxy Messages URL'**
  String get proxyMessagesUrl;

  /// No description provided for @invalidProxyUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid HTTPS proxy URL'**
  String get invalidProxyUrl;

  /// No description provided for @claudeModelId.
  ///
  /// In en, this message translates to:
  /// **'Claude model ID'**
  String get claudeModelId;

  /// No description provided for @modelIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a model ID'**
  String get modelIdRequired;

  /// No description provided for @historyLimit.
  ///
  /// In en, this message translates to:
  /// **'Recent messages sent (1–50)'**
  String get historyLimit;

  /// No description provided for @invalidHistoryLimit.
  ///
  /// In en, this message translates to:
  /// **'Choose a number from 1 to 50'**
  String get invalidHistoryLimit;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get saveSettings;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Tibyan'**
  String get appName;

  /// No description provided for @archiveHeading.
  ///
  /// In en, this message translates to:
  /// **'A question. A source.\nKnowledge you can return to.'**
  String get archiveHeading;

  /// No description provided for @archiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Search trusted texts. Keep your discoveries offline.'**
  String get archiveDescription;

  /// No description provided for @searchArchive.
  ///
  /// In en, this message translates to:
  /// **'Search your archive'**
  String get searchArchive;

  /// No description provided for @allSaved.
  ///
  /// In en, this message translates to:
  /// **'All saved'**
  String get allSaved;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// No description provided for @savedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved · Available offline'**
  String get savedOffline;

  /// No description provided for @logoSemantics.
  ///
  /// In en, this message translates to:
  /// **'Tibyan logo'**
  String get logoSemantics;

  /// No description provided for @emptyArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Your discoveries belong here'**
  String get emptyArchiveTitle;

  /// No description provided for @emptyArchiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Ask your first question, or try a different archive search.\nEvery saved conversation stays ready to read offline.'**
  String get emptyArchiveDescription;

  /// No description provided for @conversationActions.
  ///
  /// In en, this message translates to:
  /// **'Conversation actions'**
  String get conversationActions;

  /// No description provided for @deleteConversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this conversation?'**
  String get deleteConversationTitle;

  /// No description provided for @deleteConversationDescription.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the saved messages and sources.'**
  String get deleteConversationDescription;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @exportAsText.
  ///
  /// In en, this message translates to:
  /// **'Export as text'**
  String get exportAsText;

  /// No description provided for @renameConversation.
  ///
  /// In en, this message translates to:
  /// **'Rename conversation'**
  String get renameConversation;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @retrievalNotice.
  ///
  /// In en, this message translates to:
  /// **'This app is for search and retrieval, not a source of fatwa. Refer to qualified scholars.'**
  String get retrievalNotice;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Tibyan · تبيان'**
  String get appTitle;

  /// No description provided for @arabicLanguage.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabicLanguage;

  /// No description provided for @englishLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @proxyUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://YOUR-BACKEND.example/v1/messages'**
  String get proxyUrlHint;

  /// No description provided for @modelIdHint.
  ///
  /// In en, this message translates to:
  /// **'Your proxy-supported model ID'**
  String get modelIdHint;

  /// No description provided for @localStorageOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open local storage. Restart the app.'**
  String get localStorageOpenError;

  /// No description provided for @noLinkedSourcesFound.
  ///
  /// In en, this message translates to:
  /// **'No linked sources were found. Try different search terms.'**
  String get noLinkedSourcesFound;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Check your connection and retry.'**
  String get networkError;

  /// No description provided for @requestTimeoutError.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. You can retry.'**
  String get requestTimeoutError;

  /// No description provided for @sourceToolError.
  ///
  /// In en, this message translates to:
  /// **'The source tool failed. Please retry.'**
  String get sourceToolError;

  /// No description provided for @noSearchToolError.
  ///
  /// In en, this message translates to:
  /// **'The server has no compatible search tool.'**
  String get noSearchToolError;

  /// No description provided for @proxyConfigurationError.
  ///
  /// In en, this message translates to:
  /// **'Configure your Claude proxy URL and model in Settings.'**
  String get proxyConfigurationError;

  /// No description provided for @modelError.
  ///
  /// In en, this message translates to:
  /// **'The model could not complete the answer. Please retry.'**
  String get modelError;

  /// No description provided for @cancelledError.
  ///
  /// In en, this message translates to:
  /// **'The question was saved without a complete reply.'**
  String get cancelledError;

  /// No description provided for @storageError.
  ///
  /// In en, this message translates to:
  /// **'Could not save data. Check device storage.'**
  String get storageError;

  /// No description provided for @exportUserRole.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get exportUserRole;

  /// No description provided for @exportAssistantRole.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get exportAssistantRole;

  /// No description provided for @exportToolRole.
  ///
  /// In en, this message translates to:
  /// **'Source tool'**
  String get exportToolRole;

  /// No description provided for @exportSentStatus.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get exportSentStatus;

  /// No description provided for @exportFailedStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get exportFailedStatus;

  /// Role and delivery status preceding an exported message.
  ///
  /// In en, this message translates to:
  /// **'{role} [{status}]:'**
  String exportMessageHeader(String role, String status);

  /// No description provided for @continueConversation.
  ///
  /// In en, this message translates to:
  /// **'Continue conversation'**
  String get continueConversation;

  /// No description provided for @savedConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation saved'**
  String get savedConversation;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get searchResults;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
