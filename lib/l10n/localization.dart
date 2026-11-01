import 'package:flutter/widgets.dart';
import 'package:tibyan/l10n/app_localizations.dart';
import 'package:tibyan/models/retrieval.dart';

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension LocalizedFailure on AppFailure {
  String message(AppLocalizations l10n) => switch (this) {
    AppFailure.network => l10n.networkError,
    AppFailure.timeout => l10n.requestTimeoutError,
    AppFailure.tool => l10n.sourceToolError,
    AppFailure.noSearchTool => l10n.noSearchToolError,
    AppFailure.proxyConfiguration => l10n.proxyConfigurationError,
    AppFailure.model => l10n.modelError,
    AppFailure.cancelled => l10n.cancelledError,
    AppFailure.storage => l10n.storageError,
  };
}
