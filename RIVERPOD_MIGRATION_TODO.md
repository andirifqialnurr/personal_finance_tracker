# TODO - Riverpod State Management Migration

Dokumen ini membreakdown perubahan yang akan terjadi saat aplikasi Flow dipindahkan dari state global berbasis `StatefulWidget`/`setState` di `lib/app.dart` menuju Riverpod.

## Tujuan

- [x] Memusatkan app state global di layer state management yang testable.
- [x] Mempertahankan kontrak offline-first: SQLite tetap source of truth persistence lokal.
- [x] Mempertahankan `FlowStore` sebagai abstraction untuk `SqliteFlowStore` dan `MemoryFlowStore`.
- [x] Mengurangi constructor drilling untuk data global seperti accounts, transactions, categories, settings, dan callbacks mutation.
- [x] Menjaga UI state lokal tetap lokal: form input, search/filter, selected tab, selected chart period, dan bottom sheet selection.
- [x] Tidak mengubah behavior domain: saldo tetap `opening_balance + income - expense + incoming_transfer - outgoing_transfer`.
- [x] Tidak memasukkan transfer ke income/expense statistics.

## Scope Utama

- [x] Tambah Riverpod sebagai dependency.
- [x] Buat state global immutable untuk data aplikasi.
- [x] Buat controller Riverpod untuk load/save/delete/export/reset data.
- [x] Refactor `FlowApp` agar membaca state dari provider.
- [x] Refactor screen yang saat ini bergantung pada callback panjang dari `FlowApp`.
- [x] Update test agar bisa override `FlowStore` dengan `MemoryFlowStore`.
- [x] Jalankan validasi analyzer/test/build setelah migrasi selesai.

## File Baru

### `lib/state/flow_state.dart`

- [x] Buat `FlowState` immutable.
- [x] Field yang disimpan:
  - [x] `List<Account> accounts`
  - [x] `List<Category> categories`
  - [x] `List<Transaction> transactions`
  - [x] `AppSettings settings`
  - [x] `bool hasCompletedWelcome`
- [x] Tambahkan factory initial/default state.
- [x] Tambahkan `copyWith`.
- [x] Tambahkan getter turunan yang stabil:
  - [x] `currency`
  - [x] `themeMode`
  - [x] `hideBalance`
  - [x] `activeAccounts`
  - [x] `hasAccounts`
- [x] Pastikan list yang diekspos tidak mudah dimutasi sembarangan dari UI.

### `lib/state/flow_controller.dart`

- [x] Buat Riverpod controller untuk mengelola `FlowState`.
- [x] Controller membaca `FlowStore` dari provider.
- [x] Method yang perlu dibuat:
  - [x] `Future<void> restore()`
  - [x] `Future<void> saveAccount(Account account)`
  - [x] `Future<void> archiveAccount(Account account)`
  - [x] `Future<void> saveTransaction(Transaction transaction, {Transaction? editing})`
  - [x] `Future<void> deleteTransaction(int id)`
  - [x] `Future<void> saveCategory(Category category)`
  - [x] `Future<void> saveCategories(List<Category> categories)`
  - [x] `Future<void> changeHideBalance(bool value)`
  - [x] `Future<void> changeThemeMode(ThemeMode mode)`
  - [x] `Future<void> changeCurrency(String currency)`
  - [x] `Future<void> deleteAllData()`
  - [x] `Future<String> exportCsv()`
  - [x] `Future<void> closeStore()`
- [x] Pindahkan helper dari `lib/app.dart` bila masih dibutuhkan:
  - [x] `_themeModeFromSetting`
  - [x] `_themeModeSetting`
  - [x] `_copyAccount`
- [x] Hindari update UI-only state di controller.
- [x] Pastikan hasil save dari `FlowStore` dipakai kembali untuk state, terutama entity dengan `id` baru.
- [x] Tangani error persistence dengan state error atau debug log yang jelas.

