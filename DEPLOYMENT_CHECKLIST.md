# DEPLOYMENT CHECKLIST
## Veroprise - Procurement and Logistics Stack

Last updated: 2026-04-06

## A. Pre-Deployment

- [ ] Supabase project baru siap
- [ ] URL dan key publishable/anon sudah benar di barberdoc_erp/.env
- [ ] service role tidak disimpan di env frontend
- [ ] dependency frontend sudah terinstall

## B. SQL Deployment Order (Mandatory)

Jalankan di Supabase SQL Editor berurutan:

- [ ] 1. barberdoc_erp/supabase/complete_schema.sql
- [ ] 2. barberdoc_erp/supabase/postgresql_procurement_schema.sql
- [ ] 3. barberdoc_erp/supabase/postgresql_auth_profile_trigger.sql
- [ ] 4. barberdoc_erp/supabase/postgresql_backfill_profiles.sql
- [ ] 5. barberdoc_erp/supabase/ASSIGN_NEW_OWNER.sql

## C. SQL Verification

### C1. Trigger auth profile aktif

```sql
select trigger_name, event_object_table
from information_schema.triggers
where event_object_schema = 'auth'
  and event_object_table = 'users'
  and trigger_name = 'on_auth_user_created';
```

- [ ] result muncul 1 row

### C2. Tidak ada auth user tanpa profile

```sql
select u.id, u.email
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null;
```

- [ ] result 0 row

### C3. Procurement tables tersedia

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in (
    'procurement_user_roles',
    'material_requests',
    'material_request_items',
    'stock_receipts',
    'stock_receipt_items',
    'stock_adjustments',
    'stock_adjustment_items',
    'delivery_documents',
    'delivery_document_items',
    'daily_stock_audits',
    'daily_stock_audit_items',
    'warehouse_stock_movements'
  )
order by table_name;
```

- [ ] semua tabel muncul

## D. Frontend Deployment

- [ ] jalankan npm run dev di barberdoc_erp
- [ ] login owner berhasil
- [ ] tambah user baru tidak mengganti session user aktif
- [ ] role user bisa terbaca dari public.profiles

## E. Operational Smoke Test

- [ ] input role procurement_user_roles untuk user uji
- [ ] insert stock receipt uji
- [ ] insert stock adjustment uji
- [ ] insert daily stock audit uji
- [ ] insert delivery document uji

## F. Known Gaps (Post-Deployment Work)

- [ ] role UI masih legacy, belum role procurement
- [ ] halaman warehouse perlu align ke nama tabel schema aktif
- [ ] print surat jalan dan tanda terima belum final dari workflow delivery document

## G. Go-Live Decision

Production dapat jalan untuk validasi database dan proses SQL-driven procurement.
Untuk operasional user non-teknis penuh, lanjutkan penyelesaian gap di bagian F.
