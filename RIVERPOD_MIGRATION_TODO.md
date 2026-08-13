# TODO - Riverpod State Management Migration

Dokumen ini membreakdown perubahan yang akan terjadi saat aplikasi Flow dipindahkan dari state global berbasis `StatefulWidget`/`setState` di `lib/app.dart` menuju Riverpod.

## Tujuan

- [ ] Memusatkan app state global di layer state management yang testable.
- [ ] Mempertahankan kontrak offline-first: SQLite tetap source of truth persistence lokal.
- [ ] Mempertahankan `FlowStore` sebagai abstraction untuk `SqliteFlowStore` dan `MemoryFlowStore`.
- [ ] Mengurangi constructor drilling untuk data global seperti accounts, transactions, categories, settings, dan callbacks mutation.
- [ ] Menjaga UI state lokal tetap lokal: form input, search/filter, selected tab, selected chart period, dan bottom sheet selection.
- [ ] Tidak mengubah behavior domain: saldo tetap `opening_balance + income - expense + incoming_transfer - outgoing_transfer`.
- [ ] Tidak memasukkan transfer ke income/expense statistics.

## Scope Utama

- [x] Tambah Riverpod sebagai dependency.
- [x] Buat state global immutable untuk data aplikasi.
- [x] Buat controller Riverpod untuk load/save/delete/export/reset data.
- [ ] Refactor `FlowApp` agar membaca state dari provider.
- [ ] Refactor screen yang saat ini bergantung pada callback panjang dari `FlowApp`.
- [ ] Update test agar bisa override `FlowStore` dengan `MemoryFlowStore`.
- [ ] Jalankan validasi analyzer/test/build setelah migrasi selesai.

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
- [ ] Method yang perlu dibuat:
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

- [ ] Tambahkan dependency Riverpod.
- [ ] Gunakan command preferensi:

```powershell
flutter pub add flutter_riverpod
```

- [ ] Jangan menambah dependency state management lain seperti `provider`, `bloc`, atau `get_it` kecuali ada alasan baru.
- [ ] Setelah dependency berubah, pastikan `pubspec.lock` ikut ter-update dari `flutter pub get`.

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
- [ ] Kurangi parameter `FlowShell` jika data bisa dibaca langsung lewat provider.
- [x] Pertahankan selected tab di `FlowShell` sebagai local state.
- [x] Pastikan bottom navigation selected state tidak reset saat data berubah.

### `lib/screens/welcome_page.dart`

- [ ] Evaluasi apakah tetap menerima `currency` dan callbacks dari parent.
- [ ] Jika refactor penuh, ubah menjadi `ConsumerWidget`.
- [ ] Ambil currency dari provider.
- [ ] Trigger create account flow tetap melalui callback navigasi dari parent, bukan dari controller langsung.
- [ ] `onCurrencyChanged` memanggil controller.

### `lib/screens/home_dashboard.dart`

- [x] Pilihan migrasi bertahap: tetap menerima props dari `FlowShell`.
- [ ] Pilihan migrasi penuh: ubah menjadi `ConsumerWidget`.
- [ ] Jika migrasi penuh:
  - [ ] baca accounts, transactions, categories, currency, hideBalance dari provider.
  - [ ] `onHideBalanceChanged` panggil controller.
- [x] Hapus mirror local `_hideBalance` jika state global sudah reaktif.
- [x] Pertahankan `onAddTransaction` sebagai callback navigasi.
- [x] Pastikan perhitungan total balance tidak berubah.

### `lib/screens/transactions_page.dart`

- [ ] Biarkan search query dan filter modal tetap local state.
- [ ] Data global dapat tetap dikirim dari `FlowShell` atau dibaca dari provider.
- [ ] `onOpenDetail` tetap callback navigasi.
- [ ] Jangan pindahkan `_query`, `_type`, `_accountId`, `_categoryId`, `_dateRange` ke global state kecuali ada kebutuhan deep link atau persist filter.
- [ ] Pastikan grouping tanggal, total filter income/expense, dan no-result state tidak berubah.

### `lib/screens/statistics_page.dart`

- [ ] Biarkan period dan selected date tetap local state.
- [ ] Data transactions/categories bisa dibaca dari provider atau tetap props.
- [ ] Jangan mengubah agregasi:
  - [ ] yearly = 12 bucket bulanan
  - [ ] monthly = bucket harian per bulan
  - [ ] date = 1 bucket tanggal terpilih
- [ ] Pastikan transfer tetap dikeluarkan dari income/expense statistics.

### `lib/screens/accounts_page.dart`