### `lib/state/flow_providers.dart`

- [x] Buat `flowStoreProvider`.
- [x] Buat `flowControllerProvider`.
- [x] Buat selector provider bila perlu untuk mengurangi rebuild:
  - [x] `accountsProvider`
  - [x] `transactionsProvider`
  - [x] `categoriesProvider`
  - [x] `settingsProvider`
  - [x] `themeModeProvider`
  - [x] `hideBalanceProvider`
  - [x] `currencyProvider`
- [x] Sediakan pattern override untuk test dengan `MemoryFlowStore`.

### `lib/state/state.dart`

- [x] Buat barrel export untuk state layer.
- [x] Export:
  - [x] `flow_state.dart`
  - [x] `flow_controller.dart`
  - [x] `flow_providers.dart`

## File Yang Diubah

### `pubspec.yaml`

- [x] Tambahkan dependency Riverpod.
- [x] Gunakan command preferensi:

```powershell
flutter pub add flutter_riverpod
```

- [x] Jangan menambah dependency state management lain seperti `provider`, `bloc`, atau `get_it` kecuali ada alasan baru.
- [x] Setelah dependency berubah, pastikan `pubspec.lock` ikut ter-update dari `flutter pub get`.

### `lib/main.dart`

- [x] Import Riverpod.
- [x] Bungkus app dengan `ProviderScope`.
- [x] Override `flowStoreProvider` dengan store hasil `SqliteFlowStore.open()`.
- [x] Pertahankan fallback ke `MemoryFlowStore` jika SQLite tidak tersedia.
- [x] Pastikan startup tetap:
  - [x] `WidgetsFlutterBinding.ensureInitialized()`
  - [x] open SQLite
  - [x] run app
- [x] Jangan mengubah package name atau native entrypoint.

Target bentuk akhir kira-kira:

```dart
runApp(
  ProviderScope(
    overrides: [
      flowStoreProvider.overrideWithValue(store),
    ],
    child: const FlowApp(),
  ),
);
```

### `lib/app.dart`

- [x] Ubah `FlowApp` dari `StatefulWidget` menjadi `ConsumerWidget` atau `ConsumerStatefulWidget` hanya bila masih perlu lifecycle.
- [x] Hapus state global dari `_FlowAppState`:
  - [x] `_store`
  - [x] `_themeMode`
  - [x] `_accounts`
  - [x] `_transactions`
  - [x] `_categories`
  - [x] `_currency`
  - [x] `_hideBalance`
  - [x] `_hasCompletedWelcome`
- [x] Pindahkan restore state ke controller/provider.
- [x] Pindahkan mutation method ke `FlowController`:
  - [x] `_saveTransaction`
  - [x] `_archiveAccount`
  - [x] `_changeHideBalance`
  - [x] `_changeTheme`
  - [x] `_changeCurrency`
  - [x] `_saveSettings`
  - [x] `_deleteAllData`
  - [x] `_exportCsv`
  - [x] `_persist`
- [x] Pertahankan navigasi route push di `FlowApp` bila belum dibuat routing service.
- [x] `FlowApp` membaca `AsyncValue<FlowState>` dan menampilkan:
  - [x] loading sederhana saat restore berlangsung
  - [x] error sederhana saat restore gagal
  - [x] `FlowWelcomePage` jika belum ada akun
  - [x] `FlowShell` jika akun sudah ada
- [x] Kurangi parameter `FlowShell` jika data bisa dibaca langsung lewat provider.
- [x] Pertahankan selected tab di `FlowShell` sebagai local state.
- [x] Pastikan bottom navigation selected state tidak reset saat data berubah.

### `lib/screens/welcome_page.dart`

- [x] Evaluasi apakah tetap menerima `currency` dan callbacks dari parent.
- [x] Keputusan scope: tetap presentational; `FlowApp` membaca currency dari provider dan meneruskan callback navigasi.
- [x] Trigger create account flow tetap melalui callback navigasi dari parent, bukan dari controller langsung.
- [x] `onCurrencyChanged` memanggil controller.

