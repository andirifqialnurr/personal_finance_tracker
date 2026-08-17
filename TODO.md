# TODO — Flow Personal Finance Tracker

Dokumen ini menjadi breakdown implementasi berdasarkan `01-personal-finance-flutter-PRD.md`.

## Arah desain yang disepakati

- [x] Gunakan gaya visual **clean, modern, dan futuristik** dengan fokus pada kartu UI sebagai elemen utama.
- [x] Terapkan sudut kartu yang sangat membulat, border/radius yang rapi, dan shadow lembut dengan glow tipis.
- [x] Gunakan font **Montserrat** secara konsisten untuk seluruh aplikasi.
- [x] Pertahankan visual tetap tenang dan mudah dipindai; jangan menambahkan dashboard, animasi, atau fitur dekoratif di luar kebutuhan MVP.
- [x] Light mode memakai neutral warm/gray, dark mode memakai charcoal, dengan accent emerald/teal.
- [x] Warna merah dibatasi untuk expense dan destructive action.
- [x] Target utama mobile portrait dengan dukungan lebar small (320–359dp), medium (360–399dp), dan large (≥400dp).
- [x] Gunakan satu set component dan layout yang sama untuk Light, Dark, dan System; perbedaan hanya melalui design tokens.

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
- [x] Buat mini cash-flow chart sederhana dengan angka/label pendamping.
- [x] Buat Spending by Category dengan maksimal 4 kategori + Others.
- [x] Tampilkan 5 Recent Transactions terakhir.
- [x] Tambahkan quick action Add transaction.
- [x] Implementasikan empty, populated, light, dan dark state untuk Home.

### 7. Add/Edit Transaction dan transfer

- [x] Buat segmented control Expense / Income / Transfer.
- [x] Jadikan amount sebagai elemen paling dominan dan tampilkan numeric keypad langsung.
- [x] Buat account selector dan category bottom sheet berisi icon + nama.
- [x] Tambahkan date dan note opsional.
- [x] Saat Transfer dipilih, tampilkan From Account dan To Account serta sembunyikan kategori.
- [x] Nonaktifkan Save sampai field wajib valid.
- [x] Simpan amount sebagai nilai positif; bedakan expense/income melalui type dan treatment warna di UI.
- [x] Pastikan transfer hanya memengaruhi saldo akun, bukan total income/expense.
- [x] Uji form pada keyboard aktif, nama panjang, validasi error, dan lebar layar kecil.

### 8. Transactions

- [x] Buat list transaksi yang dikelompokkan per tanggal.
- [x] Tampilkan nominal, type, account, category, dan note secara ringkas.
- [x] Tambahkan pencarian berdasarkan note/category.
- [x] Tambahkan filter type, account, category, dan date range.
- [x] Tampilkan total income dan expense untuk hasil filter.
- [x] Buat detail transaksi dengan aksi Edit dan Delete.
- [x] Tambahkan confirmation dialog/sheet untuk delete.
- [x] Buat no-search-result state.

### 9. Statistics

- [x] Buat month selector.
- [x] Tampilkan summary Income vs Expense.
- [x] Buat donut/bar chart kategori pengeluaran.
- [x] Buat trend pengeluaran per minggu.
- [x] Tampilkan top categories dengan nominal dan persentase.
- [x] Pastikan setiap chart memiliki angka/label sehingga bukan satu-satunya penyampai informasi.
- [x] Buat empty state dan pastikan chart tetap aman ketika data sedikit.

### 10. Accounts detail dan Settings

- [x] Buat account detail dengan transaksi milik akun tersebut.
- [x] Tambahkan pengaturan currency display.
- [x] Tambahkan pilihan Light / Dark / System.
- [x] Tambahkan Manage Categories untuk edit/archive kategori.
- [x] Sediakan Export CSV sebagai stretch goal lokal setelah core flow selesai.
- [x] Tambahkan Delete all data dengan konfirmasi kuat.

### 11. Validasi MVP dan polish terbatas

