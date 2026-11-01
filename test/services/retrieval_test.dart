import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:tibyan/models/retrieval.dart';

void main() {
  test(
    'raw source text is never normalized and canonical URLs are retained',
    () {
      const raw = '  مصدر\n\nhttps://example.org/source?q=one&lang=ar  ';
      final result = Retrieval.fromMcp(
        'tool',
        const CallToolResult(
          content: [TextContent(text: raw)],
          structuredContent: {
            'results': [
              {
                'title': 'مرجع',
                'url': 'https://example.org/source?q=one&lang=ar',
              },
            ],
          },
        ),
      );
      expect(result.blocks.single.rawText, raw);
      expect(
        result.blocks.single.links.single.url,
        'https://example.org/source?q=one&lang=ar',
      );
      expect(result.blocks.single.links.single.label, 'مرجع');
    },
  );
  test('only HTTP(S) source links are launchable', () {
    expect(isWebUrl('javascript:alert(1)'), isFalse);
    expect(isWebUrl('file:///etc/passwd'), isFalse);
    expect(isWebUrl('https://example.org/path'), isTrue);
  });
}
