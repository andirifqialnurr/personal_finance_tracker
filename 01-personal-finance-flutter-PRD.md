# PRD — Flow: Personal Finance Tracker

**Platform:** Mobile — Flutter  
**Persistence:** `sqflite` / SQLite lokal di perangkat  
**Mode:** Offline-first, single user, tanpa akun  
**Prototype target:** Lovable  
**Prioritas:** Portfolio MVP

## 1. Ringkasan produk

Flow adalah aplikasi pencatatan keuangan pribadi untuk menjawab tiga pertanyaan sederhana: berapa uang yang dimiliki, dari mana uang masuk, dan ke mana uang keluar. Aplikasi bukan software accounting dan tidak terhubung ke bank. Semua transaksi dimasukkan manual dan seluruh data tersimpan di perangkat.

## 2. Tujuan

- Mencatat pemasukan, pengeluaran, dan transfer antar akun dalam kurang dari 15 detik.
- Menampilkan saldo aktual per akun dan total kekayaan kas yang tercatat.
- Membantu pengguna memahami pola pengeluaran bulanan.
- Memberikan portfolio case yang kuat untuk data modelling, form UX, chart, filtering, dan local persistence.

## 3. Batas MVP

Termasuk: akun/dompet, kategori, transaksi, transfer, dashboard bulanan, statistik, pencarian/filter, edit/hapus, dark/light mode.

Tidak termasuk: login, cloud sync, koneksi bank/e-wallet, OCR struk, AI, investasi, hutang/piutang kompleks, multi-currency conversion, subscription, payment gateway.

## 4. Pengguna utama

Individu yang ingin mencatat arus uang harian secara manual tanpa menghubungkan data finansial ke layanan eksternal.

## 5. Navigasi

Bottom navigation 4 item:

1. Home
2. Transactions
3. Statistics
4. Accounts

Tombol `+` menjadi primary action untuk menambahkan transaksi. Settings dibuka dari avatar/icon di Home.

## 6. Core flow

### First use

`Welcome → pilih mata uang (default IDR) → buat akun pertama → Home`

Tidak ada onboarding panjang dan tidak ada login.

### Add transaction

`+ → Expense / Income / Transfer → nominal → akun → kategori → tanggal/catatan → Save`

Form harus dapat digunakan satu tangan. Numeric keypad muncul langsung saat input nominal.

### Transfer

`Transfer → From Account → To Account → Amount → Date → Save`

Transfer mengurangi saldo akun asal dan menambah saldo akun tujuan, tetapi **tidak dihitung sebagai income atau expense**.

## 7. Screen requirements

### Home

- Greeting pendek + bulan aktif.
- Total Balance sebagai angka utama dengan opsi hide/show.
- Ringkasan `Income` dan `Expense` bulan aktif.
- Mini cash-flow chart.
- Spending by category: maksimal 4 kategori utama + `Others`.
- Recent Transactions: 5 terakhir.
- Quick action `Add transaction`.
- Empty state mengarahkan pengguna membuat transaksi pertama.

### Add / Edit Transaction

- Segmented control: Expense / Income / Transfer.
- Amount sebagai elemen paling dominan.
- Account selector.
- Category selector berupa bottom sheet dengan icon + nama.
- Date, note opsional.
- Untuk transfer: From Account dan To Account; kategori disembunyikan.
- Save disabled sampai field wajib valid.

### Transactions

- List dikelompokkan per tanggal.
- Search catatan/kategori.
- Filter: type, account, category, date range.
- Total income dan expense untuk hasil filter.
- Tap item membuka detail; detail memiliki Edit dan Delete.

### Statistics

- Month selector.
- Income vs Expense summary.
- Donut/bar chart kategori pengeluaran.
- Trend pengeluaran per minggu.
- Top categories dengan nominal + persentase.
- Chart tidak boleh menjadi satu-satunya penyampai informasi; selalu ada angka/label.

### Accounts

- Total Balance.
- List account: Cash, Bank, E-wallet, Other.
- Saldo tiap akun.
- Add/Edit/Archive Account.
- Account detail menampilkan transaksi akun tersebut.

### Settings

- Currency display.
- Light / Dark / System theme.
- Manage categories.
- Export CSV opsional sebagai stretch goal lokal.
- Delete all data dengan konfirmasi kuat.

## 8. Business rules

- `account_balance = opening_balance + income - expense + incoming_transfer - outgoing_transfer`.
- Penghapusan/edit transaksi harus langsung merekalkulasi saldo.
- Income menggunakan nilai positif di UI; expense menggunakan treatment warna/arah yang berbeda, tetapi nilai database tetap menyimpan `amount` positif + `type`.
- Nominal IDR memakai pemisah ribuan dan tanpa desimal secara default.
- Akun yang memiliki transaksi boleh di-archive, bukan dihapus sembarangan.
- Category default dapat diedit; transaksi lama tetap mempertahankan referensinya.