- [x] Tambahkan test untuk kalkulasi saldo, transfer, filter, dan persistence.
- [x] Jalankan analyzer/test/build Flutter dan perbaiki blocker pertama yang ditemukan.
- [x] Smoke test core flow: buat akun → income/expense → edit/delete → transfer → tutup/buka aplikasi.
- [x] Cek semua state wajib PRD: empty, normal, validation error, no result, delete confirmation, nama panjang, light/dark.
- [x] Cek touch target, safe area, keyboard, overflow, dan scrolling pada small/medium/large phone.
- [x] Lakukan final visual pass pada konsistensi Montserrat, rounded card, shadow/glow, spacing, dan warna.

## 12. UI refinement dan interaction polish (request baru)

### 12.1 Theme, background, dan floating shell

- [x] Ubah pilihan mode tema yang terlihat di Settings menjadi tepat dua opsi: **Light** dan **Dark**; tangani nilai `System` lama dengan fallback yang aman tanpa menampilkannya sebagai opsi baru.
- [x] Revisi token background Light menjadi neutral warm/gray yang sedikit lebih gelap agar card putih terlihat jelas terpisah dari halaman.
- [x] Audit ulang token Dark untuk background, surface/card, text, muted text, border, shadow, accent, income, expense, dan state agar kontras serta hierarki tetap nyaman dibaca.
- [x] Jadikan header/AppBar floating dengan inset dari tepi layar, radius, surface, shadow/elevation, dan safe area yang konsisten.
- [x] Jadikan bottom navigation floating dengan kontrak visual yang sama, tanpa menutup konten, tetap aman terhadap safe area/keyboard, dan tetap mempertahankan state tab aktif.
- [x] Verifikasi floating header, floating bottom bar, spacing, scrolling, dan overflow pada lebar small/medium/large dalam Light dan Dark.

### 12.2 Statistics line chart dan periode waktu

- [x] Ganti chart trend pengeluaran yang saat ini berupa bar chart menjadi line chart yang reusable; chart kategori/donut tetap dipertahankan kecuali ada kebutuhan lanjutan.
- [x] Pisahkan model agregasi data dari painter/widget chart agar pergantian periode tidak mengubah aturan kalkulasi transaksi.
- [x] Tambahkan selector periode **Tahunan**, **Bulanan**, dan **Tanggal** pada area chart.
- [x] Agregasikan periode Tahunan per bulan, periode Bulanan per hari pada bulan terpilih, dan periode Tanggal melalui date picker untuk fokus pada tanggal yang dipilih.
- [x] Tampilkan label sumbu, titik/marker, nilai atau tooltip yang mudah dibaca, serta state aman untuk data kosong, satu titik, nilai nol, 28/29/30/31 hari, dan 12 bulan.
- [x] Pastikan line chart tetap terbaca pada Light/Dark, lebar layar kecil, serta nilai nominal besar; tambahkan test untuk agregasi setiap periode.

### 12.3 Input nominal mata uang

- [x] Buat reusable numeric/currency input formatter yang otomatis memakai pemisah ribuan titik saat mengetik, contoh `1.000.000`, hanya menerima digit, dan menjaga posisi cursor saat insert/delete.
- [x] Terapkan formatter pada amount Add/Edit Transaction dan Opening balance Add/Edit Account, termasuk saat nilai awal form dimuat.
- [x] Normalisasi teks terformat kembali menjadi integer sebelum validasi dan penyimpanan SQLite; simbol `Rp` tetap menjadi prefix/presentasi dan tidak ikut disimpan sebagai nilai.
- [x] Uji nilai kosong, nol, angka kecil, `1.000`, `1.000.000`, penghapusan digit, edit di tengah teks, validasi, dan nilai nominal besar.

### 12.4 Transactions search dan filter modal

- [x] Susun search field dan tombol filter kecil dalam satu baris; tombol filter membuka satu modal filter.
- [x] Pindahkan seluruh filter **Type**, **Account**, **Category**, dan **Date** dari chip inline ke dalam modal tersebut.
- [x] Sediakan apply/close dan Clear all di modal tanpa mengubah aturan filter yang sudah berjalan; tampilkan indikator/count ketika filter aktif.
- [x] Pertahankan hasil filter, total Income/Expense, grouping tanggal, no-result state, dan pencarian setelah layout dipindahkan.
- [x] Pastikan modal filter responsif, dapat discroll, dan konsisten pada Light/Dark serta layar kecil.

