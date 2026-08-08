# TODO — Flow Personal Finance Tracker

Dokumen ini menjadi breakdown implementasi berdasarkan `01-personal-finance-flutter-PRD.md`.

## Arah desain yang disepakati

- [ ] Gunakan gaya visual **clean, modern, dan futuristik** dengan fokus pada kartu UI sebagai elemen utama.
- [ ] Terapkan sudut kartu yang sangat membulat, border/radius yang rapi, dan shadow lembut dengan glow tipis.
- [ ] Gunakan font **Montserrat** secara konsisten untuk seluruh aplikasi.
- [ ] Pertahankan visual tetap tenang dan mudah dipindai; jangan menambahkan dashboard, animasi, atau fitur dekoratif di luar kebutuhan MVP.
- [ ] Light mode memakai neutral warm/gray, dark mode memakai charcoal, dengan accent emerald/teal.
- [ ] Warna merah dibatasi untuk expense dan destructive action.
- [ ] Target utama mobile portrait dengan dukungan lebar small (320–359dp), medium (360–399dp), dan large (≥400dp).
- [ ] Gunakan satu set component dan layout yang sama untuk Light, Dark, dan System; perbedaan hanya melalui design tokens.

## Urutan pengerjaan

### 1. Fondasi aplikasi

- [x] Ganti starter counter app menjadi shell aplikasi Flow.
- [x] Tambahkan dependency SQLite (`sqflite`) yang sudah dipasang; dependency Montserrat dan chart ditunda ke task design system/statistics.
- [x] Mulai merapikan struktur Flutter dengan memisahkan entry point (`main.dart`) dan app shell (`app.dart`).
- [x] Pastikan aplikasi dapat dijalankan pada kondisi kosong tanpa crash.

### 2. Design system dan theme

- [x] Buat color bank/token Light: background `#F7F7F4`, surface/card `#FFFFFF`, text `#182321`, muted text `#6F7B78`, accent emerald/teal `#168C78`, income, expense, dan destructive.
- [x] Buat color bank/token Dark: background `#171C1B`, surface/card `#222927`, text `#F2F5F3`, muted text `#AAB8B3`, serta semantic color yang tetap kontras.
- [x] Tambahkan dan gunakan font **Montserrat** untuk seluruh typography aplikasi.
- [x] Buat `ThemeData` light/dark dan dukungan `ThemeMode.system`.
- [x] Tetapkan skala typography untuk greeting, page title, card label, nominal uang, body, caption, dan button.
- [x] Tetapkan spacing, minimum touch target 44–48dp, radius kartu besar, radius input/button, dan shadow/glow yang konsisten.
- [x] Buat design tokens terpusat agar screen tidak menyimpan warna, radius, spacing, atau shadow secara hard-coded.
- [x] Buat component reusable, satu component utama per file, dengan variant terukur: `FlowCard`, `FlowButton`, `FlowAmountText`, `FlowIconContainer`, `FlowTransactionTile`, `FlowEmptyState`, `FlowSegmentedControl`, `FlowSelector`, dan `FlowConfirmationSheet`.
- [x] Pastikan variant component hanya mengubah visual/behavior yang relevan, tanpa menggandakan component untuk setiap screen.
- [x] Verifikasi kontras, overflow, dan keterbacaan pada tiga ukuran layar target.

### 3. Model data dan local persistence

- [x] Definisikan model `Account`, `Category`, `Transaction`, dan `AppSettings` sesuai field di PRD.
- [x] Buat SQLite database lokal dengan migration/versioning sejak versi pertama.
- [x] Buat repository/service untuk CRUD account, category, transaction, dan settings.
- [x] Implementasikan kalkulasi saldo: opening balance + income - expense + transfer masuk - transfer keluar.
- [x] Pastikan edit dan delete transaksi langsung menghitung ulang saldo.
- [x] Tambahkan seed kategori default yang dapat diedit tanpa mengubah referensi transaksi lama.

### 4. App shell dan navigasi

- [x] Implementasikan bottom navigation: Home, Transactions, Statistics, Accounts.
- [x] Tambahkan primary action `+` untuk membuka alur tambah transaksi.
- [x] Tambahkan akses Settings dari avatar/icon pada Home.
- [x] Pastikan state navigasi dan theme tidak hilang saat berpindah tab.

### 5. First use dan akun

- [x] Buat flow Welcome → pilih currency (default IDR) → buat akun pertama → Home.
- [x] Buat form Add/Edit Account untuk Cash, Bank, E-wallet, dan Other.
- [x] Tampilkan total balance dan saldo per akun dalam kartu rounded dengan visual ringkas.
- [x] Implementasikan archive account; jangan menghapus akun yang sudah memiliki transaksi secara sembarangan.
- [x] Buat empty state akun yang mengarahkan pengguna membuat akun pertama.

