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

- [x] Buat export backup lokal satu file yang berisi accounts, categories, transactions, dan settings.
- [x] Buat restore backup dengan preview dampak sebelum menimpa data lokal.
- [x] Tambahkan konfirmasi kuat untuk restore karena operasi ini dapat mengganti data aktif.
- [x] Pertahankan tanpa cloud sync; file tetap dikelola user secara lokal.

### 14.3 Recurring transaction templates

- [x] Tambahkan template transaksi berulang untuk gaji, tagihan, langganan, dan transfer rutin.
- [x] Sediakan frekuensi sederhana: weekly, monthly, dan custom day-of-month.
- [x] Buat generated transaction tetap editable dan tidak otomatis masuk income/expense sampai user mengonfirmasi.
- [x] Tampilkan reminder ringkas di Home tanpa membuat dashboard ramai.

### 14.4 Budget bulanan per kategori

- [x] Tambahkan budget bulanan opsional untuk kategori expense.
- [x] Tampilkan progress budget di Statistics dan Home secara compact.
- [x] Beri status aman/perhatian/melebihi budget dengan warna semantic yang sudah ada.
- [x] Pastikan budget tidak mengubah transaksi atau saldo.

### 14.5 Savings goals

- [x] Tambahkan goal tab atau section ringan untuk target tabungan manual.
- [x] Hubungkan goal ke akun opsional tanpa membuat rekening virtual baru.
- [x] Tampilkan progress berdasarkan saldo akun yang dipilih atau input kontribusi manual.
- [x] Jaga scope tetap personal tracking, bukan investasi atau payment flow.

## 15. Redesign planning, laporan, dan backup export (request baru)

Catatan arah produk: fitur import dan restore tidak menjadi menu utama. Fokus user-facing adalah export laporan dan export backup. Import/restore boleh tetap ada sebagai utilitas internal/lanjutan bila dibutuhkan, tetapi jangan ditonjolkan di Home atau alur utama karena dapat membingungkan dan restore berisiko menimpa data.

### 15.1 Top title / appbar ringan

- [x] Tambahkan judul kecil di tengah/top appbar untuk semua menu utama kecuali Home.
- [x] Pertahankan Home tanpa appbar karena sudah memiliki greeting dan identitas dashboard sendiri.
- [x] Pastikan ukuran font title tidak terlalu besar dan konsisten dengan typography scale di `design-system.md`.
- [x] Cek safe area, bottom navigation, dan scroll padding agar judul tidak menimpa konten pada layar kecil.
- [x] Batasi bottom navigation menjadi 5 item: `Home`, `Transactions`, `Statistics`, `Accounts`, dan `Settings`.
- [x] Hapus item bottom navigation `Plans` karena `Recurring templates`, `Monthly budgets`, dan `Savings goals` sudah keluar menjadi halaman sendiri dari Home quick menu.
- [x] Jangan tambahkan bottom navigation baru untuk `Reports`, bills, debt/receivables, tags, atau budget alerts.

### 15.2 Home quick menu grid 4

- [x] Hapus total card ringkasan Income dan Expense dari Home.
- [x] Tambahkan grid 4 kotak menu tambahan di Home: `Recurring templates`, `Monthly budgets`, `Savings goals`, dan `Reports`.
- [x] Setiap kotak harus memakai icon, label pendek, dan state count/progress ringkas bila relevan tanpa membuat Home terlalu ramai.
- [x] Klik `Recurring templates` membuka halaman khusus template transaksi rutin.
- [x] Klik `Monthly budgets` membuka halaman khusus budget bulanan.
- [x] Klik `Savings goals` membuka halaman khusus target tabungan.
- [x] Klik `Reports` membuka halaman laporan dan export.
- [x] Verifikasi grid tetap rapi pada small/medium/large phone widths dan Light/Dark.

### 15.3 Recurring templates sebagai halaman khusus

- [x] Pisahkan section recurring dari `PlansPage` menjadi halaman/list khusus.
- [x] Jelaskan alur produk sebagai template transaksi rutin, bukan transaksi otomatis yang langsung mengubah saldo.
- [x] Pertahankan aksi `Review`/buat transaksi dari template supaya transaksi tetap dikonfirmasi user sebelum masuk income/expense/transfer.
- [x] Tambahkan detail item recurring yang menampilkan metadata template dan riwayat transaksi yang dibuat dari template bila sudah tersedia penanda relasi.
- [x] Jika belum ada field relasi template di transaksi, tentukan migration/model yang aman sebelum menampilkan riwayat berbasis relasi.

### 15.4 Monthly budgets sebagai halaman khusus