### 12.5 Total balance visibility

- [x] Pada section Total Balance, sembunyikan hanya angka nominal menjadi titik-titik/masking; prefix `Rp` tetap terlihat, termasuk penanganan sign bila saldo negatif.
- [x] Jangan ikut menyamarkan label atau nominal Income/Expense yang bukan bagian dari Total Balance kecuali diminta pada batch berikutnya.
- [x] Pertahankan toggle show/hide dan persistensinya; tambahkan test untuk state visible, hidden, perubahan state, dan reload snapshot.

### 12.6 Validasi UI refinement

- [x] Smoke test Light/Dark, floating shell, line chart Tahunan/Bulanan/Tanggal, input nominal terformat, filter modal, dan masking Total Balance pada emulator Android.
- [x] Jalankan `flutter analyze`, `flutter test`, dan `flutter build apk --debug`; perbaiki blocker pertama yang ditemukan.
- [x] Lakukan final visual pass untuk kontras, radius, shadow, safe area, keyboard, cursor input, overflow, dan keterbacaan chart.

## 13. Chart Apex, density system, dan backlog audit (request baru)

Catatan awal: full `flutter test --concurrency=1` pada audit 2026-08-15 belum hijau. `flutter analyze` hijau, test statistik/controller hijau, tetapi full suite masih gagal karena beberapa test harness lama belum mengikuti Riverpod `ProviderScope` dan satu ekspektasi masking balance belum selaras dengan state wrapper test.

### 13.1 Rework chart ke ApexChart

- [x] Audit package chart Flutter yang paling cocok untuk request ApexChart, terutama `apexcharts_flutter`; cek status versi terbaru, lisensi, API, platform support Android/iOS, dan risiko karena package masih early preview/unofficial.
- [x] Tambahkan dependency chart hanya setelah audit singkat selesai; pin versi agar API preview tidak berubah diam-diam.
- [x] Buat wrapper chart reusable, misalnya `FlowApexChartCard` atau `FlowStatisticsChart`, agar konfigurasi Apex tidak tersebar di screen.
- [x] Ganti `Statistics` spending trend dari custom `CustomPainter` (`_LineChartPainter`) ke Apex line/area chart.
- [x] Ganti `Statistics` spending by category dari custom donut painter ke Apex donut/pie chart dengan legend dan label yang lebih rapi.
- [x] Evaluasi `Home` cash-flow chart agar ikut memakai chart reusable; Home tetap ringkas dan tidak berubah menjadi dashboard ramai.
- [x] Pertahankan aturan domain: transfer tidak masuk income/expense, amount tetap positif, dan chart hanya memakai data dari transaksi lokal.
- [x] Pertahankan fallback/empty state ketika data kosong, satu titik, semua nilai nol, atau kategori kosong.

### 13.2 Filter periode chart

- [x] Ubah selector periode statistik menjadi lebih natural untuk personal finance: **Harian**, **Pekanan**, **Bulanan**; pertimbangkan **Tahunan** sebagai mode lanjutan bila tetap dibutuhkan.
- [x] Definisikan default Statistics ke **Pekanan** atau **Bulanan dengan breakdown harian** setelah dibandingkan secara visual; jangan default ke mode yang membuat chart terlalu ramai pada layar kecil.
- [x] Mode Harian: tampilkan transaksi/expense pada tanggal dipilih atau bucket jam sederhana bila data harian cukup.
- [x] Mode Pekanan: tampilkan bucket minggu dalam bulan berjalan atau 7 hari terakhir; ini menjadi kandidat default karena paling mudah dibaca.
- [x] Mode Bulanan: tampilkan bucket bulan untuk tren jangka lebih panjang, idealnya 6-12 bulan.
- [x] Pastikan label sumbu tidak bertumpuk pada small width 320-359dp; gunakan label yang disingkat dan tick yang dipilih otomatis.
- [x] Tambahkan tooltip/value formatter Rupiah yang ringkas, contoh `Rp 1,2 jt` untuk axis dan nilai penuh di tooltip/detail.
- [x] Tambahkan test agregasi untuk Harian, Pekanan, Bulanan, batas bulan, minggu lintas bulan, dan data tanpa transaksi.

