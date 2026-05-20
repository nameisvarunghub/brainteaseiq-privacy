# TrakIt

> Your AI money companion. Capture, understand and *feel* where your money goes.

TrakIt is a premium expense-tracking app built in Flutter. It does **not** rely
on bank sync alone — instead, it uses a hybrid capture pipeline that's fast,
private and emotionally engaging.

## Why it feels different

- **Screenshot scanner first.** Drop a PhonePe / GPay / Swiggy / Amazon
  screenshot — the OCR + AI parser extracts amount, merchant, category and
  payment mode in seconds.
- **Quick add that reads English.** Type `₹350 Zomato` and you're done — no
  forms, no dropdowns.
- **Gmail sync, optional.** Connect Gmail to auto-import transaction emails.
- **Camera receipts.** Snap a bill, get a clean expense.
- **AI insights, narrated.** "You're spending 42% more on food this week" —
  "Subscriptions total ₹2,400/month" — "Your late-night ordering increased."

The visual language draws from Apple Health, CRED and Notion: glassmorphism,
aurora gradients, vivid category pills, premium type. Spreadsheet vibes are
banned.

## Getting started

```bash
cd trakit

# add platform folders (the scaffold ships lib/ only)
flutter create . --platforms=ios,android,web --org com.trakit --project-name trakit

flutter pub get
flutter run
```

The app boots into a splash → onboarding (first run only) → home flow. Demo
transactions seed automatically so the UI is alive on first launch.

## Architecture

```
lib/
  main.dart                 entrypoint, sets up ProviderScope + storage
  app.dart                  MaterialApp.router, theme wiring

  core/
    theme/                  AppColors, AppGradients, AppTextStyles, AppTheme
    router/                 GoRouter config (shell tabs + capture stack)
    utils/                  Money / Dates formatters
    extensions/             BuildContext sugar

  data/
    models/                 ExpenseTxn, ExpenseCategory, Insight
    services/               OcrService, AiParserService, GmailSyncService,
                            InsightEngine, StorageService
    repositories/           TransactionRepository
    providers/              Riverpod providers + derived selectors
    mock/                   DummyData generator (weekend / late-night biased)

  features/
    splash/                 animated logo intro
    onboarding/             3-page swipe, glass cards, gradient CTA
    home/                   hero card, category strip, AI insight, recents
    timeline/               filterable, grouped social-feed of expenses
    insights/               donut + narrative cards
    add_expense/            capture-method picker + quick add
    scanner/                screenshot, receipt camera, gmail sync flows
    detail/                 transaction detail
    settings/               theme, capture, data, about

  widgets/
    cards/glass_card.dart           blurred frosted surface
    buttons/gradient_button.dart    scale-on-press CTA
    animations/animated_counter.dart tabular-figure currency tween
    common/category_pill.dart       gradient pill w/ emoji & amount
    common/transaction_tile.dart    feed row with source chip
    common/aurora_background.dart   animated orb gradient backdrop
    charts/spend_sparkline.dart     7-day fl_chart line
    charts/category_donut.dart      animated PieChart center label
```

State management is **Riverpod 2** (`StateNotifier` + derived `Provider`s).
Persistence uses `shared_preferences` — swap `StorageService` for Isar/Hive
when you outgrow it; the API is shaped for a one-line replacement.

## Capture pipeline

The services are **placeholders that match production shape**:

- `OcrService.recognizeFromImagePath` — wire `google_mlkit_text_recognition`
  on device. The stub returns realistic sample blobs so the UI flows end to
  end without native config.
- `AiParserService.parseQuickAdd` / `parseOcrText` — rule-based extraction
  for amount/merchant/category/payment. Drop in a small LLM (Gemma 2B int4
  on-device or a Claude endpoint) without changing call sites.
- `GmailSyncService.scan` — emits a fake progress stream. Wire
  `googleapis` + `google_sign_in` with `gmail.readonly`.
- `InsightEngine.generate` — produces 5-7 narrative insights deterministically
  from real data (week-over-week deltas, late-night ordering, subscription
  totals, weekend share, streaks).

## Monetisation-ready

`pubspec.yaml` is shaped for AdMob (`google_mobile_ads`) and RevenueCat
(`purchases_flutter`) — kept commented to keep the scaffold buildable with
zero native config. Uncomment + run the platform setup steps when you're
ready to ship.

## Design language

- **Palette.** Plum night-sky (`#0B0613`) + violet brand (`#B084FF`) + peach
  sunrise accent (`#FFB37C`). Light mode is a warm lilac.
- **Type.** Plus Jakarta Sans, variable-axis tight tracking on large display
  sizes, tabular figures for currency.
- **Motion.** Every screen transitions in with stagger; the FAB pulses; the
  aurora background drifts on a 14s loop; touches haptic-tap.
- **Glass.** `GlassCard` is the workhorse surface — backdrop blur 16px,
  6% white tint, 1px inner stroke. Light mode trades blur for a tinted
  card with soft shadow.

## Roadmap hooks

- Firebase auth + cloud sync (commented in `pubspec.yaml`).
- Real ML Kit + Tesseract OCR.
- Budget envelope feature (storage key reserved: `monthlyBudget`).
- Bank statement PDF ingestion.
- Family / shared expenses.

---

Built with care. Designed to be lived with, not endured.
