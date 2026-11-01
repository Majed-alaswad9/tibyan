// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get viewSource => 'عرض المصدر';

  @override
  String get searchSources => 'البحث في المصادر';

  @override
  String get askWithSources => 'محادثة بالمصادر';

  @override
  String get retrievingSources => 'جارٍ استرجاع المصادر…';

  @override
  String get newQuestion => 'سؤال جديد';

  @override
  String get yourQuestion => 'سؤالك';

  @override
  String get questionHint => 'اكتب سؤالك أو سؤالاً إضافياً…';

  @override
  String get sendQuestion => 'إرسال السؤال';

  @override
  String get beginWithQuestion => 'ابدأ بسؤال';

  @override
  String get questionIntroduction =>
      'تصفّح القرآن والحديث والنصوص الإسلامية المنشورة. يُحفظ النص المسترجع مع رابط مصدره.';

  @override
  String get archiveOnLeaveNotice =>
      'تُحفظ المحادثة عند مغادرتها، ويمكنك متابعتها لاحقاً.';

  @override
  String get assistantWording => 'صياغة المساعد';

  @override
  String get copyQuestion => 'نسخ السؤال';

  @override
  String get noCompleteReplySaved => 'لم يُحفظ رد مكتمل';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get retrievedVerbatim => 'نص مسترجع · كما ورد';

  @override
  String get noLinkedSourceReturned => 'لم يُرجع الخادم رابط مصدر';

  @override
  String get settings => 'الإعدادات';

  @override
  String get readingExperience => 'تجربة القراءة';

  @override
  String get language => 'اللغة';

  @override
  String get appearance => 'المظهر';

  @override
  String get systemTheme => 'النظام';

  @override
  String get lightTheme => 'فاتح';

  @override
  String get darkTheme => 'داكن';

  @override
  String get newConversationMode => 'نمط المحادثات الجديدة';

  @override
  String get directSearchMode => 'بحث مباشر · دون ذكاء اصطناعي';

  @override
  String get chatMode => 'محادثة · Claude عبر وسيط';

  @override
  String get settingsScopeNotice =>
      'يتغيّر نمط المحادثات الجديدة فقط. يمكنك قراءة المحادثات المحفوظة دون اتصال أو متابعتها لاحقاً.';

  @override
  String get claudeConnection => 'الاتصال بـ Claude';

  @override
  String get proxyDescription =>
      'اختياري. استخدم خادم HTTPS خاصاً بك يحفظ مفتاح API على الخادم ويمرّر واجهة Messages. في نمط المحادثة تُرسل الأسئلة والرسائل الأخيرة إلى هذا الخادم.';

  @override
  String get proxyMessagesUrl => 'رابط وسيط Messages';

  @override
  String get invalidProxyUrl => 'أدخل رابط وسيط HTTPS صالحاً';

  @override
  String get claudeModelId => 'معرّف نموذج Claude';

  @override
  String get modelIdRequired => 'أدخل معرّف النموذج';

  @override
  String get historyLimit => 'عدد الرسائل الأخيرة المرسلة (١–٥٠)';

  @override
  String get invalidHistoryLimit => 'اختر رقماً من ١ إلى ٥٠';

  @override
  String get saving => 'جارٍ الحفظ…';

  @override
  String get saveSettings => 'حفظ الإعدادات';

  @override
  String get appName => 'تبيان';

  @override
  String get archiveHeading => 'سؤالٌ يقودك إلى مصدر.\nومعرفةٌ تعود إليها.';

  @override
  String get archiveDescription =>
      'ابحث في النصوص الموثوقة، واحتفظ بما وجدته دون اتصال.';

  @override
  String get searchArchive => 'ابحث في المحفوظات';

  @override
  String get allSaved => 'جميع المحفوظات';

  @override
  String get pinned => 'المثبّتة';

  @override
  String get savedOffline => 'محفوظة · متاحة دون اتصال';

  @override
  String get logoSemantics => 'شعار تبيان';

  @override
  String get emptyArchiveTitle => 'هنا تحفظ رحلتك مع المعرفة';

  @override
  String get emptyArchiveDescription =>
      'ابدأ بسؤالك الأول، أو جرّب بحثاً آخر في المحفوظات.\nتبقى المحادثات المحفوظة متاحة للقراءة دون اتصال.';

  @override
  String get conversationActions => 'إجراءات المحادثة';

  @override
  String get deleteConversationTitle => 'حذف هذه المحادثة؟';

  @override
  String get deleteConversationDescription =>
      'سيؤدي هذا إلى حذف الرسائل والمصادر المحفوظة نهائياً.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get unpin => 'إلغاء التثبيت';

  @override
  String get pin => 'تثبيت';

  @override
  String get rename => 'إعادة التسمية';

  @override
  String get exportAsText => 'تصدير كنص';

  @override
  String get renameConversation => 'إعادة تسمية المحادثة';

  @override
  String get title => 'العنوان';

  @override
  String get save => 'حفظ';

  @override
  String get retrievalNotice =>
      'هذا التطبيق للبحث والاسترجاع، وليس مصدراً للفتوى. ارجع إلى أهل العلم المؤهلين.';

  @override
  String get appTitle => 'Tibyan · تبيان';

  @override
  String get arabicLanguage => 'العربية';

  @override
  String get englishLanguage => 'English';

  @override
  String get proxyUrlHint => 'https://YOUR-BACKEND.example/v1/messages';

  @override
  String get modelIdHint => 'معرّف النموذج الذي يدعمه الوسيط';

  @override
  String get localStorageOpenError =>
      'تعذّر فتح التخزين المحلي. أعد تشغيل التطبيق.';

  @override
  String get noLinkedSourcesFound =>
      'لم يُعثر على مصادر مرتبطة بهذا السؤال. جرّب كلمات بحث أخرى.';

  @override
  String get networkError => 'تعذّر الاتصال. تحقق من الإنترنت ثم أعد المحاولة.';

  @override
  String get requestTimeoutError => 'انتهت مهلة الطلب. يمكنك إعادة المحاولة.';

  @override
  String get sourceToolError => 'تعذّر استرجاع المصدر. أعد المحاولة.';

  @override
  String get noSearchToolError => 'لا توجد أداة بحث متوافقة في الخادم.';

  @override
  String get proxyConfigurationError =>
      'أضف رابط وسيط Claude واسم النموذج في الإعدادات.';

  @override
  String get modelError => 'تعذّر إكمال الرد. أعد المحاولة.';

  @override
  String get cancelledError => 'حُفظ السؤال دون رد مكتمل.';

  @override
  String get storageError => 'تعذّر حفظ البيانات. تحقق من مساحة الجهاز.';

  @override
  String get exportUserRole => 'المستخدم';

  @override
  String get exportAssistantRole => 'المساعد';

  @override
  String get exportToolRole => 'أداة المصدر';

  @override
  String get exportSentStatus => 'مُرسلة';

  @override
  String get exportFailedStatus => 'فشلت';

  @override
  String exportMessageHeader(String role, String status) {
    return '$role [$status]:';
  }

  @override
  String get continueConversation => 'متابعة المحادثة';

  @override
  String get savedConversation => 'المحادثة محفوظة';

  @override
  String get searchResults => 'نتائج البحث';
}
