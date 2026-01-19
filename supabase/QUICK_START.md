# 🚀 QUICK START - Deploy to New Supabase

## TL;DR (5 Menit Setup)

### 1️⃣ Create Project
```
https://supabase.com/dashboard
→ New Project
→ Region: Singapore
→ Copy URL & Anon Key
```

### 2️⃣ Update .env
```bash
VITE_SUPABASE_URL=https://xxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=xxxxx
```

### 3️⃣ Run Migrations
Open SQL Editor di Supabase:

**A. Base Schema** (dari existing migrations):
```sql
-- Run semua file di migrations/ folder kecuali 20260117_*
-- Run secara berurutan dari tanggal paling lama
```

**B. New Features** (file baru):
```sql
-- 1. Warehouse System
-- Paste isi file: 20260117_warehouse_system.sql

-- 2. Multi-Payment
-- Paste isi file: 20260117_multi_payment_system.sql

-- 3. HR Enhancement
-- Paste isi file: 20260117_hr_attendance_incentives.sql
```

### 4️⃣ Create Initial Data

```sql
-- Warehouse
INSERT INTO warehouses (code, name, address, phone)
VALUES ('WH-001', 'Gudang Pusat', 'Jakarta', '021-xxx');

-- Outlet
INSERT INTO outlets (name, address, phone, is_active)
VALUES ('Veroprise Pusat', 'Jakarta Pusat', '021-yyy', true);
```

### 5️⃣ Create User (via Dashboard)
```
Authentication → Users → Add User
Email: owner@veroprise.com
✅ Auto Confirm
Copy UUID
```

### 6️⃣ Assign User
```sql
-- Ganti 'user-uuid' dengan UUID dari step 5
-- Ganti 'outlet-uuid' dengan UUID outlet dari step 4

INSERT INTO profiles (user_id, full_name, phone)
VALUES ('user-uuid', 'Owner Name', '08123456789');

INSERT INTO user_roles (user_id, role)
VALUES ('user-uuid', 'owner');

INSERT INTO user_outlets (user_id, outlet_id)
VALUES ('user-uuid', 'outlet-uuid');
```

### 7️⃣ Test Login
```
npm run dev
→ Login dengan email & password dari step 5
```

---

## ✅ Verification Checklist

Run this query to verify:

```sql
SELECT 
    'warehouses' as table_name, COUNT(*) as count FROM warehouses
UNION ALL
SELECT 'outlets', COUNT(*) FROM outlets
UNION ALL
SELECT 'profiles', COUNT(*) FROM profiles
UNION ALL
SELECT 'user_roles', COUNT(*) FROM user_roles
UNION ALL
SELECT 'user_outlets', COUNT(*) FROM user_outlets;
```

Expected result:
```
warehouses: 1
outlets: 1
profiles: 1
user_roles: 1
user_outlets: 1
```

---

## 🎯 Test Features

### Test Multi-Payment:
1. Login → POS
2. Add items
3. Click "Multi Payment"
4. Add: DP Transfer Rp 50k + Cash Rp 50k
5. Check `transaction_payments` table

### Test Attendance:
1. HR → Shifts → Create Shift
2. Assign Employee
3. Check `attendance` table (auto-created)

### Test Stock Transfer:
1. Inventory → Stock Transfer
2. Request from Warehouse
3. Approve → Stock updates automatically

---

## 🆘 Troubleshooting

**Error: "relation does not exist"**
→ Run migrations in correct order (see README.md)

**Error: "permission denied"**
→ Check RLS policies, user needs proper role

**Login failed**
→ Verify user has profile, role, and outlet assigned

---

**Ready? Deploy Now! 🚀**