- [ ] Evaluasi menjadi `ConsumerWidget` agar accounts/transactions/currency dibaca dari provider.
- [ ] `onAdd`, `onEdit`, dan `onOpenDetail` tetap callback navigasi.
- [ ] `onArchive` panggil controller.
- [ ] Pertahankan konfirmasi archive di UI.

### `lib/screens/account_form_page.dart`

- [ ] Form state tetap local.
- [ ] `onSaved` bisa tetap callback parent atau langsung memanggil controller jika page menjadi `ConsumerStatefulWidget`.
- [ ] Jangan simpan controller text input ke global state.
- [ ] Pastikan opening balance formatter tetap jalan.

### `lib/screens/add_transaction_page.dart`

- [ ] Form state tetap local.
- [ ] Accounts/categories bisa tetap props atau dibaca via provider.
- [ ] `onSaved` bisa tetap callback parent atau langsung memanggil controller.
- [ ] Pertahankan validasi:
  - [ ] amount wajib valid dan positif
  - [ ] account wajib
  - [ ] category wajib untuk income/expense
  - [ ] destination wajib untuk transfer
  - [ ] source dan destination transfer tidak sama
- [ ] Jangan ubah aturan amount sebagai nilai positif.

### `lib/screens/transaction_detail_page.dart`

- [ ] Bisa tetap stateless dengan callback.
- [ ] Jika refactor penuh, delete transaction dapat memanggil controller.
- [ ] Detail display tetap membutuhkan nama account/category yang bisa dihitung dari provider.
- [ ] Pertahankan confirmation sheet sebelum delete.

### `lib/screens/account_detail_page.dart`

- [ ] Bisa tetap menerima account/transactions dari navigator.
- [ ] Jika dibaca dari provider, pastikan account archived/deleted state tetap aman.
- [ ] `onEdit` dan `onOpenTransaction` tetap callback navigasi.

### `lib/screens/settings_page.dart`

- [ ] Ubah setting global agar panggil controller:
  - [ ] theme mode
  - [ ] currency
  - [ ] categories
  - [ ] export CSV
  - [ ] delete all data
- [ ] `_isExporting` tetap local state kecuali ingin global loading per action.
- [ ] Pertahankan pilihan visible hanya Light/Dark.
- [ ] Tetap baca legacy `ThemeModeSetting.system` sebagai fallback ke Light.

### `lib/screens/manage_categories_page.dart`

- [ ] Local draft categories tetap boleh dipertahankan untuk UX edit/archive.
- [ ] Saat selesai/update, panggil controller save categories.
- [ ] Pastikan category lama tidak dihapus fisik agar transaksi lama tetap punya referensi aman.

### `lib/data/flow_store.dart`

- [ ] Pertahankan interface `FlowStore`.
- [ ] Tambahkan method hanya jika benar-benar dibutuhkan oleh controller.
- [ ] Pertimbangkan method berikut bila migrasi membutuhkan atomic update:
  - [ ] `Future<List<Category>> saveCategories(List<Category> categories)`
  - [ ] `Future<AppSettings> loadSettings()` tidak wajib karena `load()` sudah ada.
- [ ] Pastikan `SqliteFlowStore.saveAccount/saveTransaction/saveCategory` tetap mengembalikan entity tersimpan.
- [ ] Pertahankan `MemoryFlowStore` untuk tests dan fallback unsupported target.

### `lib/data/flow_repositories.dart`

- [ ] Tidak perlu perubahan besar.
- [ ] Cek apakah method batch category save dibutuhkan.
- [ ] Jangan ubah query order kecuali test mengharuskan.
- [ ] Jangan mengubah behavior transaction balance/statistics dari file ini.

### `lib/data/flow_csv_exporter.dart`

- [ ] Tidak perlu perubahan domain.
- [ ] Pemanggilan pindah dari `FlowApp._exportCsv` ke `FlowController.exportCsv`.
- [ ] Pastikan exporter tetap menerima accounts/categories/transactions dari state terbaru.

### `lib/data/models/*`

- [ ] Tidak perlu perubahan besar.
- [ ] Tambahkan `copyWith` hanya bila dibutuhkan controller dan tidak membuat model membengkak.
- [ ] Prioritaskan helper internal di controller bila perubahan model tidak diperlukan.

## Test Yang Diubah

### `test/core_flow_test.dart`

- [ ] Update harness agar memakai `ProviderScope`.
- [ ] Override `flowStoreProvider` dengan `MemoryFlowStore`.
- [ ] Pastikan flow income dan transfer tetap menyimpan data ke store.
- [ ] Jangan mengubah ekspektasi transfer.

