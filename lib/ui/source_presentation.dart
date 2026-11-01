import 'dart:convert';

import 'package:tibyan/data/database.dart';

class SourceExcerpt {
  const SourceExcerpt({
    required this.source,
    required this.text,
    required this.isQuran,
    this.notes = '',
  });
  final MessageSource source;
  final String text;
  final bool isQuran;
  final String notes;
}

/// Presentation only: the stored source text is never changed.
class SourcePresentation {
  static final _resultHeader = RegExp(
    r'^\d+\. \[(quran|hadith|library)\] [^\r\n]*\r?\n',
    multiLine: true,
  );
  static final _urlLine = RegExp(
    r'^[ \t]*(https?://\S+)[ \t]*\r?\n',
    multiLine: true,
  );
  static final _searchStatus = RegExp(
    r'^(?:quran|hadith|library): (?:\d+ of \d+|unavailable\b)',
    multiLine: true,
  );

  SourcePresentation(List<StoredMessage> messages) {
    final links = <String, MessageSource>{};
    for (final item in messages) {
      for (final source in item.sources) {
        links.putIfAbsent(source.sourceUrl, () => source);
      }
    }
    for (final item in messages) {
      final raw = item.message.content;
      try {
        final json = jsonDecode(raw);
        if (json is Map && json['text'] is String) {
          final source = links[json['url']];
          _addText(
            json['text'] as String,
            source == null ? links : {source.sourceUrl: source},
          );
        }
        // JSON indexes are represented by their source titles and links below.
      } on FormatException {
        final citationInstructions = RegExp(
          r'^─+ CITE ─+\s*$',
          multiLine: true,
        ).firstMatch(raw);
        final text = citationInstructions == null
            ? raw
            : raw.substring(0, citationInstructions.start);
        if (text.trim().isNotEmpty) _addText(text, links);
      }
    }
    sources = links.values.toList();
    final shown = excerpts.map((excerpt) => excerpt.source.sourceUrl).toSet();
    remainingSources = sources
        .where((source) => !shown.contains(source.sourceUrl))
        .toList();
  }
  final List<String> texts = [];
  final List<SourceExcerpt> excerpts = [];
  late final List<MessageSource> sources;
  late final List<MessageSource> remainingSources;

  void _addText(String text, Map<String, MessageSource> links) {
    if (_splitSearchResults(text, links)) return;
    final source = links.length == 1 ? links.values.single : null;
    if (source != null &&
        !_resultHeader.hasMatch(text) &&
        _isQuranSource(source)) {
      excerpts.add(SourceExcerpt(source: source, text: text, isQuran: true));
    } else {
      texts.add(text);
    }
  }

  bool _splitSearchResults(String text, Map<String, MessageSource> links) {
    final headers = _resultHeader.allMatches(text).toList();
    if (headers.isEmpty) return false;
    final parsed = <SourceExcerpt>[];
    String? summary;
    for (var i = 0; i < headers.length; i++) {
      final header = headers[i];
      final end = i + 1 < headers.length ? headers[i + 1].start : text.length;
      final section = text.substring(header.end, end);
      final urlLine = _urlLine.firstMatch(section);
      if (urlLine == null) return false;
      final source = links[urlLine.group(1)];
      if (source == null) return false;
      var body = section.substring(urlLine.end);
      if (i == headers.length - 1) {
        final status = _searchStatus.firstMatch(body);
        if (status != null) {
          summary = body.substring(status.start);
          body = body.substring(0, status.start);
        }
      }
      parsed.add(
        SourceExcerpt(
          source: source,
          text: body,
          isQuran: header.group(1) == 'quran',
          notes: section.substring(0, urlLine.start),
        ),
      );
    }
    final introduction = text.substring(0, headers.first.start);
    if (introduction.trim().isNotEmpty) texts.add(introduction);
    excerpts.addAll(parsed);
    if (summary != null) texts.add(summary);
    return true;
  }

  bool _isQuranSource(MessageSource source) =>
      source.toolName.startsWith('get_quran') ||
      RegExp(r'/quran/\d+(?:/|$)')
          .hasMatch(Uri.tryParse(source.sourceUrl)?.path ?? '');
}

class MessageEntry {
  MessageEntry(this.item, {this.source});
  final StoredMessage item;
  final SourcePresentation? source;

  static List<MessageEntry> group(List<StoredMessage> messages) {
    final entries = <MessageEntry>[];
    var index = 0;
    while (index < messages.length) {
      final item = messages[index];
      if (item.message.role != 'tool') {
        entries.add(MessageEntry(item));
        index++;
        continue;
      }
      final group = <StoredMessage>[];
      while (index < messages.length &&
          messages[index].message.role == 'tool') {
        group.add(messages[index++]);
      }
      entries.add(MessageEntry(item, source: SourcePresentation(group)));
    }
    return entries;
  }
}
