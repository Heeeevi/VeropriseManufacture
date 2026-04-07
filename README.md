# Veroprise Hybrid ERP Workspace

Monorepo ini berisi dua bagian utama:

- Frontend React + Vite di folder `barberdoc_erp` untuk Veroprise ERP.
- Backend Express (legacy/hybrid) di root folder untuk endpoint operasional tambahan.

Fokus pengembangan saat ini: logistik dan procurement dengan basis Supabase PostgreSQL, tetap mempertahankan beberapa modul legacy agar transisi berjalan aman.

## Struktur Singkat

```text
.
├── barberdoc_erp/                # Frontend utama Veroprise ERP
│   ├── src/
│   └── supabase/                 # SQL schema, migration, dan panduan eksekusi
├── src/                          # Backend Express (hybrid)
├── public/                       # Asset root/legacy
└── package.json                  # Backend package manifest
```

## Jalankan Frontend

```bash
cd barberdoc_erp
npm install
npm run dev
```

## Jalankan Backend Root

```bash
npm install
npm start
```

## Setup Database Supabase

1. Buka SQL Editor pada project Supabase.
2. Jalankan schema utama yang sudah tersedia di folder `barberdoc_erp/supabase`.
3. Untuk modul logistik/procurement terbaru, jalankan file:

```text
barberdoc_erp/supabase/postgresql_procurement_schema.sql
```

4. Isi environment frontend pada file `.env` di folder `barberdoc_erp`.

## Catatan Keamanan

- Jangan commit `service_role` key ke repository.
- Selalu gunakan secret manager deployment untuk key sensitif.
- Jika key pernah terpapar, segera rotate dari dashboard Supabase.