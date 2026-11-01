# Tibyan · تبيان

An Android/iOS Flutter app for Islamic source retrieval, with Arabic/English UI,
RTL, bundled Cairo fonts, dark mode, and locally saved conversations that can be read offline or explicitly continued.
Direct search is the default and needs no account, API key, or LLM.

## Run

```sh
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter run
```

The generated Drift code is included. Regenerate it after changing database tables.
Use the Dart/Flutter SDK compatible with `sdk: ^3.13.0` in `pubspec.yaml`.

```sh
flutter analyze
flutter test
flutter test --dart-define=LIVE_MCP=true test/services/live_mcp_test.dart
flutter build apk --debug
flutter build ios --simulator
```

The live test uses the public MCP server; the normal suite is offline. iOS builds
require Xcode. Device installation/release distribution requires your own Apple
signing team and Android release keystore. The Android template still uses debug
signing for release builds; configure real signing before publishing.

## Use

- Tap **New question**. Send a question to retrieve exact source text and links.
  Keep sending follow-up questions in the same composer. Direct search executes
  each query independently; Claude mode uses recent history for contextual answers.
- A question is stored before the network request. Failed/incomplete questions stay
  stored; **Retry** reuses the last failed message without duplicating it.
- Leaving a conversation, backgrounding the app, or five minutes of inactivity
  ends the conversation and closes its MCP transport. A response arriving later
  cannot change the saved conversation, including after continuation. On process restart, any active records are archived.
- Opening a saved conversation only reads SQLite. Tap **Continue conversation**
  to open its composer; the next send resumes the same stored conversation and
  initializes a fresh MCP transport lazily. No network is used until a send.
  Source links open externally and require a connection when visited.
- **Copy question** opens a brand-new draft; it does not send automatically.
- Search titles and message text, filter pinned entries, rename, delete, or share
  an export as text. Entries remain sorted newest first, grouped by day.
- Settings change language, appearance, mode, proxy endpoint/model, and the number
  of recent messages included in model history. Changes apply to new conversations.

The visible notice remains on every main screen: this app retrieves sources and
is not a source of fatwa. No religious answers, sources, or demo conversations are
fabricated or seeded locally.

## Claude mode

In **Settings**, select Chat and configure:

1. The full HTTPS URL of your own Messages API proxy, e.g.
   `https://YOUR-BACKEND.example/v1/messages` (placeholder only).
2. A Claude model ID supported by that proxy.
3. The recent-message history limit, 1–50 (default 12).

No API key is stored in the app, supplied through build flags, or sent by the
client. The proxy must keep the Anthropic API key on the server and forward the
Messages JSON contract. See [docs/PROXY.md](docs/PROXY.md) for the exact contract.
A deployed proxy/account is intentionally not bundled. Chat cannot work until you
supply one. Direct search is fully usable independently.

`LlmProvider` is the provider boundary; `LlmService` implements Claude Messages.
The model receives dynamically discovered tool schemas. It must retrieve evidence
for each question and return tool calls; the app executes those calls and feeds
back `tool_result` blocks. There are at most six model rounds and twelve tool
calls per turn. Only recent stored messages from the current conversation are
included; the in-flight tool-use protocol exchange is added to that history.
Older archives are never sent. Raw tool results are stored and displayed apart
from the assistant's wording. A model reply without any retrieved linked source
is replaced with an explicit no-results message. Final answers must include a
retrieved URL; invented citation URLs are rejected as a failed turn.

The system prompt prohibits invented verses, hadith, gradings, URLs, and fatwas;
it requires exact sacred quotations, attribution and links, and referral to
qualified scholars for ijtihad. These instructions cannot mathematically guarantee
model correctness: the separate verbatim cards let users inspect the evidence.

Replies are shown after completion rather than token streaming. The UI shows a
retrieval indicator while working; only a complete turn commits to the archive.

## Code map

```text
lib/
  main.dart                         Bootstrap, dependencies, themes and locale
  l10n/
    app_en.arb / app_ar.arb          All app-authored user-facing messages
    app_localizations*.dart         Flutter-generated localizations
    localization.dart               Context getter and localized errors
  models/
    settings.dart                   Immutable configuration
    retrieval.dart                  Exact tool text, canonical links, errors
  data/
    database.dart / database.g.dart  Drift tables and ConversationDao
    conversation_repository.dart    Single source of truth for stored data
    mcp_client_service.dart         MCP session and Streamable HTTP ownership
    llm_service.dart                LlmProvider and Claude proxy implementation
    network_client.dart             Dio configuration and debug metadata interceptor
    chat_repository.dart            Save → retrieve/tool loop → atomic reply
  ui/
    view_models.dart                Provider/ChangeNotifier view models
    archive_screen.dart             Search, grouping, pin/rename/delete/export
    chat_screen.dart                Active and saved conversations with explicit continuation
    settings_screen.dart            Validated configuration form
    common.dart                     Notice, frame and external source links
assets/
  fonts/                            Existing Cairo font files
  images/logo.png                   Existing Tibyan branding
```

