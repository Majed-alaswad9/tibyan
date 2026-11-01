import 'package:flutter/material.dart';
import 'package:tibyan/ui/common.dart';
import 'package:tibyan/ui/source_presentation.dart';

class SourceExcerptCard extends StatelessWidget {
  const SourceExcerptCard({super.key, required this.excerpt});
  final SourceExcerpt excerpt;

  // Font metrics leave room for Quranic marks; forced struts can clip them.
  static const _quranStyle = TextStyle(
    fontFamily: 'AmiriQuran',
    fontFamilyFallback: ['Cairo'],
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    wordSpacing: 0,
    height: kTextHeightNone,
  );
  static const _textStyle = TextStyle(
    fontSize: 16,
    height: 1.9,
    letterSpacing: 0,
  );

  @override
  Widget build(BuildContext context) {
    final direction = contentDirection(excerpt.text);
    final quranArabic = excerpt.isQuran && direction == TextDirection.rtl;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            excerpt.source.referenceLabel,
            textDirection: contentDirection(excerpt.source.referenceLabel),
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(letterSpacing: 0),
          ),
          const SizedBox(height: 12),
          if (excerpt.notes.trim().isNotEmpty)
            Text(
              excerpt.notes.trim(),
              textDirection: contentDirection(excerpt.notes),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          SelectableText(
            excerpt.text.trim(),
            textDirection: direction,
            textAlign: quranArabic ? TextAlign.right : TextAlign.start,
            style: quranArabic ? _quranStyle : _textStyle,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => openSource(context, excerpt.source.sourceUrl),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(context.l10n.viewSource),
          ),
          const SizedBox(height: 4),
          Text(
            excerpt.source.sourceUrl,
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }
}