### 13.3 Design density contract

- [x] Revisi design token spacing agar card tidak terlalu tinggi dan konten tidak terasa terhimpit.
- [x] Tetapkan tiga density variant untuk `FlowCard`:
  - [x] `compact`: padding 12-14dp untuk summary kecil, list compact, dan filter/action item.
  - [x] `standard`: padding 16dp untuk transaksi, account item, settings row, dan card umum.
  - [x] `featured`: padding 18-20dp maksimal untuk Total Balance dan chart utama.
- [x] Hindari padding 24dp ke atas pada mobile kecuali empty state atau form section yang benar-benar membutuhkan ruang.
- [x] Tetapkan gap internal card: 4dp untuk label-detail dekat, 8dp untuk item satu grup, 12dp untuk blok berbeda, 16dp hanya untuk pemisah antar section penting.
- [x] Audit `FlowSpacing`, `FlowRadii`, `FlowControlSize`, dan `FlowCardVariant` supaya spacing tidak perlu di-hardcode berulang di screen.
- [x] Pastikan nested card tidak digunakan untuk layout biasa; card hanya untuk item berulang, summary, chart, modal/content container yang memang butuh frame.

### 13.4 Typography scale dan hierarchy

- [x] Turunkan ukuran font default yang terlalu besar pada card kecil.
- [x] Tetapkan skala praktis:
  - [x] label/caption 11-12sp, medium weight.
  - [x] body/list title 13-14sp.
  - [x] section title 15-16sp.
  - [x] amount kecil 15-17sp.
  - [x] Total Balance utama 24-28sp.
- [x] Batasi pemakaian `titleLarge`, `headlineSmall`, dan `displaySmall` hanya untuk elemen utama; jangan dipakai di semua nominal/card.
- [x] Pastikan angka uang memakai tabular numerals bila memungkinkan dan tetap aman untuk nominal besar.
- [x] Terapkan `maxLines`, `overflow`, `FittedBox`, atau `Flexible` secara konsisten pada nominal, nama akun, nama kategori, dan metadata transaksi.

### 13.5 Layout hygiene per card/container

- [x] Tetapkan struktur minimum card: header kecil, body utama, metadata/footer bila diperlukan.
- [x] Pastikan setiap card hanya punya satu visual focus; jangan mencampur nominal besar, chart, legend, action, dan copy panjang dalam satu blok tanpa hierarchy.
- [x] Rapikan `Home` Total Balance, Income/Expense summary, Cash flow, dan Recent Transactions agar tinggi card proporsional dengan konten.
- [x] Rapikan `Transactions` total cards, search/filter row, dan transaction list agar nominal tidak menekan teks.
- [x] Rapikan `Statistics` summary, chart, legend, dan top categories setelah pindah ke ApexChart.
- [x] Rapikan `Accounts` card agar nama akun panjang, saldo, dan archive icon tidak saling menekan.
- [x] Rapikan `Settings` selector/action rows agar button dan label tidak terasa oversized.
- [x] Verifikasi small/medium/large phone widths dalam Light dan Dark untuk overflow, clipped text, touch target, keyboard, dan safe area.

### 13.6 Riverpod cleanup dan test recovery

- [x] Selesaikan sisa `RIVERPOD_MIGRATION_TODO.md` atau sinkronkan ulang bila scope berubah.
- [x] Kurangi callback/props drilling di `FlowShell` untuk data global yang sudah bisa dibaca via provider.
- [x] Update widget test lama agar membungkus `FlowApp` dengan `ProviderScope` atau memakai constructor override store yang valid.
- [x] Perbaiki test masking Total Balance agar benar-benar mengubah state wrapper atau uji dari store/provider yang persisten.
- [x] Jalankan `flutter analyze`.
- [x] Jalankan `flutter test --concurrency=1` sampai full suite hijau.
- [x] Jalankan `flutter build apk --debug` dan catat blocker environment secara spesifik bila Flutter CLI/lockfile bermasalah.