### `lib/screens/home_dashboard.dart`

- [x] Pilihan migrasi bertahap: tetap menerima props dari `FlowShell`.
- [x] Keputusan scope: `FlowShell` membaca accounts, transactions, categories, currency, dan hideBalance dari provider lalu meneruskan props presentational.
- [x] `onHideBalanceChanged` dari `FlowShell` memanggil controller.
- [x] Hapus mirror local `_hideBalance` jika state global sudah reaktif.
- [x] Pertahankan `onAddTransaction` sebagai callback navigasi.
- [x] Pastikan perhitungan total balance tidak berubah.

### `lib/screens/transactions_page.dart`

- [x] Biarkan search query dan filter modal tetap local state.
- [x] Data global dapat tetap dikirim dari `FlowShell` atau dibaca dari provider.
- [x] `onOpenDetail` tetap callback navigasi.
- [x] Jangan pindahkan `_query`, `_type`, `_accountId`, `_categoryId`, `_dateRange` ke global state kecuali ada kebutuhan deep link atau persist filter.
- [x] Pastikan grouping tanggal, total filter income/expense, dan no-result state tidak berubah.

### `lib/screens/statistics_page.dart`

- [x] Biarkan period dan selected date tetap local state.
- [x] Data transactions/categories bisa dibaca dari provider atau tetap props.
- [x] Jangan mengubah agregasi:
  - [x] daily = bucket empat jam pada tanggal terpilih
  - [x] weekly = bucket tujuh hari terakhir
  - [x] monthly = bucket dua belas bulan terakhir
- [x] Pastikan transfer tetap dikeluarkan dari income/expense statistics.

### `lib/screens/accounts_page.dart`

- [x] Keputusan scope: tetap presentational; `FlowShell` membaca accounts/transactions/currency dari provider.
- [x] `onAdd`, `onEdit`, dan `onOpenDetail` tetap callback navigasi.
- [x] `onArchive` panggil controller.
- [x] Pertahankan konfirmasi archive di UI.

### `lib/screens/account_form_page.dart`

- [x] Form state tetap local.
- [x] `onSaved` tetap callback parent; `FlowApp` memanggil controller.
- [x] Jangan simpan controller text input ke global state.
- [x] Pastikan opening balance formatter tetap jalan.

### `lib/screens/add_transaction_page.dart`

- [x] Form state tetap local.
- [x] Accounts/categories tetap props dari state provider terbaru saat route dibuka.
- [x] `onSaved` tetap callback parent; `FlowApp` memanggil controller.
- [x] Pertahankan validasi:
  - [x] amount wajib valid dan positif
  - [x] account wajib
  - [x] category wajib untuk income/expense
  - [x] destination wajib untuk transfer
  - [x] source dan destination transfer tidak sama
- [x] Jangan ubah aturan amount sebagai nilai positif.

### `lib/screens/transaction_detail_page.dart`

- [x] Bisa tetap stateless dengan callback.
- [x] Keputusan scope: delete transaction tetap callback route; `FlowApp` memanggil controller.
- [x] Detail display tetap membutuhkan nama account/category yang dihitung dari state provider saat route dibuka.
- [x] Pertahankan confirmation sheet sebelum delete.

### `lib/screens/account_detail_page.dart`

- [x] Bisa tetap menerima account/transactions dari navigator.
- [x] Account archived state tetap aman karena archive terjadi lewat controller dan shell rebuild dari provider.
- [x] `onEdit` dan `onOpenTransaction` tetap callback navigasi.

### `lib/screens/settings_page.dart`

- [x] Ubah setting global agar panggil controller:
  - [x] theme mode
  - [x] currency
  - [x] categories
  - [x] export CSV
  - [x] delete all data
