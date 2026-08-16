# Flow Personal Finance Tracker

Flow is an offline-first Flutter app for simple personal money tracking. It focuses on fast mobile entry, local SQLite persistence, clear transaction history, and compact spending insights without login or cloud dependencies.

## Features

- First-use setup with default currency and first account creation.
- Account management for Cash, Bank, E-wallet, and Other.
- Income, expense, and transfer transactions with positive stored amounts.
- Correct balance rules: opening balance plus income, minus expense, plus incoming transfers, minus outgoing transfers.
- Home summary with total balance visibility toggle, monthly income/expense, cash-flow chart, category spending, and recent transactions.
- Transactions search and filter modal for type, account, category, and date range.
- Statistics with daily, weekly, and monthly ApexCharts trends plus spending by category.
- Settings for Light/Dark theme, currency, categories, CSV export, and delete-all-data.
- Archived account view with restore action.

## Architecture

- `lib/main.dart` opens `SqliteFlowStore` and falls back to `MemoryFlowStore` when SQLite is unavailable.
- `lib/app.dart` owns app routing and shell navigation; global data is read from Riverpod providers.
- `lib/state/` contains `FlowState`, `FlowController`, and provider selectors.
- `lib/data/` contains models, SQLite repositories, balance logic, filters, seeding, and CSV export.
- `lib/components/` contains reusable Flow UI primitives.
- `lib/theme/` contains design tokens, typography, colors, and theme setup.
- `lib/screens/` contains presentational screens; form, filter, chart-period, and navigation state stays local.

## Setup

```powershell
flutter pub get
flutter run
```

For Android debug builds:

```powershell
flutter build apk --debug
```

## Validation

```powershell
flutter analyze
flutter test --concurrency=1
flutter build apk --debug
```

`flutter test --concurrency=1` is preferred because this project has layout and surface-size widget tests.

## Product Boundaries

Flow intentionally stays offline-first and lightweight. Do not add login, cloud sync, bank/e-wallet integrations, OCR, AI, investment tracking, or payment-gateway behavior unless explicitly requested.
