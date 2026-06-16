# TrakIt

> Your AI money companion. Capture, understand and *feel* where your money goes.

TrakIt is a premium Flutter expense-tracker built around a **hybrid capture
pipeline** — screenshots, OCR, the Claude API, real camera, Gmail sync and
quick-add text — wrapped in an Apple-grade glassmorphism UI.

## Real, not stubbed

| Surface | Implementation |
|---|---|
| Screenshot capture | `image_picker` from gallery → `google_mlkit_text_recognition` on-device OCR → Claude Haiku 4.5 parser |
| Quick add | Live AI parse as you type, debounced by sequence number |
| Receipt camera | `camera` plugin with live `CameraPreview` behind a custom glass viewfinder; system-camera fallback via `image_picker` |
| Gmail sync | Progress-stream UI + transaction harvest (OAuth wiring left as a TODO — see `lib/data/services/gmail_sync_service.dart`) |
| AI parsing | **Claude Haiku 4.5** via raw HTTP (no Dart SDK). Prompt-cached system block, structured outputs via `output_config.format`. Falls back to a hardened rule-based parser when no API key is set. |
| Insights | Local rule engine over real transaction history (week-over-week deltas, late-night ordering, subscription totals, weekend share) |
| Persistence | `shared_preferences` behind a `StorageService` swappable for Isar/Hive |
| App icon | Generated programmatically from `tool/gen_icon.dart`, fanned out by `flutter_launcher_icons` |

## Quick start

```bash
cd trakit
./scripts/setup.sh

# with the Claude API (recommended):
flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...

# without — the rule-based parser handles capture
flutter run
```

`scripts/setup.sh` is idempotent and does five things:

1. `flutter create .` to scaffold `android/`, `ios/`, `web/`
2. Patches `AndroidManifest.xml` and `Info.plist` with the camera + photo
   permissions the plugins need
3. `flutter pub get`
4. Generates `assets/icons/app_icon.png` from the Dart source in `tool/`
5. Runs `flutter_launcher_icons` to materialise platform-specific variants

## Architecture

```
lib/
  main.dart                 entrypoint, ProviderScope + StorageService init
  app.dart                  MaterialApp.router, theme wiring

  core/
    theme/                  AppColors, AppGradients, AppTextStyles, AppTheme
    router/                 go_router shell + capture stack
    utils/                  Money / Dates formatters
    extensions/             BuildContext sugar

  data/
    models/                 ExpenseTxn, ExpenseCategory, Insight
    services/
      claude_service.dart   raw HTTP to /v1/messages, Haiku 4.5, prompt-cached
      ai_parser_service.dart  Claude-first w/ rule fallback
      ocr_service.dart      Google ML Kit, falls back to canned blobs off-mobile
      gmail_sync_service.dart  progress stream + harvest stub
      insight_engine.dart   narrative generation from raw transactions
      storage_service.dart  SharedPreferences-backed CRUD
    repositories/           TransactionRepository
    providers/              Riverpod + derived selectors
    mock/                   DummyData generator (weekend / late-night biased)

  features/                 splash · onboarding · home · timeline · insights
                            · add_expense · scanner (screenshot/receipt/gmail)
                            · detail · settings
  widgets/                  glass card, gradient button, aurora bg, charts, …

tool/
  gen_icon.dart             draws app_icon.png + adaptive foreground

test/
  ai_parser_service_test.dart    rule-parser correctness (amount picking, etc.)
  claude_service_test.dart       HTTP shape: headers, model, cache_control, schema
  insight_engine_test.dart       insight generation invariants
  dummy_data_test.dart           determinism + sort order
  formatters_test.dart           ₹ formatting + relative dates
  storage_service_test.dart      JSON round-trip + malformed-blob recovery
```

## Why Claude Haiku 4.5?

For an OCR-blob → structured-JSON task, Haiku 4.5 is the right tool:

- **Cheapest current Claude** — $1.00 / $5.00 per 1M tokens (input / output).
  A typical receipt parse is ~1.5K tokens in + 80 tokens out, well under
  $0.002 per call.
- **Structured outputs supported** — we constrain Claude with a JSON schema
  (`output_config.format.json_schema`) that enforces the response shape.
- **Prompt caching** — the system prompt is intentionally large (3-4K
  tokens of taxonomy, examples, formatting rules) so it crosses Haiku's
  4096-token cacheable-prefix threshold. After the first call, cache reads
  cost ~10% of fresh input.
- **Adaptive thinking is unnecessary** — extraction doesn't need reasoning;
  the schema does the heavy lifting.

To upgrade to richer narrative insights, swap `_model` in
`claude_service.dart` to `claude-sonnet-4-6` (Sonnet caches at 2048 tokens
and produces better long-form reasoning). The call shape is identical.

The API key is compile-time-injected via `--dart-define=ANTHROPIC_API_KEY=...`.
When absent, `ClaudeService.isConfigured` returns `false` and every parse
falls through to a deterministic rule engine that's stable but lossier.

## Tests + CI

```bash
flutter test
```

Tests cover the pure-Dart logic — parser, insight engine, dummy data,
formatters, storage round-trip, and the Claude HTTP request shape
(injected `MockClient`, no network). CI runs analyse + test + APK build on
every push to the working branch — see `.github/workflows/trakit-ci.yml`.

## Monetisation hooks

`pubspec.yaml` is shaped for `google_mobile_ads` and `purchases_flutter`
(commented out to keep the scaffold buildable without native config).
Uncomment + follow each plugin's platform setup when ready to ship.

## Design language

- **Palette.** Plum night-sky (`#0B0613`) + violet brand (`#B084FF`) + peach
  sunrise accent (`#FFB37C`).
- **Type.** Plus Jakarta Sans with tabular figures on currency.
- **Motion.** Aurora background drifts on a 14s loop; FAB pulses; every
  screen staggers in; haptics on capture.
- **Glass.** `GlassCard` is the workhorse — 16px backdrop blur, 6% white
  tint, 1px inner stroke. Light mode trades blur for a tinted card.

## Roadmap

- Real Gmail OAuth + email regex pipeline (`googleapis` + `google_sign_in`)
- Firebase auth + cloud sync
- Budget envelopes (storage key `monthlyBudget` reserved)
- Bank statement PDF ingestion
- Family / shared expenses

---

Built with care. Designed to be lived with, not endured.