- [x] `_isExporting` tetap local state kecuali ingin global loading per action.
- [x] Pertahankan pilihan visible hanya Light/Dark.
- [x] Tetap baca legacy `ThemeModeSetting.system` sebagai fallback ke Light.

### `lib/screens/manage_categories_page.dart`

- [x] Local draft categories tetap boleh dipertahankan untuk UX edit/archive.
- [x] Saat selesai/update, panggil controller save categories.
- [x] Pastikan category lama tidak dihapus fisik agar transaksi lama tetap punya referensi aman.

### `lib/data/flow_store.dart`

- [x] Pertahankan interface `FlowStore`.
- [x] Tambahkan method hanya jika benar-benar dibutuhkan oleh controller.
- [x] Pertimbangkan method berikut bila migrasi membutuhkan atomic update:
  - [x] `Future<List<Category>> saveCategories(List<Category> categories)` tidak ditambahkan; controller menyimpan batch kategori lewat method existing.
  - [x] `Future<AppSettings> loadSettings()` tidak wajib karena `load()` sudah ada.
- [x] Pastikan `SqliteFlowStore.saveAccount/saveTransaction/saveCategory` tetap mengembalikan entity tersimpan.
- [x] Pertahankan `MemoryFlowStore` untuk tests dan fallback unsupported target.

### `lib/data/flow_repositories.dart`

- [x] Tidak perlu perubahan besar.
- [x] Cek apakah method batch category save dibutuhkan.
- [x] Jangan ubah query order kecuali test mengharuskan.
- [x] Jangan mengubah behavior transaction balance/statistics dari file ini.

### `lib/data/flow_csv_exporter.dart`

- [x] Tidak perlu perubahan domain.
- [x] Pemanggilan pindah dari `FlowApp._exportCsv` ke `FlowController.exportCsv`.
- [x] Pastikan exporter tetap menerima accounts/categories/transactions dari state terbaru.

### `lib/data/models/*`

- [x] Tidak perlu perubahan besar.
- [x] Tambahkan `copyWith` hanya bila dibutuhkan controller dan tidak membuat model membengkak.
- [x] Prioritaskan helper internal di controller bila perubahan model tidak diperlukan.

## Test Yang Diubah

### `test/core_flow_test.dart`

- [x] Update harness agar memakai `ProviderScope`.
- [x] Override `flowStoreProvider` dengan `MemoryFlowStore`.
- [x] Pastikan flow income dan transfer tetap menyimpan data ke store.
- [x] Jangan mengubah ekspektasi transfer.

### `test/mvp_state_test.dart`

- [x] Update `FlowApp(store: store)` menjadi provider override, atau pertahankan constructor compatibility sementara.
- [x] Pastikan app restore snapshot tetap menampilkan Home dan Recent transactions.
- [x] Pertahankan surface size checks 320/360/400dp.

### `test/total_balance_visibility_test.dart`

- [x] Update setup state settings via provider/store.
- [x] Pastikan hide balance persist setelah reload.
- [x] Pastikan hanya nominal Total Balance yang dimasking.

### `test/ui_refinement_test.dart`

- [x] Update harness Riverpod untuk theme mode state.
- [x] Pastikan floating navigation masih mempertahankan selected tab.
- [x] Jalankan dengan concurrency 1 bila surface-size/layout test tidak stabil.

### `test/flow_store_test.dart`

- [x] Idealnya tidak berubah karena ini test persistence layer.
- [x] Update hanya jika interface `FlowStore` bertambah.

### Test Baru: `test/flow_controller_test.dart`

- [x] Tambahkan unit/widget-adjacent test controller tanpa full UI.
- [x] Test restore dari `MemoryFlowStore`.
- [x] Test save account menghasilkan `hasCompletedWelcome = true`.
- [x] Test save transaction create/edit.
- [x] Test delete transaction.
- [x] Test change settings: theme, currency, hide balance.
- [x] Test delete all restores default categories dan default settings.
- [x] Test export CSV memakai state terkini.