### `test/mvp_state_test.dart`

- [ ] Update `FlowApp(store: store)` menjadi provider override, atau pertahankan constructor compatibility sementara.
- [ ] Pastikan app restore snapshot tetap menampilkan Home dan Recent transactions.
- [ ] Pertahankan surface size checks 320/360/400dp.

### `test/total_balance_visibility_test.dart`

- [ ] Update setup state settings via provider/store.
- [ ] Pastikan hide balance persist setelah reload.
- [ ] Pastikan hanya nominal Total Balance yang dimasking.

### `test/ui_refinement_test.dart`

- [ ] Update harness Riverpod untuk theme mode state.
- [ ] Pastikan floating navigation masih mempertahankan selected tab.
- [ ] Jalankan dengan concurrency 1 bila surface-size/layout test tidak stabil.

### `test/flow_store_test.dart`

- [ ] Idealnya tidak berubah karena ini test persistence layer.
- [ ] Update hanya jika interface `FlowStore` bertambah.

### Test Baru: `test/flow_controller_test.dart`

- [ ] Tambahkan unit/widget-adjacent test controller tanpa full UI.
- [ ] Test restore dari `MemoryFlowStore`.
- [ ] Test save account menghasilkan `hasCompletedWelcome = true`.
- [ ] Test save transaction create/edit.
- [ ] Test delete transaction.
- [ ] Test change settings: theme, currency, hide balance.
- [ ] Test delete all restores default categories dan default settings.
- [ ] Test export CSV memakai state terkini.

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

- [ ] Kurangi callback drilling di `FlowShell`.
- [x] Update Home hide balance agar langsung ke controller.
- [ ] Update Settings agar langsung ke controller.
- [ ] Evaluasi Accounts/Transactions/Statistics apakah tetap props atau provider selector.
- [ ] Jangan refactor semua screen sekaligus jika test mulai sulit dibaca.

### Batch 5 - Test dan Stabilization

- [ ] Update semua test harness Riverpod.
- [x] Jalankan `dart format`.
- [ ] Jalankan `flutter analyze`.
- [ ] Jalankan `flutter test --concurrency=1`.
- [ ] Jalankan `flutter build apk --debug`.
- [x] Jika Flutter CLI timeout/lock, catat proses dan lockfile secara eksplisit sebelum retry.

Catatan validasi 2026-08-13:

- [x] `dart analyze` full melaporkan `No issues found!` setelah cleanup unused local variable di `lib/screens/accounts_page.dart`.
- [ ] `flutter test --concurrency=1` belum berhasil selesai; command timeout setelah 180 detik.
- [ ] `flutter build apk --debug` belum berhasil selesai; command timeout setelah 240 detik.
- [x] Emulator aktif terdeteksi sebagai `emulator-5554` dengan model `sdk_gphone64_x86_64`.
- [x] Setelah timeout Flutter CLI, proses `dart.exe` dari `C:\Users\HP\develop\flutter\bin\cache\dart-sdk\bin\dart.exe` dan `C:\Users\HP\develop\flutter\bin\cache\lockfile` terdeteksi aktif.

## Risiko dan Guardrail

- [ ] Jangan membuat duplicate source of truth antara `FlowState` dan list mutable lama di `FlowApp`.
- [ ] Jangan memindahkan ephemeral UI state ke global provider tanpa kebutuhan jelas.
- [ ] Jangan mengubah schema SQLite hanya untuk migrasi state management.
- [ ] Jangan mengubah PRD/MVP behavior saat refactor.
- [ ] Jangan menghapus `MemoryFlowStore`; itu masih penting untuk tests.
- [ ] Jangan mengklaim analyzer/test/build sukses jika Flutter CLI timeout atau telemetry permission membuat exit status bias.
- [ ] Jalankan test Flutter secara berurutan bila ada layout/surface-size tests.

## Definition of Done

- [ ] `FlowApp` tidak lagi menyimpan app domain state global dengan `setState`.
- [ ] Data global dibaca dari Riverpod provider.
- [ ] Semua mutation domain berjalan lewat controller.
- [ ] SQLite persistence tetap dipakai di production startup.
- [ ] `MemoryFlowStore` tetap bisa dipakai untuk tests.
- [ ] Welcome flow, add account, add income, add expense, transfer, edit/delete transaction, archive account, settings, export CSV, dan delete all tetap berjalan.
- [ ] Existing regression tests diperbarui dan lulus.
- [x] Analyzer bersih, atau blocker environment dicatat spesifik.
- [x] Debug APK berhasil dibuat, atau blocker environment dicatat spesifik.
