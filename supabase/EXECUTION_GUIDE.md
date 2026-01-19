# 🚀 Panduan Eksekusi SQL di Supabase

## 📋 **FILE YANG HARUS DIJALANKAN (URUTAN PENTING!)**

Hanya ada **4 file SQL** yang perlu dijalankan di Supabase SQL Editor. Jalankan sesuai urutan berikut:

---

### **1️⃣ PERTAMA: `01_base_schema.sql`**
**Apa yang dilakukan:**
- Membuat struktur database dasar (core tables)
- Tables: profiles, outlets, employees, shifts, products, inventory, transactions, bookings, expenses
- RLS policies untuk semua table
- Trigger untuk updated_at
- Data awal (categories)

**Cara menjalankan:**
1. Buka Supabase Dashboard → SQL Editor
2. Copy-paste isi file `01_base_schema.sql`
3. Klik **Run** atau tekan `Ctrl + Enter`
4. ✅ Pastikan muncul "Success. No rows returned"

---

### **2️⃣ KEDUA: `02_warehouse_system.sql`**
**Apa yang dilakukan:**
- Sistem Warehouse Management lengkap
- Tables: warehouses, warehouse_inventory, suppliers, purchase_orders, stock_transfer_orders, stock_opname, daily_closing_reports
- Functions untuk auto-update inventory setelah PO received & stock transfer
- RLS policies untuk warehouse

**Cara menjalankan:**
1. Di SQL Editor yang sama
2. Copy-paste isi file `02_warehouse_system.sql`
3. Klik **Run**
4. ✅ Pastikan semua table berhasil dibuat

**⚠️ DEPENDENCY:** File ini butuh table dari `01_base_schema.sql` (products, outlets, profiles)

---

### **3️⃣ KETIGA: `03_multi_payment_system.sql`**
**Apa yang dilakukan:**
- Sistem Multi-Payment (7 metode pembayaran)
- Table: transaction_payments
- Alter table transactions (tambah kolom payment_status, total_paid, remaining_amount)
- Functions untuk auto-calculate payment status
- Functions untuk cash deposit calculation
- Data migration (migrate existing payment_method ke transaction_payments)

**Cara menjalankan:**
1. Di SQL Editor yang sama
2. Copy-paste isi file `03_multi_payment_system.sql`
3. Klik **Run**
4. ✅ Pastikan ALTER TABLE berhasil dan views dibuat

**⚠️ DEPENDENCY:** File ini butuh table `transactions` dari `01_base_schema.sql`

---

### **4️⃣ KEEMPAT: `04_hr_attendance_incentives.sql`**
**Apa yang dilakukan:**
- Sistem HR Attendance (auto dari shift) & Sales Incentives
- Tables: attendance, sales_targets, employee_incentives
- Alter table employees (tambah kolom payroll)
- Functions untuk:
  - Auto-create attendance dari shift
  - Calculate work hours & overtime
  - Calculate employee incentives otomatis setelah penjualan
- Views untuk attendance summary & employee performance

**Cara menjalankan:**
1. Di SQL Editor yang sama
2. Copy-paste isi file `04_hr_attendance_incentives.sql`
3. Klik **Run**
4. ✅ Pastikan semua triggers & functions berhasil dibuat

**⚠️ DEPENDENCY:** File ini butuh table `employees`, `shifts`, `transactions` dari `01_base_schema.sql`

---

## ✅ **VERIFIKASI SETELAH EKSEKUSI**

### Cek apakah semua table berhasil dibuat:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

### Expected result (30 tables):
```
✅ attendance
✅ bookings
✅ categories
✅ daily_closing_reports
✅ employee_incentives
✅ employees
✅ expenses
✅ inventory
✅ inventory_transactions
✅ outlets
✅ products
✅ profiles
✅ purchase_order_items
✅ purchase_orders
✅ sales_targets
✅ shifts
✅ stock_opname
✅ stock_opname_items
✅ stock_transfer_items
✅ stock_transfer_orders
✅ suppliers
✅ transaction_items
✅ transaction_payments
✅ transactions
✅ user_outlets
✅ warehouse_inventory
✅ warehouses
```

### Cek RLS policies:
```sql
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

### Cek Functions:
```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_type = 'FUNCTION'
ORDER BY routine_name;
```

---

## ⚠️ **TROUBLESHOOTING**

### ❌ Error: "relation does not exist"
**Penyebab:** Urutan eksekusi salah atau file sebelumnya belum dijalankan
**Solusi:** Jalankan ulang dari `01_base_schema.sql` sampai selesai

### ❌ Error: "column already exists"
**Penyebab:** File sudah pernah dijalankan sebelumnya
**Solusi:** Skip error ini atau gunakan `DROP TABLE IF EXISTS` untuk reset

### ❌ Error: "type already exists"
**Penyebab:** Enum type sudah dibuat sebelumnya
**Solusi:** Skip error atau drop type dengan `DROP TYPE IF EXISTS`

---

## 🗑️ **JIKA INGIN RESET DATABASE (HATI-HATI!)**

```sql
-- PERINGATAN: Ini akan menghapus SEMUA data!
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
```

Setelah itu jalankan lagi 4 file SQL dari awal.

---

## 📊 **SUMMARY**

| No | File | Tabel Dibuat | Fungsi Utama |
|----|------|--------------|--------------|
| 1 | `01_base_schema.sql` | 13 tables | Core ERP foundation |
| 2 | `02_warehouse_system.sql` | 9 tables | Warehouse & inventory flow |
| 3 | `03_multi_payment_system.sql` | 1 table + alter | Multi-payment system |
| 4 | `04_hr_attendance_incentives.sql` | 3 tables + alter | HR automation |
| **TOTAL** | **4 files** | **27 tables** | **Complete Veroprise ERP** |

---

## 🎉 **SETELAH SEMUA BERHASIL**

1. ✅ Database schema siap digunakan
2. ✅ Frontend components (14 React files) sudah siap di `src/components/`
3. ✅ Type definitions (3 files) sudah ada di `src/types/`
4. ✅ Custom hooks (useMultiPayment.ts) sudah siap
5. ✅ Tinggal test di frontend dan sesuaikan API calls

**Next steps:**
- Test login & authentication
- Test create outlet & products
- Test POS dengan multi-payment
- Test warehouse flow (PO → Transfer → Opname)
- Test HR attendance & incentives

---

**PENTING:** Jangan jalankan file SQL lain yang ada di folder `supabase/` selain 4 file di atas! File-file lama sudah tidak relevan dan akan menyebabkan konflik.