## Urutan Implementasi Disarankan

### Batch 1 - Dependency dan State Foundation

- [x] Tambah `flutter_riverpod`.
- [x] Buat folder `lib/state`.
- [x] Buat `FlowState`.
- [x] Buat provider store dan controller skeleton.
- [x] Tambah test awal `flow_controller_test.dart` untuk restore/settings sederhana.
- [x] Jalankan format dan targeted analyzer.

### Batch 2 - Controller Actions

- [x] Pindahkan logic save settings dari `FlowApp` ke controller.
- [x] Pindahkan save account/archive account.
- [x] Pindahkan save/edit/delete transaction.
- [x] Pindahkan save categories.
- [x] Pindahkan delete all data.
- [x] Pindahkan export CSV.
- [x] Tambah/ubah test controller untuk semua action.

### Batch 3 - App Shell Migration

- [x] Bungkus app dengan `ProviderScope` di `main.dart`.
- [x] Refactor `FlowApp` membaca `flowControllerProvider`.
- [x] Hapus global `setState` dari `FlowApp`.
- [x] Pertahankan navigasi page push dari app shell.
- [x] Pastikan welcome/home routing sama seperti sebelumnya.

### Batch 4 - Screen Cleanup Bertahap

- [x] Kurangi callback drilling di `FlowShell`.
- [x] Update Home hide balance agar langsung ke controller.
- [x] Update Settings agar langsung ke controller.
- [x] Evaluasi Accounts/Transactions/Statistics apakah tetap props atau provider selector.
- [x] Jangan refactor semua screen sekaligus jika test mulai sulit dibaca.

### Batch 5 - Test dan Stabilization

- [x] Update semua test harness Riverpod.
- [x] Jalankan `dart format`.
- [x] Jalankan `flutter analyze`.
- [x] Jalankan `flutter test --concurrency=1`.
- [x] Jalankan `flutter build apk --debug`.
- [x] Jika Flutter CLI timeout/lock, catat proses dan lockfile secara eksplisit sebelum retry.

Catatan validasi 2026-08-16:

- [x] `flutter analyze` melaporkan `No issues found!`.
- [x] `flutter test --concurrency=1` selesai hijau dengan 49 test.
- [x] `flutter build apk --debug` berhasil membuat `build\app\outputs\flutter-apk\app-debug.apk`.
- [x] `dart format` sempat timeout/hang pada file terbatas; analyzer, full test, dan debug build menjadi validasi utama untuk batch ini.

## Risiko dan Guardrail

- [x] Jangan membuat duplicate source of truth antara `FlowState` dan list mutable lama di `FlowApp`.
- [x] Jangan memindahkan ephemeral UI state ke global provider tanpa kebutuhan jelas.
- [x] Jangan mengubah schema SQLite hanya untuk migrasi state management.
- [x] Jangan mengubah PRD/MVP behavior saat refactor.
- [x] Jangan menghapus `MemoryFlowStore`; itu masih penting untuk tests.
- [x] Jangan mengklaim analyzer/test/build sukses jika Flutter CLI timeout atau telemetry permission membuat exit status bias.
- [x] Jalankan test Flutter secara berurutan bila ada layout/surface-size tests.

## Definition of Done

- [x] `FlowApp` tidak lagi menyimpan app domain state global dengan `setState`.
- [x] Data global dibaca dari Riverpod provider.
- [x] Semua mutation domain berjalan lewat controller.
- [x] SQLite persistence tetap dipakai di production startup.
- [x] `MemoryFlowStore` tetap bisa dipakai untuk tests.
- [x] Welcome flow, add account, add income, add expense, transfer, edit/delete transaction, archive account, settings, export CSV, dan delete all tetap berjalan.
- [x] Existing regression tests diperbarui dan lulus.
- [x] Analyzer bersih, atau blocker environment dicatat spesifik.
- [x] Debug APK berhasil dibuat, atau blocker environment dicatat spesifik.
