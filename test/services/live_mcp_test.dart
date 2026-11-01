import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/data/mcp_client_service.dart';

void main() {
  test(
    'live MCP discovers tools and retrieves linked source text',
    () async {
      final service = McpClientService();
      addTearDown(service.close);
      final tools = await service.listTools();
      final search = SearchTool.discover(tools);
      final result = await service.callTool(
        search.tool.name,
        search.arguments('الصبر', 'ar'),
      );
      expect(result.isError, isFalse);
      expect(result.blocks.any((b) => b.links.isNotEmpty), isTrue);
      expect(result.blocks.any((b) => b.rawText.isNotEmpty), isTrue);
    },
    skip: !const bool.fromEnvironment('LIVE_MCP'),
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