## 9. Model data lokal

### accounts
`id, name, type, opening_balance, icon, color, is_archived, created_at, updated_at`

### categories
`id, name, transaction_type, icon, color, is_default, is_archived`

### transactions
`id, type, amount, account_id, destination_account_id?, category_id?, note?, occurred_at, created_at, updated_at`

### app_settings
`currency, theme_mode, hide_balance`

Gunakan migration/versioning SQLite sejak versi pertama. Jangan menyimpan transaksi inti hanya di state atau key-value storage.

## 10. Arahan UI/UX untuk Lovable

Karakter: tenang, bersih, terpercaya, modern. Hindari dashboard finansial yang terlalu ramai. Light mode menggunakan neutral warm/gray; dark mode menggunakan charcoal, bukan pure black. Accent utama emerald/teal; merah hanya untuk destructive/expense, bukan dekorasi berlebihan.

- Bottom navigation konsisten.
- Card radius medium, shadow sangat ringan.
- Angka uang menggunakan tabular numerals bila tersedia.
- Minimum touch target ±44–48dp.
- Semua destructive action membutuhkan confirmation sheet/dialog.
- Jangan menggunakan hover-dependent interaction.

### Design system dan component architecture

UI harus dibangun secara component-based. Komponen yang dipakai berulang dibuat sebagai Flutter widget reusable, idealnya satu komponen utama per file, lalu dipanggil dari screen dengan variant dan data yang sesuai. Jangan membuat satu file raksasa yang berisi seluruh komponen aplikasi.

Komponen minimum yang perlu dipusatkan:

- `FlowCard`: `balance`, `summary`, `chart`, `transaction`, dan `action`.
- `FlowButton`: `primary`, `secondary`, `ghost`, dan `destructive`.
- `FlowAmountText`: `balance`, `income`, `expense`, dan `transfer`.
- `FlowIconContainer`: `account`, `category`, `income`, `expense`, dan `transfer`.
- `FlowTransactionTile`, `FlowEmptyState`, `FlowSegmentedControl`, `FlowSelector`, dan `FlowConfirmationSheet`.

Variant hanya mengubah hal yang memang relevan seperti warna, icon treatment, padding, emphasis, atau elevation. Struktur, touch target, radius, dan typography tetap mengikuti design tokens yang sama.

#### Design tokens

- Font utama: **Montserrat** untuk heading, nominal, label, body, dan button. Angka uang memakai tabular numerals bila tersedia.
- Light background: warm gray `#F7F7F4`; light surface/card: `#FFFFFF`; light text: `#182321`; light muted text: `#6F7B78`.
- Dark background: charcoal `#171C1B`; dark surface/card: `#222927`; dark text: `#F2F5F3`; dark muted text: `#AAB8B3`.
- Primary accent: emerald/teal `#168C78`; accent soft untuk surface/icon boleh memakai tint transparan dari warna utama.
- Income: teal/green yang tetap terbaca di light dan dark mode. Expense: muted red seperlunya. Destructive: red yang lebih tegas hanya pada aksi destructive.
- Card memakai radius besar dan konsisten, border tipis bila dibutuhkan, serta shadow lembut dengan glow tipis. Hindari drop shadow berat, gradient berlebihan, dan pure black.
- Spacing menggunakan skala kecil yang konsisten; semua kontrol interaktif memiliki minimum touch target 44–48dp.

Light, Dark, dan System theme harus memakai component dan layout yang sama. Yang berubah adalah token warna, contrast, surface, border, dan shadow agar pengalaman tetap konsisten.

### Adaptive mobile

- **Small:** 320–359dp — satu kolom, chart disederhanakan, label panjang truncate/wrap aman.
- **Medium:** 360–399dp — baseline prototype.
- **Large:** ≥400dp — spacing sedikit lebih lega; jangan mengubah menjadi desktop grid.
- Portrait adalah target utama; safe area dan keyboard harus diperhitungkan.

## 11. State wajib diprototype

- Empty: belum ada akun/transaksi.
- Normal populated state.
- Validation error.
- No search result.
- Delete confirmation.
- Long category/account name.
- Light dan dark mode minimal pada Home, Add Transaction, dan Statistics.

## 12. Acceptance criteria MVP

- User dapat membuat minimal satu account lalu mencatat income/expense.
- Saldo account dan total balance selalu konsisten setelah create/edit/delete.
- Transfer tidak memengaruhi total income/expense.
- Filter transaksi dan ringkasan statistik bekerja tanpa internet.
- App dapat ditutup dan dibuka kembali tanpa kehilangan data.
- Seluruh core flow dapat digunakan pada small, medium, dan large phone widths.

## 13. V2, bukan untuk prototype awal

Budget, recurring transactions, saving goals, attachment receipt, backup/restore, biometric lock, multi-currency, dan cloud sync.