Provider was chosen because this app needs a small dependency graph and focused
ChangeNotifier view models, while Drift already provides reactive stored state.
A second reactive store would duplicate SQLite data. `Selector` limits changes
to the archive list, filter, message stream, or request status. Form controllers
are created once and disposed; local saving state uses `ValueNotifier`. No app
code calls `setState`. Streams/futures are created outside `build`, and static
subtrees use const widgets. Business and transport logic stay outside widgets.

The original counter used `setState` for one integer; that was appropriate for a
counter. It had no repositories, resources or domain behavior to preserve. This
is a replacement app, not a behavior-preserving counter refactor. Provider is
justified here by the explicit app specification; a purely local counter would
not need it.

## Storage and session guarantees

Drift tables: `conversations`, `messages`, `message_sources`, `app_settings`.
Foreign keys cascade messages/sources on deletion. Conversation/message states
are checked by SQLite. Message/source indexes serve the joined message stream.
The archive searches stored message bodies (including raw source text).

The question starts with status `failed` until its complete reply transaction
commits, using the specified two-state schema. During a live request the typing
indicator identifies it as in flight. This avoids losing incomplete questions
on process death. Saved conversations reject new questions and replies until explicitly resumed.
Rename, pin, delete, and continuation are intentional archive-management operations.

MCP initializes lazily on the first send, negotiates the verified server's
`2025-06-18` protocol, and dynamically discovers every tool/schema, including
pagination. Direct search selects a search-capable tool with a compatible string
query field from the discovered schema. Unsupported schemas produce a clear
error instead of guessed arguments. Tools with an explicit non-read-only hint
are excluded. `mcp_dart 2.4.3` already handles a session-bearing HTTP 404 by
initializing without the stale session ID and retrying the same request once;
Tibyan deliberately adds no second retry. Local server tests cover both recovery
and a second 404. Transport IDs, resumption IDs and session data never enter the
database or configuration.

Raw returned text blocks are stored without trimming, reformatting or changing
sacred wording. Structured-only results are losslessly JSON-serialized; source
URLs are taken from results, never assembled from IDs. The presentation groups
consecutive tool blocks per turn, shows readable source wording, and lists each
source link once. JSON indexes and the server's CITE instructions are not shown
in the conversation UI. The raw-response expander was removed: it was unnecessary
for reading and its PageStorage key collided with nested SelectableText scroll
state (a stored bool was read as a double). Full raw blocks remain unchanged in
storage and text exports, including older archives.

## Dependencies

Versions below were resolved from pub.dev for this implementation; the exact
transitive dependency graph is in `pubspec.lock`. Flutter/Flutter localizations
and flutter_test are SDK packages.

