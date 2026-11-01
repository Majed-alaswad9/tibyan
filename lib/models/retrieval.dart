import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart';

class SourceLink {
  const SourceLink(this.url, this.label);
  final String url;
  final String label;
}

class RetrievedBlock {
  const RetrievedBlock({
    required this.toolName,
    required this.rawText,
    required this.links,
  });
  final String toolName;
  final String rawText;
  final List<SourceLink> links;
}

class Retrieval {
  const Retrieval(this.payload, this.blocks, {this.isError = false});
  final Map<String, dynamic> payload;
  final List<RetrievedBlock> blocks;
  final bool isError;

  factory Retrieval.fromMcp(String toolName, CallToolResult result) {
    final blocks = <RetrievedBlock>[];
    final structuredLinks = <SourceLink>[];
    void visit(Object? value) {
      if (value is Map) {
        final url = value['url'] ?? value['sourceUrl'] ?? value['source_url'];
        if (url is String && isWebUrl(url)) {
          structuredLinks.add(
            SourceLink(
              url,
              (value['title'] ?? value['reference'] ?? url).toString(),
            ),
          );
        }
        for (final child in value.values) {
          visit(child);
        }
      } else if (value is List) {
        for (final child in value) {
          visit(child);
        }
      }
    }

    visit(result.structuredContent);
    for (final content in result.content.whereType<TextContent>()) {
      final raw = content.text;
      try {
        visit(jsonDecode(raw));
      } on FormatException {
        /* Plain text is expected too. */
      }
      final urls = <String>{
        for (final link in structuredLinks) link.url,
        ...RegExp(r'''https?://[^\s<>"\]\)]+''')
            .allMatches(raw)
            .map((m) => m.group(0)!),
      };
      blocks.add(
        RetrievedBlock(
          toolName: toolName,
          rawText: raw,
          links: [
            for (final url in urls.where(isWebUrl))
              structuredLinks.where((l) => l.url == url).firstOrNull ??
                  SourceLink(url, url),
          ],
        ),
      );
    }
    // Structured-only tools still need an exact, lossless representation in the archive.
    if (blocks.isEmpty && result.structuredContent != null) {
      blocks.add(
        RetrievedBlock(
          toolName: toolName,
          rawText: jsonEncode(result.structuredContent),
          links: structuredLinks,
        ),
      );
    }
    return Retrieval(result.toJson(), blocks, isError: result.isError);
  }
}

bool isWebUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty;
}

enum AppFailure {
  network,
  timeout,
  tool,
  noSearchTool,
  proxyConfiguration,
  model,
  cancelled,
  storage,
}
