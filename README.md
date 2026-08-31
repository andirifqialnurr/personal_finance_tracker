# Flow Personal Finance Tracker

Flow is an offline-first Flutter app for simple personal money tracking. It focuses on fast mobile entry, local SQLite persistence, clear transaction history, and compact spending insights without login or cloud dependencies.

## Features

- First-use setup with default currency and first account creation.
- Account management for Cash, Bank, E-wallet, and Other.
- Income, expense, and transfer transactions with positive stored amounts.
- Correct balance rules: opening balance plus income, minus expense, plus incoming transfers, minus outgoing transfers.
- Home summary with total balance visibility toggle, monthly income/expense, cash-flow chart, category spending, recent transactions, and quick access to planning and reports.
- Transactions search and filter modal for type, account, category, and date range.
- Statistics with daily, weekly, and monthly ApexCharts trends plus spending by category.
- Recurring templates, monthly budgets, and savings goals open from the Home quick menu with dedicated list/detail flows.
- Reports open from the Home quick menu and export monthly CSV/PDF files with a separate local backup export section.
- Settings for Light/Dark theme, currency, categories, and delete-all-data.
- Archived account view with restore action.

## Architecture

- `lib/main.dart` opens `SqliteFlowStore` and falls back to `MemoryFlowStore` when SQLite is unavailable.
- `lib/app.dart` owns app routing and shell navigation; global data is read from Riverpod providers.
- `lib/state/` contains `FlowState`, `FlowController`, and provider selectors.
- `lib/data/` contains models, SQLite repositories, balance logic, filters, seeding, CSV/PDF report export, and local backup export.
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

## Reports and Backup

- Use `Home > Reports` to choose a month and review income, expense, net cash flow, transfer totals, top expense categories, and transaction count before exporting.
- Monthly CSV exports use stable headers and sorted transaction rows for spreadsheet use.
- Monthly PDF exports include the report title, selected period, summary, transaction table, export timestamp, and page footer.
- Local backup export is available in the Reports backup section. CSV import and local backup restore are intentionally not primary Settings actions.
- After CSV, PDF, or database-backup export, use `Open file` to launch a compatible app or `Choose file location` to save a copy in a visible device folder.

## Product Boundaries

Flow intentionally stays offline-first and lightweight. Do not add login, cloud sync, bank/e-wallet integrations, OCR, AI, investment tracking, or payment-gateway behavior unless explicitly requested.
