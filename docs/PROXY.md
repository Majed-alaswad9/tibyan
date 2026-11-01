# Claude proxy contract

The app calls the **full URL** configured in Settings. It is a placeholder until
you deploy your own backend. No Anthropic secret belongs in a mobile binary.

Request:

```http
POST https://YOUR-BACKEND.example/v1/messages
Content-Type: application/json
anthropic-version: 2023-06-01
```

```json
{
  "model": "YOUR-PROXY-SUPPORTED-MODEL",
  "max_tokens": 2048,
  "system": "The grounding and no-fatwa system prompt from LlmService",
  "messages": [{"role": "user", "content": "The current question"}],
  "tools": [{"name": "discovered_name", "description": "Discovered description", "input_schema": {"type": "object", "properties": {}}}],
  "tool_choice": {"type": "any"}
}
```

Later rounds use `tool_choice: {"type":"auto"}` and append the assistant's
`tool_use` blocks and a user message containing matching `tool_result` blocks.
Return the normal, non-streaming Claude Messages JSON response, including
`content` and `stop_reason`; forward non-success responses as non-2xx HTTP status.
The app applies a 60-second model timeout. Configure your upstream accordingly.

The proxy must inject its server-side API key and use the compatible Anthropic
API version. Apply your own access controls and usage limits before making it
public; a mobile app without a user authentication flow cannot protect an open
billable endpoint. If your backend uses authenticated user sessions, extend
`LlmService` with that app-specific authentication, without embedding a shared
secret. Do not blindly forward arbitrary destinations, model IDs or unbounded
request sizes to a billable upstream. No proxy deployment, authentication system,
cloud account, paid request, or key creation is included in this mobile project.

Authoritative contracts:
[Messages API](https://platform.claude.com/docs/en/api/messages),
[tool-use definitions](https://platform.claude.com/docs/en/agents-and-tools/tool-use/define-tools).