- [x] Pisahkan section monthly budgets dari `PlansPage` menjadi halaman/list khusus.
- [x] Detail budget menampilkan kategori, bulan, limit, spent, remaining/over, dan list transaksi expense yang masuk kategori/bulan tersebut.
- [x] Perbaiki progress bar budget: track abu-abu, progress hijau, rounded kiri-kanan.
- [x] Saat spent melewati budget, tampilkan bagian over budget berwarna merah di atas progress penuh hijau atau dengan indikator merah yang jelas.
- [x] Pastikan budget tetap read-only terhadap saldo: budget hanya membaca transaksi expense, tidak membuat/mengubah transaksi.
- [x] Tambahkan test kalkulasi spent, remaining, over budget, dan progress rendering state normal/over.

### 15.5 Savings goals dengan tambah nominal

- [x] Pisahkan section savings goals dari `PlansPage` menjadi halaman/list khusus.
- [x] Detail goal menampilkan target, current amount, remaining amount, progress rounded, dan status selesai bila target tercapai.
- [x] Tambahkan aksi `Add contribution` untuk menambah nominal ke goal yang sudah ada.
- [x] Untuk tahap awal, contribution boleh menambah `manualContribution`; untuk riwayat yang rapi, tambahkan model/table kontribusi goal sebelum menampilkan list kontribusi.
- [x] Jika goal terhubung ke akun, pastikan copy UI membedakan saldo akun dan kontribusi manual agar progress tidak terasa seperti transaksi ganda.
- [x] Detail goal menampilkan list kontribusi/aktivitas yang tercatat setelah struktur datanya tersedia.
- [x] Tambahkan test untuk create goal, add contribution, progress, goal linked account, dan archive/delete behavior.

### 15.6 Reports

- [x] Buat halaman `Reports` dari quick menu Home.
- [x] Tambahkan filter bulan/tahun sebagai periode laporan default.
- [x] Tampilkan ringkasan sebelum download: total income, total expense, net cash flow, transfer count/amount, top expense categories, dan jumlah transaksi.
- [x] Sediakan export CSV bulanan yang rapi dengan header konsisten, transaksi terurut, escaping koma/kutip/newline, dan nama file berisi periode.
- [ ] Sediakan export PDF bulanan yang rapi dan mudah dibaca: judul laporan, periode, ringkasan, tabel transaksi, dan footer tanggal export.
- [ ] Pastikan PDF aman untuk nominal panjang, kategori/note panjang, multi-page, Light/Dark source data, dan data kosong.
- [ ] Tambahkan test unit untuk builder data laporan, CSV output, dan minimal golden/source check untuk PDF bila tooling tersedia.

### 15.7 Backup export-only

- [x] Pindahkan `Export local backup` ke halaman `Reports` dalam section berbeda bernama backup/cadangan data.
- [x] Jangan tampilkan `Restore local backup` sebagai aksi utama di Home atau laporan.
- [x] Pertahankan format backup sebagai cadangan seluruh data lokal, berbeda dari CSV laporan transaksi.
- [x] Tampilkan copy singkat bahwa backup dipakai untuk menyimpan cadangan data aplikasi, bukan laporan keuangan.
- [x] Pastikan nama file backup jelas dan berisi timestamp.

### 15.8 Settings cleanup

- [ ] Hapus atau sembunyikan `Import CSV` dari menu utama Settings.
- [ ] Hapus atau sembunyikan `Restore local backup` dari menu utama Settings, atau pindahkan ke area advanced/danger bila masih ingin dipertahankan untuk recovery.
- [ ] Kurangi Settings menjadi pengaturan aplikasi: theme, currency, categories, dan danger zone.
- [ ] Update README agar alur export laporan dan backup sesuai struktur baru.

### 15.9 Validasi akhir batch

- [x] Jalankan `flutter analyze`.
- [x] Jalankan test terkait planning, laporan, CSV, backup, dan widget navigation.
- [x] Jalankan `flutter test --concurrency=1` bila environment memungkinkan.
- [x] Jalankan `flutter build apk --debug`.
- [ ] Lakukan visual pass pada Home grid, halaman detail planning, progress bar, laporan PDF/CSV, dan judul menu di Light/Dark serta layar kecil.

## 16. Fitur tambahan tanpa menambah bottom navigation

Catatan arah UX: fitur tambahan ini harus masuk sebagai bagian dari alur yang sudah ada, bukan sebagai tab bottom navigation baru. Entry point utama tetap melalui Home, Transactions, Monthly budgets, Recurring templates, Savings goals, Reports, atau Settings sesuai konteksnya.