| Package | Version | Purpose |
| --- | --- | --- |
| [provider](https://pub.dev/packages/provider) | 6.1.5+1 | View models and dependency ownership |
| [drift](https://pub.dev/packages/drift) | 2.35.3 | Reactive relational storage |
| [drift_flutter](https://pub.dev/packages/drift_flutter) | 0.3.1 | Native database setup |
| [mcp_dart](https://pub.dev/packages/mcp_dart) | 2.4.3 | MCP initialization, tools and transport |
| [dio](https://pub.dev/packages/dio) | 5.11.1 | Claude HTTP, timeouts, cancellation and interceptors |
| [http](https://pub.dev/packages/http) | 1.6.0 | MCP SDK HTTP exception handling |
| [url_launcher](https://pub.dev/packages/url_launcher) | 6.3.3 | Source links |
| [share_plus](https://pub.dev/packages/share_plus) | 13.3.1 | Text export/share sheet |
| [intl](https://pub.dev/packages/intl) | 0.20.3 | Localized archive dates |
| [drift_dev](https://pub.dev/packages/drift_dev) | 2.35.2 | Database generation (dev) |
| [build_runner](https://pub.dev/packages/build_runner) | 2.17.1 | Code generation (dev) |
| [flutter_lints](https://pub.dev/packages/flutter_lints) | 6.0.0 | Static checks (dev) |

## Platform setup and future web support

Android has the main-manifest INTERNET permission. All production endpoints are
HTTPS. iOS uses standard HTTPS networking without ATS exceptions. URLs are opened
directly with `launchUrl`, so scheme-query whitelists are unnecessary. iPad export
passes a share-sheet anchor rectangle.

This delivery targets Android and iOS. The application layer uses portable Dart,
`dio`, `mcp_dart`, and `drift_flutter`; native SQLite appears only in tests. Web is not yet a
target. When adding it, generate Flutter web support, obtain **version-matched**
`sqlite3.wasm` and `drift_worker.js` following the
[official Drift web setup](https://drift.simonbinder.eu/platforms/web/), put them in
`web/`, and pass their URIs through `DriftWebOptions` in `AppDatabase`. Configure
WASM MIME type, worker deployment, and the server headers described there. Confirm
CORS support on both MCP and your proxy before claiming browser support. No unused
web binaries are added to the mobile app.

## Official references and design decisions

- [Flutter offline-first architecture](https://docs.flutter.dev/app-architecture/design-patterns/offline-first): repositories own stored data; views do not perform networking.
- [Flutter architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations): services/repositories and view/view-model separation, dependency injection, and independent tests.
- [Flutter simple app state management](https://docs.flutter.dev/data-and-backend/state-mgmt/simple): Provider and ChangeNotifier for shared application state.
- [Flutter performance guidance](https://docs.flutter.dev/perf/best-practices): small widgets, const subtrees, avoiding expensive build work, and limiting rebuild scope.
- [ValueListenableBuilder](https://api.flutter.dev/flutter/widgets/ValueListenableBuilder-class.html): narrow local state updates without rebuilding a whole screen.
- [Drift getting started](https://drift.simonbinder.eu/getting-started/) and [drift_flutter](https://pub.dev/packages/drift_flutter): generated schema, reactive queries, platform database setup.
- [mcp_dart API](https://pub.dev/documentation/mcp_dart/latest/): verified client and Streamable HTTP APIs.
- [MCP transport specification](https://modelcontextprotocol.io/specification/2025-06-18/basic/transports): transport sessions, termination, and session-404 recovery.
- [Claude Messages](https://platform.claude.com/docs/en/api/messages) and [tool definitions](https://platform.claude.com/docs/en/agents-and-tools/tool-use/define-tools): proxy request shape, discovered tool schemas and tool-result exchange.

## Localization

Uses Flutter's `flutter_localizations` and `gen-l10n` workflow, configured in
`l10n.yaml` with `flutter.generate: true`. Edit `lib/l10n/app_en.arb` and
`lib/l10n/app_ar.arb`, then run `flutter gen-l10n` (also runs with normal Flutter
builds). Both bootstrap and the main app use generated delegates and supported
locales. UI strings, accessibility labels, validation, errors, app-generated
empty-result replies, and export role/status labels all come from ARBs. The
settings language drives the UI and RTL; export labels use the current language,
while empty-result replies use the conversation's language. Already saved text,
user questions, model output, and verbatim sources are never translated or
rewritten. Technical protocol values, diagnostics and model instructions remain
internal strings.

See [Flutter internationalization](https://docs.flutter.dev/ui/internationalization)
for the official ARB and generated-localization workflow.

## HTTP and debug logging

Claude proxy requests use Dio 5.11.1 with connection, send and receive timeouts,
a 60-second overall deadline, and cancellation of an expired request. The service
owns its Dio instance and closes it on disposal. HTTP errors and timeout types map
to localized application failures; failed requests preserve the saved question.
No automatic retries are added to potentially billable Claude calls.

`NetworkLogInterceptor` prints method, origin, status, duration and error type only
in debug mode. It does not print URL paths/queries/credentials, request or response
bodies, headers, API keys, or MCP session IDs. Logs do not modify outgoing requests.

`mcp_dart 2.4.3` creates its own `http.Client` internally and has no Dio injection
point. Its Streamable HTTP/SSE transport stays intact to preserve protocol/session
recovery. `McpClientService` adds debug operation names, durations, and error types
without logging questions, results or session IDs. See the
[Dio interceptor documentation](https://pub.dev/packages/dio#interceptors) for the
supported hook lifecycle.

## Quran display

Search results with recognized source markers and matching stored canonical URLs
are separated into excerpts. Quran, hadith and library content no longer share
one mixed-direction paragraph. Quranic Arabic uses the bundled **Amiri Quran**
font, 24sp, RTL, zero letter/word spacing, and the font's own line metrics so
Quranic marks have room. The monochrome font inherits theme colors in dark mode.
Titles, matching notes and LTR source links remain separate from the verse.
Outer whitespace from the server's list formatting is trimmed only when rendered;
all verse characters, combining marks, internal whitespace and raw database/export
content are retained. Unrecognized result layouts fall back to the original text
rather than guessing source associations. Existing saved conversations use the
same rendering without a migration or network request.

Font: [official Amiri repository](https://github.com/aliftype/amiri),
`fonts/AmiriQuran.ttf` (monochrome), SIL OFL 1.1. Its license is bundled at
`assets/fonts/OFL-Amiri.txt` and registered with Flutter's license registry.
Downloaded asset SHA-256:
`8fa95faaf7bd18b71789f6f57312003e30c5029218a035e5baf613a0222ab82d`.
See Flutter's [font fallback](https://api.flutter.dev/flutter/painting/TextStyle/fontFamilyFallback.html)
and [line-height documentation](https://api.flutter.dev/flutter/painting/TextStyle/height.html).
