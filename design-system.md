# Flow Design System

This document is the UI contract for Flow. New screens and features should reuse these tokens, components, and layout rules before adding new visual patterns.

## Product Feel

Flow is a compact, offline-first personal finance app for mobile portrait screens. The interface should feel clean, modern, calm, and slightly futuristic, with readable money data as the main focus.

Do not turn Flow into a marketing page, dense desktop dashboard, or decorative illustration-heavy app. The first screen after setup is the actual tracker.

## Target Screens

- Primary target: mobile portrait.
- Required widths: small 320-359dp, medium 360-399dp, large 400dp and above.
- Layout must survive Light and Dark mode.
- Use scrolling lists instead of fixed-height screen assumptions.
- Keep safe area, keyboard, and bottom navigation spacing in mind.

## Colors

Source of truth: `lib/theme/flow_colors.dart`.

Light:

- Background: `#ECEFEA`
- Surface/card: `#FFFFFF`
- Text: `#182321`
- Muted text: `#6F7B78`
- Outline: `#C9D3CD`
- Surface container: `#E2E8E3`

Dark:

- Background: `#121817`
- Surface/card: `#1E2724`
- Text: `#F2F5F3`
- Muted text: `#AAB8B3`
- Outline: `#40504A`
- Surface container: `#2A3531`

Semantic:

- Accent/income: `#168C78`
- Expense: `#C96B6B`
- Destructive: `#B84444`
- Chart amber: `#E0A458`
- Chart blue: `#6D8FC7`
- Chart purple: `#9B7EBD`

Rules:

- Red is only for expense and destructive actions.
- Transfer uses primary/accent styling, not income or expense color.
- Do not add one-off colors inside screens; extend `FlowColors` only when a reusable semantic token is needed.

## Typography

Source of truth: `lib/theme/flow_theme.dart` and `assets/fonts/Montserrat-*`.

- Font family: Montserrat.
- `displaySmall`: 28sp, weight 700, tabular figures; only for main total balance.
- `headlineSmall`: 22sp, weight 700; only for page identity such as "Your Flow".
- `titleLarge`: 18sp, weight 700; page and modal titles.
- `titleMedium`: 15sp, weight 600; section headings.
- `bodyLarge`: 14sp; primary list titles.
- `bodyMedium`: 13sp; normal body text.
- `bodySmall`: 12sp; secondary metadata.
- `labelLarge`: 13sp, weight 700; strong small values.
- `labelMedium`: 12sp, weight 500; labels and muted metadata.
- `labelSmall`: 11sp, weight 500; badges and compact labels.

Money values should use tabular figures and must use `FittedBox`, `Flexible`, `maxLines`, or ellipsis when space can be tight.

## Spacing, Radius, and Elevation

Source of truth: `lib/theme/flow_tokens.dart`.

Spacing:

- `xxs` 4
- `xs` 8
- `sm` 12
- `md` 16
- `lg` 24
- `xl` 32
- `xxl` 40

Card density:

- `compact`: 12dp padding for small summaries, filters, action rows.
- `standard`: 16dp padding for common cards and list items.
- `featured`: 20dp padding for total balance and primary charts.

Internal gaps:

- `gapTight` 4 for label/detail.
- `gapGroup` 8 for items in one group.
- `gapBlock` 12 for separate blocks inside a card.
- `gapSection` 16 for section separation.

Radius:

- Card: 16
- Input: 12
- Button: 12
- Pill: 999

Controls:

- Minimum touch target: 48
- Icon container: 44

Cards use the shared shadow from `FlowShadows.card` or `FlowShadows.darkCard`. Do not create nested cards for ordinary layout.

## Core Components

Source of truth: `lib/components/`.

- `FlowCard`: default surface wrapper. Variants: `balance`, `summary`, `chart`, `transaction`, `action`. Densities: `compact`, `standard`, `featured`.
- `FlowAmountText`: money display with semantic variants `balance`, `income`, `expense`, `transfer`.
- `FlowButton`: command button. Variants: `primary`, `secondary`, `ghost`, `destructive`.
- `FlowIconContainer`: 44x44 icon well for account, category, income, expense, and transfer.
- `FlowTransactionTile`: compact transaction row with icon, title, metadata, and amount.
- `FlowEmptyState`: centered empty state with icon, title, message, and optional action.
- `FlowSegmentedControl`: equal-width mode selector for small option sets.
- `FlowSelector`: input-like row for pickers and bottom-sheet selectors.
- `FlowConfirmationSheet`: destructive confirmation bottom sheet.
- `FlowApexChart`: chart wrapper around `apexcharts_flutter`.

Component rules:

- Prefer these components before creating new widgets.
- One reusable component per file.
- Keep screen-specific composition in screens, but keep visual primitives in `lib/components`.
- Variants should change only relevant visuals or behavior.

## Card Structure

Each card should have a clear structure:

- Header: small label, icon/title row, or section title.
- Body: one main visual focus, such as a total, chart, or list.
- Footer/metadata: optional helper text, counts, percentages, or small action.

Avoid mixing a large amount, chart, legend, long copy, and multiple actions in one unstructured block.

## Navigation and Shell

Source of truth: `lib/app.dart`.

- `FlowShell` uses an `IndexedStack` to preserve tab state.
- Bottom navigation is floating, inset from screen edges, and safe-area aware.
- Primary `+` action opens Add Transaction except on Statistics and Settings.
- Settings is a shell tab, not a separate hidden page.
- Route pushes stay in `FlowApp`; domain state comes from Riverpod.

## Charts

Source of truth: `lib/components/flow_apex_chart.dart` and `lib/screens/statistics_page.dart`.

- Use ApexCharts through `FlowApexChart`.
- Chart labels and tooltips must use compact Rupiah formatting when values are large.
- A chart must never be the only way to understand data; include summary numbers, labels, legend, or top-category rows.
- Empty, one-point, zero-value, and small-width states must be safe.
- Transfers must not be counted as income or expense in statistics.

## Forms and Inputs

- Use Montserrat and shared `InputDecorationTheme`.
- Currency amount fields use `FlowCurrencyInputFormatter`.
- Store amount as positive integer; type determines income/expense/transfer meaning.
- Form input, selected category/account, search query, filter state, selected chart period, and selected tab are local UI state.
- Global persisted settings and domain mutations go through `FlowController`.

## Data and State

Source of truth:

- `lib/state/flow_controller.dart`
- `lib/state/flow_state.dart`
- `lib/state/flow_providers.dart`
- `lib/data/flow_store.dart`

Rules:

- SQLite is the production source of truth.
- `MemoryFlowStore` remains available for tests and unsupported targets.
- Do not duplicate domain state in screens.
- Do not move ephemeral UI state into global providers without a product need.
- Balance formula: opening balance + income - expense + incoming transfer - outgoing transfer.

## Product Boundaries

Allowed near-term additions:

- Import CSV.
- Local backup and restore.
- Recurring transaction templates.
- Budget alerts.
- Savings goals.

Do not add without explicit request:

- Login.
- Cloud sync.
- Bank or e-wallet integrations.
- OCR receipt scanning.
- AI categorization.
- Investment tracking.
- Payment gateway behavior.

## Validation

Before finishing UI or state work:

```powershell
flutter analyze
flutter test --concurrency=1
flutter build apk --debug
```

Use `--concurrency=1` for widget/layout test stability on this project.