### 16.1 Bills / Upcoming

- [ ] Buat surface `Upcoming` yang menampilkan transaksi rutin yang akan jatuh tempo dari `Recurring templates`.
- [ ] Entry point utama berasal dari Home sebagai ringkasan kecil atau dari halaman `Recurring templates`, bukan bottom navigation baru.
- [ ] Tampilkan item upcoming dengan nama, tipe, nominal, akun, kategori/tujuan transfer, tanggal jatuh tempo, dan status due/overdue.
- [ ] Sediakan aksi `Review transaction` untuk membuat transaksi dari template; saldo tetap tidak berubah sebelum user menyimpan transaksi.
- [ ] Hindari istilah yang mengesankan auto-debit penuh bila sistem masih meminta konfirmasi manual.
- [ ] Tambahkan state empty, due soon, overdue, dan completed/created bila relasi transaksi-template sudah tersedia.
- [ ] Pastikan card upcoming compact, mudah dipindai, dan tidak membuat Home kembali ramai.

### 16.2 Debt & Receivables

- [ ] Tambahkan model sederhana untuk hutang/piutang: nama pihak, tipe `Debt`/`Receivable`, nominal awal, nominal terbayar, due date opsional, note, status, createdAt, updatedAt.
- [ ] Letakkan entry point di Home sebagai shortcut sekunder atau di Reports/Transactions context, bukan bottom navigation baru.
- [ ] Buat halaman list dengan filter `All`, `Debt`, `Receivable`, `Open`, dan `Settled`.
- [ ] Detail item menampilkan progress pembayaran, sisa nominal, timeline pembayaran, dan aksi `Add payment`.
- [ ] Saat `Add payment`, tentukan jelas apakah hanya mencatat progress manual atau juga membuat transaksi expense/income/transfer; jangan membuat transaksi ganda tanpa konfirmasi user.
- [ ] Tampilkan warning/copy singkat bahwa fitur ini adalah pencatatan pribadi, bukan pinjaman/investasi/payment gateway.
- [ ] Tambahkan test untuk create, add payment, settle, overdue, dan kalkulasi remaining.

### 16.3 Notes / Tags

- [ ] Tambahkan dukungan tag ringan pada transaksi tanpa mengubah kategori utama.
- [ ] Sediakan input tag di Add/Edit Transaction dengan chip sederhana dan validasi panjang nama tag.
- [ ] Tampilkan tag di Transaction detail dan optional chip kecil di list bila ruang cukup.
- [ ] Tambahkan filter tag di modal filter Transactions.
- [ ] Reports CSV/PDF harus menyertakan kolom/area tags agar hasil export tetap lengkap.
- [ ] Pastikan tag tidak menggantikan kategori dan tidak mengubah kalkulasi income/expense/budget.
- [ ] Tambahkan test untuk create/edit transaction dengan tags, filter tags, export CSV, dan backup.

### 16.4 Budget Alerts

- [ ] Tambahkan alert budget lokal untuk threshold 80%, 100%, dan over budget.
- [ ] Entry point konfigurasi alert berada di detail `Monthly budgets` atau Settings advanced, bukan bottom navigation baru.
- [ ] Tampilkan alert secara visual di Home/Monthly budgets dengan state attention/over memakai warna semantic yang sudah ada.
- [ ] Jika memakai notifikasi device, minta permission secara eksplisit dan tetap sediakan fallback in-app alert bila permission ditolak.
- [ ] Hindari spam: satu alert per budget per threshold per bulan kecuali user mengubah budget/transaksi.
- [ ] Pastikan alert tidak mengubah transaksi, saldo, atau budget; alert hanya membaca progress.
- [ ] Tambahkan test untuk threshold 80%, 100%, over budget, reset bulan baru, dan perubahan budget.

### 16.5 UX/UI guardrail fitur tambahan

- [ ] Semua fitur tambahan harus memakai component existing (`FlowCard`, `FlowButton`, `FlowSelector`, `FlowSegmentedControl`, `FlowTransactionTile`) sebelum membuat component baru.
- [ ] Gunakan appbar/title kecil yang konsisten untuk halaman fitur baru.
- [ ] Jangan memakai card bertingkat; halaman list memakai item card tunggal atau section datar.
- [ ] Pastikan copy tetap pendek, action jelas, dan empty state memberi next action yang relevan.
- [ ] Verifikasi Light/Dark, small/medium/large widths, long names, large amounts, keyboard, dan scroll safe area.
- [ ] Update README dan test coverage setelah fitur tambahan dipilih untuk implementasi.

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