### 13.7 Product polish backlog dari audit

- [x] Update `README.md` dari template Flutter menjadi dokumentasi proyek Flow: fitur, setup, arsitektur singkat, test command, dan screenshot/recording bila tersedia.
- [x] Tambahkan akses untuk melihat dan restore archived account; saat ini archive menyembunyikan akun aktif tetapi tidak ada restore surface yang jelas.
- [x] Pertimbangkan Import CSV agar Export CSV tidak menjadi satu arah saja.
- [x] Pertimbangkan backup/restore lokal sebagai fitur V2 ringan tanpa cloud sync.
- [x] Pertahankan batas MVP: jangan menambah login, cloud sync, koneksi bank/e-wallet, OCR, AI, investasi, atau payment gateway tanpa request eksplisit.

## 14. Rekomendasi fitur tambahan berikutnya

Catatan: section ini adalah backlog baru setelah seluruh task sebelumnya selesai. Implementasikan bertahap dan tetap mengikuti `design-system.md`.

### 14.1 Import CSV

- [x] Buat alur Import CSV yang kompatibel dengan format Export CSV saat ini.
- [x] Tambahkan preview sebelum import: jumlah transaksi, akun/kategori yang cocok, dan baris yang error.
- [x] Tangani duplikasi transaksi dengan aturan deterministic, misalnya kombinasi tanggal, amount, type, account, category, dan note.
- [x] Sediakan hasil import ringkas: berhasil, dilewati, dan gagal.

### 14.2 Backup dan restore lokal

- [ ] Buat export backup lokal satu file yang berisi accounts, categories, transactions, dan settings.
- [ ] Buat restore backup dengan preview dampak sebelum menimpa data lokal.
- [ ] Tambahkan konfirmasi kuat untuk restore karena operasi ini dapat mengganti data aktif.
- [ ] Pertahankan tanpa cloud sync; file tetap dikelola user secara lokal.

### 14.3 Recurring transaction templates

- [ ] Tambahkan template transaksi berulang untuk gaji, tagihan, langganan, dan transfer rutin.
- [ ] Sediakan frekuensi sederhana: weekly, monthly, dan custom day-of-month.
- [ ] Buat generated transaction tetap editable dan tidak otomatis masuk income/expense sampai user mengonfirmasi.
- [ ] Tampilkan reminder ringkas di Home tanpa membuat dashboard ramai.

### 14.4 Budget bulanan per kategori

- [ ] Tambahkan budget bulanan opsional untuk kategori expense.
- [ ] Tampilkan progress budget di Statistics dan Home secara compact.
- [ ] Beri status aman/perhatian/melebihi budget dengan warna semantic yang sudah ada.
- [ ] Pastikan budget tidak mengubah transaksi atau saldo.

### 14.5 Savings goals

- [ ] Tambahkan goal tab atau section ringan untuk target tabungan manual.
- [ ] Hubungkan goal ke akun opsional tanpa membuat rekening virtual baru.
- [ ] Tampilkan progress berdasarkan saldo akun yang dipilih atau input kontribusi manual.
- [ ] Jaga scope tetap personal tracking, bukan investasi atau payment flow.

## Di luar scope prototype awal

- Budget, recurring transactions, saving goals, receipt attachment, backup/restore, biometric lock, multi-currency conversion, dan cloud sync.
- Login, koneksi bank/e-wallet, OCR struk, AI, investasi, hutang/piutang kompleks, subscription, dan payment gateway.
- Animasi kompleks, ilustrasi dekoratif, serta perubahan layout menjadi desktop dashboard.

## Definition of Done MVP

- [x] User dapat membuat akun dan mencatat income/expense secara offline.
- [x] Total balance dan saldo akun konsisten setelah create/edit/delete.
- [x] Transfer tidak masuk ke income/expense.
- [x] Transactions dan Statistics mendukung filter/pemahaman data dasar.
- [x] Data tetap ada setelah aplikasi ditutup dan dibuka kembali.
- [x] Core flow usable pada small, medium, dan large phone widths.
- [x] Visual mengikuti arah desain dan menggunakan Montserrat.
