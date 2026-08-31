# Flow Testing Scheme

Dokumen ini menjadi skema pengujian untuk backlog TODO 14.2-14.5: backup/restore lokal, recurring templates, monthly budgets, dan savings goals.

## 1. Pengujian Kode

Jalankan command berikut secara berurutan, tanpa menjalankan command Flutter lain di checkout yang sama:

```powershell
flutter analyze
flutter test --concurrency=1 test\flow_store_test.dart test\planning_features_test.dart
flutter test --concurrency=1
flutter build apk --debug
```

Coverage utama:

- `test/flow_store_test.dart`: membuktikan data core dan planning tersimpan di SQLite, tetap ada setelah close/reopen, lalu bisa dihapus.
- `test/planning_features_test.dart`: membuktikan memory store menyimpan planning snapshot dan backup JSON bisa encode, preview, decode.
- Full `flutter test --concurrency=1`: regresi seluruh flow MVP, CSV import/export, Riverpod shell, UI refinement, dan data layer.

## 2. Pengujian Flow Manual

Backup dan export laporan:

1. Buka `Home > Reports`.
2. Pilih `Export monthly CSV` dan pastikan sheet hasil export menampilkan nama serta path file.
3. Pilih `Open file` dan pastikan CSV dibuka oleh aplikasi yang sesuai.
4. Export ulang, pilih `Choose file location`, lalu simpan ke folder yang dipilih melalui file manager.
5. Pastikan salinan CSV dapat ditemukan di folder tersebut.
6. Pilih `Export database backup` dan ulangi pemeriksaan `Open file` serta `Choose file location` untuk file `flow-backup-*.json`.
7. Pastikan backup tetap bisa di-preview oleh `FlowBackupCodec` dan menampilkan jumlah accounts, categories, transactions, recurring, budgets, goals, serta currency.
8. Pastikan pemilihan lokasi yang dibatalkan tidak menghapus file export asli atau mengubah data aplikasi.

Recurring templates:

1. Buka tab `Plans`.
2. Tambah template expense/income/transfer.
3. Isi amount, akun, kategori atau destination account, frekuensi weekly/monthly, dan note opsional.
4. Simpan template.
5. Pastikan template muncul di `Plans`.
6. Pilih `Review`.
7. Pastikan form Add Transaction terbuka dengan data dari template.
8. Simpan transaksi hanya jika user memang mengonfirmasi.
9. Pastikan Home menampilkan reminder ringkas jumlah template aktif.

Monthly budgets:

1. Buka tab `Plans`.
2. Tambah budget untuk kategori expense bulan berjalan.
3. Simpan budget.
4. Catat transaksi expense pada kategori yang sama.
5. Pastikan progress budget muncul di `Plans`, `Home`, dan `Statistics`.
6. Uji status:
   - Aman: spent <= 80% dari budget.
   - Perhatian: spent > 80% dan <= 100%.
   - Melebihi: spent > 100%.
7. Pastikan budget tidak mengubah total balance, saldo akun, income, atau expense selain sebagai tampilan progress.

Savings goals:

1. Buka tab `Plans`.
2. Tambah savings goal manual tanpa akun.
3. Isi target amount dan manual contribution.
4. Pastikan progress memakai manual contribution.
5. Tambah savings goal dengan linked account.
6. Pastikan progress memakai saldo akun terpilih ditambah manual contribution.
7. Pastikan tidak ada virtual account baru yang dibuat.

## 3. Struktur Data Database

Tabel lama tetap dipertahankan:

- `accounts`: akun user, termasuk `opening_balance`, `is_archived`, `created_at`, `updated_at`.
- `categories`: kategori income/expense, termasuk kategori default dan archived.
- `transactions`: transaksi income, expense, transfer; amount selalu positif.
- `app_settings`: currency, theme mode, dan hide balance.

Tabel baru SQLite v2:

- `recurring_templates`
  - `id`, `name`, `transaction_type`, `amount`
  - `account_id`, `destination_account_id`, `category_id`
  - `note`, `frequency`, `day_of_month`, `weekday`
  - `is_archived`, `created_at`, `updated_at`
- `monthly_budgets`
  - `id`, `category_id`, `month`, `amount`
  - `created_at`, `updated_at`
  - `UNIQUE(category_id, month)`
- `savings_goals`
  - `id`, `name`, `target_amount`, `account_id`
  - `manual_contribution`, `is_archived`
  - `created_at`, `updated_at`

Relasi penting:

- Template dan budget dapat menunjuk kategori existing.
- Template transfer dapat menunjuk destination account.
- Savings goal dapat menunjuk account existing, tetapi tidak membuat rekening virtual.
- Foreign key memakai `RESTRICT` untuk akun template/transaksi dan `SET NULL` untuk kategori/goal yang opsional.

## 4. Struktur File Backup

Backup lokal berupa JSON dengan struktur:

```json
{
  "schema": "flow.local-backup",
  "version": 1,
  "exported_at": "2026-08-17T00:00:00.000Z",
  "accounts": [],
  "categories": [],
  "transactions": [],
  "settings": {},
  "recurring_templates": [],
  "monthly_budgets": [],
  "savings_goals": []
}
```

Restore hanya menerima `schema = flow.local-backup` dan `version = 1`. Restore mengganti semua data lokal: accounts, categories, transactions, settings, templates, budgets, dan goals.

## 5. Pengujian Data Masuk Database

Verifikasi otomatis:

- `SqliteFlowStore.saveRecurringTemplate()` insert/update ke `recurring_templates`.
- `SqliteFlowStore.saveMonthlyBudget()` insert/update ke `monthly_budgets`.
- `SqliteFlowStore.saveSavingsGoal()` insert/update ke `savings_goals`.
- Setelah `close()` dan `open()` ulang, `FlowSnapshot` tetap berisi data yang sama.

Verifikasi manual opsional dengan SQLite browser:

1. Jalankan app dan buat minimal satu template, satu budget, dan satu goal.
2. Buka file database `flow.db` dari documents/databases aplikasi.
3. Query:

```sql
SELECT * FROM recurring_templates;
SELECT * FROM monthly_budgets;
SELECT * FROM savings_goals;
```

Ekspektasi:

- Row template berisi amount positif, account_id valid, frequency `weekly` atau `monthly`.
- Row budget berisi month format `YYYY-MM`, category_id kategori expense, dan amount positif.
- Row savings goal berisi target_amount positif, manual_contribution >= 0, dan account_id nullable.
