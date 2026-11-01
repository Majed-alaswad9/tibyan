import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/l10n/app_localizations.dart';
import 'package:tibyan/l10n/localization.dart';
import 'package:tibyan/models/retrieval.dart';

void main() {
  test('Arabic and English ARBs provide the same complete set of messages', () {
    Set<String> keys(String language) => (jsonDecode(
      File('lib/l10n/app_$language.arb').readAsStringSync(),
    ) as Map).keys.cast<String>().where((key) => !key.startsWith('@')).toSet();
    expect(keys('ar'), keys('en'));
  });

  test(
    'generated localizations cover errors, validation and export placeholders',
    () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final ar = await AppLocalizations.delegate.load(const Locale('ar'));
      expect(en.newQuestion, 'New question');
      expect(ar.newQuestion, 'سؤال جديد');
      expect(en.invalidProxyUrl, 'Enter a valid HTTPS proxy URL');
      expect(ar.invalidProxyUrl, 'أدخل رابط وسيط HTTPS صالحاً');
      for (final failure in AppFailure.values) {
        expect(failure.message(en), isNotEmpty);
        expect(failure.message(ar), isNot(failure.message(en)));
        expect(failure.message(ar), matches(RegExp(r'[\u0600-\u06ff]')));
      }
      expect(
        en.exportMessageHeader(en.exportUserRole, en.exportFailedStatus),
        'User [Failed]:',
      );
      expect(
        ar.exportMessageHeader(ar.exportUserRole, ar.exportFailedStatus),
        'المستخدم [فشلت]:',
      );
    },
  );
}