### 6. Home dashboard

- [x] Buat greeting singkat dan bulan aktif.
- [x] Buat kartu Total Balance dengan hide/show balance.
- [x] Tampilkan ringkasan Income dan Expense bulan aktif.
- [ ] Buat mini cash-flow chart sederhana dengan angka/label pendamping.
- [ ] Buat Spending by Category dengan maksimal 4 kategori + Others.
- [ ] Tampilkan 5 Recent Transactions terakhir.
- [ ] Tambahkan quick action Add transaction.
- [ ] Implementasikan empty, populated, light, dan dark state untuk Home.

### 7. Add/Edit Transaction dan transfer

- [ ] Buat segmented control Expense / Income / Transfer.
- [ ] Jadikan amount sebagai elemen paling dominan dan tampilkan numeric keypad langsung.
- [ ] Buat account selector dan category bottom sheet berisi icon + nama.
- [ ] Tambahkan date dan note opsional.
- [ ] Saat Transfer dipilih, tampilkan From Account dan To Account serta sembunyikan kategori.
- [ ] Nonaktifkan Save sampai field wajib valid.
- [ ] Simpan amount sebagai nilai positif; bedakan expense/income melalui type dan treatment warna di UI.
- [ ] Pastikan transfer hanya memengaruhi saldo akun, bukan total income/expense.
- [ ] Uji form pada keyboard aktif, nama panjang, validasi error, dan lebar layar kecil.

### 8. Transactions

- [ ] Buat list transaksi yang dikelompokkan per tanggal.
- [ ] Tampilkan nominal, type, account, category, dan note secara ringkas.
- [ ] Tambahkan pencarian berdasarkan note/category.
- [ ] Tambahkan filter type, account, category, dan date range.
- [ ] Tampilkan total income dan expense untuk hasil filter.
- [ ] Buat detail transaksi dengan aksi Edit dan Delete.
- [ ] Tambahkan confirmation dialog/sheet untuk delete.
- [ ] Buat no-search-result state.

### 9. Statistics

- [ ] Buat month selector.
- [ ] Tampilkan summary Income vs Expense.
- [ ] Buat donut/bar chart kategori pengeluaran.
- [ ] Buat trend pengeluaran per minggu.
- [ ] Tampilkan top categories dengan nominal dan persentase.
- [ ] Pastikan setiap chart memiliki angka/label sehingga bukan satu-satunya penyampai informasi.
- [ ] Buat empty state dan pastikan chart tetap aman ketika data sedikit.

### 10. Accounts detail dan Settings

- [ ] Buat account detail dengan transaksi milik akun tersebut.
- [ ] Tambahkan pengaturan currency display.
- [ ] Tambahkan pilihan Light / Dark / System.
- [ ] Tambahkan Manage Categories untuk edit/archive kategori.
- [ ] Sediakan Export CSV sebagai stretch goal lokal setelah core flow selesai.
- [ ] Tambahkan Delete all data dengan konfirmasi kuat.

### 11. Validasi MVP dan polish terbatas

- [ ] Tambahkan test untuk kalkulasi saldo, transfer, filter, dan persistence.
- [ ] Jalankan analyzer/test/build Flutter dan perbaiki blocker pertama yang ditemukan.
- [ ] Smoke test core flow: buat akun → income/expense → edit/delete → transfer → tutup/buka aplikasi.
- [ ] Cek semua state wajib PRD: empty, normal, validation error, no result, delete confirmation, nama panjang, light/dark.
- [ ] Cek touch target, safe area, keyboard, overflow, dan scrolling pada small/medium/large phone.
- [ ] Lakukan final visual pass pada konsistensi Montserrat, rounded card, shadow/glow, spacing, dan warna.

## Di luar scope prototype awal

- Budget, recurring transactions, saving goals, receipt attachment, backup/restore, biometric lock, multi-currency conversion, dan cloud sync.
- Login, koneksi bank/e-wallet, OCR struk, AI, investasi, hutang/piutang kompleks, subscription, dan payment gateway.
- Animasi kompleks, ilustrasi dekoratif, serta perubahan layout menjadi desktop dashboard.

## Definition of Done MVP

- [ ] User dapat membuat akun dan mencatat income/expense secara offline.
- [ ] Total balance dan saldo akun konsisten setelah create/edit/delete.
- [ ] Transfer tidak masuk ke income/expense.
- [ ] Transactions dan Statistics mendukung filter/pemahaman data dasar.
- [ ] Data tetap ada setelah aplikasi ditutup dan dibuka kembali.
- [ ] Core flow usable pada small, medium, dan large phone widths.
- [ ] Visual mengikuti arah desain dan menggunakan Montserrat.
