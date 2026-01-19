# 🗄️ VEROPRISE ERP - Database Migrations# 🚀 VEROPRISE ERP - NEW DATABASE MIGRATIONS



**✅ CLEANED & READY FOR PRODUCTION**## 📋 Overview



---This folder contains the latest database migrations for Veroprise ERP customization based on client requirements. These migrations are ready to be pushed to a **NEW Supabase project**.



## 📁 Migration Files (4 Files Only!)---



Semua file SQL lama sudah dihapus. Hanya 4 file ini yang perlu dijalankan:## 🗂️ Migration Files



### 1️⃣ **`01_base_schema.sql`** (16.5 KB)### **1. Warehouse & Inventory System**

**Core foundation** - 13 tables**File:** `20260117_warehouse_system.sql`

- profiles, outlets, employees, shifts

- categories, products, inventory**Features:**

- transactions, transaction_items- ✅ Warehouses (Gudang Pusat)

- bookings, expenses- ✅ Warehouse Inventory Management

- RLS policies & triggers- ✅ Purchase Orders (PO from Suppliers)

- ✅ Stock Transfer Orders (Warehouse → Outlet)

### 2️⃣ **`02_warehouse_system.sql`** (22.2 KB)- ✅ Stock Opname (Monthly Physical Count)

**Warehouse management** - 9 tables- ✅ Daily Closing Reports

- warehouses, warehouse_inventory

- suppliers, purchase_orders**Tables Created:**

- stock_transfer_orders- `warehouses`

- stock_opname, daily_closing_reports- `warehouse_inventory`

- Auto-update functions- `purchase_orders`

- `purchase_order_items`

### 3️⃣ **`03_multi_payment_system.sql`** (10.4 KB)- `stock_transfer_orders`

**Multi-payment** - 1 table + alter- `stock_transfer_items`

- transaction_payments (7 metode)- `stock_opname`

- Payment status automation- `stock_opname_items`

- Data migration- `daily_closing_reports`

- Cash deposit calculation

---

### 4️⃣ **`04_hr_attendance_incentives.sql`** (20.7 KB)

**HR automation** - 3 tables + alter### **2. Multi-Payment System**

- attendance (auto dari shift)**File:** `20260117_multi_payment_system.sql`

- sales_targets (with tiers)

- employee_incentives (auto-calculate)**Features:**

- Payroll enhancements- ✅ Multi-payment dalam 1 transaksi (DP + Pelunasan)

- ✅ Payment tracking per method (Cash, QRIS, Transfer, Olshop, etc.)

---- ✅ Auto-calculate payment status

- ✅ Cash deposit calculation formula

## 🚀 Quick Start- ✅ Payment summary reports



```bash**Tables/Enhancements:**

# 1. Buka Supabase Dashboard → SQL Editor- `transaction_payments` (new)

- Enhanced `transactions` table with payment tracking

# 2. Copy-paste dan jalankan satu per satu:- Payment summary views

01_base_schema.sql           # ✅ Core tables- Auto-update triggers

02_warehouse_system.sql      # ✅ Warehouse

03_multi_payment_system.sql  # ✅ Multi-payment**Payment Methods Supported:**

04_hr_attendance_incentives.sql  # ✅ HR automation- Cash

- QRIS

# 3. Verify- Transfer Bank

SELECT COUNT(*) FROM information_schema.tables - Olshop (Marketplace)

WHERE table_schema = 'public';- Debit Card

-- Expected: 27 tables- Credit Card

```- Other



------



## 📖 Dokumentasi Lengkap### **3. HR Enhancement (Attendance & Incentives)**

**File:** `20260117_hr_attendance_incentives.sql`

Lihat folder `../` (satu level di atas):

**Features:**

1. **`EXECUTION_GUIDE.md`** - Panduan lengkap step-by-step- ✅ Auto-attendance from shift assignments

2. **`CLEANUP_SUMMARY.md`** - Summary apa yang sudah dibersihkan- ✅ Clock in/out tracking

3. **`SQL_QUICK_REFERENCE.md`** - Quick reference card- ✅ Late detection & overtime calculation

4. **`TECHNICAL_SPECS.md`** - Technical specifications- ✅ Sales targets & incentives

5. **`IMPLEMENTATION_SUMMARY.md`** - Implementation details- ✅ Auto-calculate employee bonuses

- ✅ Payroll integration

---

**Tables Created:**

## ⚠️ PENTING!- `attendance`

- `sales_targets`

- ✅ **SUDAH DIBERSIHKAN:** Semua file lama (20251221*, 20260104*, 20260112*) sudah dihapus- `employee_incentives`

- ✅ **NO CONFLICT:** Tidak ada duplikasi atau konflik antar file- Enhanced `payroll` table

- ✅ **PRODUCTION READY:** Siap digunakan untuk project baru

- ⚠️ **URUTAN PENTING:** Jalankan sesuai urutan 01 → 02 → 03 → 04**Target Types:**

- Product Quantity (e.g., 100 haircuts/day)

---- Product Value (e.g., Rp 5,000,000/day)

- Total Sales (e.g., Rp 10,000,000/day)

## 📊 Database Structure- Category Sales



```**Incentive Types:**

Total: 27 Tables- Fixed Amount

├─ Base (13)        → Core ERP- Percentage-based

├─ Warehouse (9)    → Inventory flow- Tiered (multiple levels)

├─ Payment (1)      → Multi-payment

└─ HR (3)           → Attendance & incentives---



Total: 40+ RLS Policies## 🔧 Deployment Instructions

├─ User level access control

├─ Outlet-based permissions### **STEP 1: Create New Supabase Project**

└─ Role-based authorization

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)

Total: 20+ Triggers2. Click **"New Project"**

├─ Auto-create attendance3. Fill in:

├─ Auto-calculate incentives   - Project Name: `veroprise-erp-production`

├─ Auto-update inventory   - Database Password: (generate strong password)

└─ Auto-update payment status   - Region: `Southeast Asia (Singapore)` (recommended for Indonesia)

4. Wait for project to be created (~2 minutes)

Total: 6 Functions

├─ calculate_employee_incentives()---

├─ calculate_cash_deposit()

├─ get_payment_breakdown()### **STEP 2: Update Environment Variables**

└─ update_transaction_payment_status()

```Copy the new project credentials:



---```env

# .env file

## 🎯 Key FeaturesVITE_SUPABASE_URL=https://your-new-project.supabase.co

VITE_SUPABASE_ANON_KEY=your-anon-key-here

✅ **Warehouse Management:** PO → Gudang → Toko flow with approval```

✅ **Multi-Payment:** 7 metode pembayaran per transaksi

✅ **HR Automation:** Attendance auto dari shift, incentive auto calculateUpdate in:

✅ **Stock Opname:** Physical count dengan adjustment- `barberdoc_erp/.env`

✅ **Daily Closing:** Multi-payment breakdown & bank deposit- `barberdoc_erp/.env.local` (if exists)

✅ **Sales Incentives:** Tiered system dengan auto-calculate

---

---

### **STEP 3: Run Base Schema First**

## 🔒 Security (RLS)

**IMPORTANT:** Run existing migrations first before the new ones!

All tables protected with Row Level Security:

- Users can only access their assigned outlets1. Open Supabase SQL Editor

- Employees see only their own attendance/incentives2. Run migrations in this order:

- Managers have warehouse access   - `20251221022142_*.sql`

- Owners have full access   - `20251221022155_*.sql`

- Public can create bookings   - `20251221022955_*.sql`

   - `20260104_hr_payroll.sql`

---   - `20260104_partner_vendors.sql`

   - `20260104_product_recipes.sql`

## 🧪 Testing   - `20260112_*.sql` (all files)



After migration, test these scenarios:---

1. ✅ Create user & assign to outlet

2. ✅ Create products & inventory### **STEP 4: Run New Migrations**

3. ✅ Create POS transaction with multi-payment

4. ✅ Create PO and receive to warehouseRun in this exact order:

5. ✅ Transfer stock from warehouse to outlet

6. ✅ Create shift and verify attendance auto-created```sql

7. ✅ Complete sale and verify incentive calculated-- 1. Warehouse System

-- Copy and paste content from: 20260117_warehouse_system.sql

---

-- 2. Multi-Payment System

**Last Updated:** 2026-01-18-- Copy and paste content from: 20260117_multi_payment_system.sql

**Version:** 1.0 (Production Ready)

**Status:** ✅ Clean & Tested-- 3. HR Enhancement

-- Copy and paste content from: 20260117_hr_attendance_incentives.sql
```

---

### **STEP 5: Verify Installation**

Run this query to check all tables exist:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_name IN (
    'warehouses',
    'warehouse_inventory',
    'purchase_orders',
    'purchase_order_items',
    'stock_transfer_orders',
    'stock_transfer_items',
    'stock_opname',
    'stock_opname_items',
    'daily_closing_reports',
    'transaction_payments',
    'attendance',
    'sales_targets',
    'employee_incentives'
)
ORDER BY table_name;
```

Should return **13 rows**.

---

### **STEP 6: Create Initial Data**

#### **A. Create Warehouse**

```sql
INSERT INTO public.warehouses (code, name, address, phone, warehouse_type)
VALUES (
    'WH-001',
    'Gudang Pusat Jakarta',
    'Jl. Industri No. 123, Jakarta',
    '021-12345678',
    'central'
);
```

#### **B. Create Outlets**

```sql
INSERT INTO public.outlets (name, address, phone, is_active)
VALUES 
    ('Veroprise Kelapa Gading', 'Jl. Boulevard Raya No. 15', '021-xxx', true),
    ('Veroprise Serpong', 'Jl. BSD Raya No. 88', '021-yyy', true);
```

#### **C. Create Users via Dashboard**

1. Go to **Authentication → Users**
2. Click **"Add User"**
3. Fill in:
   - Email: `owner@veroprise.com`
   - Password: (strong password)
   - ✅ Check "Auto Confirm User"
4. Copy the User UUID

#### **D. Assign User to Outlet**

```sql
-- Get outlet ID first
SELECT id, name FROM outlets;

-- Insert user profile
INSERT INTO public.profiles (user_id, full_name, phone)
VALUES ('paste-user-uuid-here', 'Veroprise Owner', '08123456789');

-- Assign role
INSERT INTO public.user_roles (user_id, role)
VALUES ('paste-user-uuid-here', 'owner');

-- Assign to outlet
INSERT INTO public.user_outlets (user_id, outlet_id)
VALUES ('paste-user-uuid-here', 'paste-outlet-uuid-here');
```

---

## 📊 Key Features Implemented

### **Inventory Flow**

```
Supplier → [PO] → Gudang Pusat → [Stock Transfer] → Outlet → Customer
```

1. **Purchase Order** - Order barang dari supplier ke gudang
2. **Stock Transfer** - Transfer stock dari gudang ke toko
3. **Transaction** - Penjualan di toko (stock toko berkurang)
4. **Stock Opname** - Physical count bulanan (gudang & toko)
5. **Daily Closing** - Laporan akhir hari per outlet

---

### **Multi-Payment Example**

```javascript
// Customer order: Rp 100,000
// DP via Transfer: Rp 50,000
// Pelunasan via Cash: Rp 50,000

// Transaction record:
{
  id: "trans-123",
  total: 100000,
  payment_status: "paid",
  is_multi_payment: true,
  payments: [
    { method: "transfer", amount: 50000, reference: "TRF123" },
    { method: "cash", amount: 50000 }
  ]
}
```

---

### **Cash Deposit Formula**

```
Uang Setor = Gross Sales - Expenses - QRIS - Olshop - Transfer - Card

OR

Uang Setor = Cash Sales - Expenses
```

**Example:**
- Cash Sales: Rp 5,000,000
- QRIS Sales: Rp 2,000,000
- Olshop Sales: Rp 1,000,000
- Expenses: Rp 500,000

**Cash to Deposit:**
```
= 5,000,000 - 500,000
= Rp 4,500,000
```

---

### **Attendance Auto-Generation**

```
Shift Created → Employee Assigned → Attendance Auto-Created
```

When employee is assigned to a shift:
1. Attendance record automatically created
2. Status: "present" (default)
3. Employee clocks in/out
4. System calculates hours worked & overtime
5. Late detection (>15 min grace period)

---

### **Sales Target & Incentive**

**Example Target:**
- Product: Pomade Premium
- Target: 100 unit/day
- Incentive: Rp 50,000

**Auto-Check:**
- End of day → System checks sales
- If employee sold ≥100 units → Create incentive record
- Status: "pending" → Manager approves → Status: "approved" → Add to payroll

---

## 🔐 Security (RLS Policies)

All tables have Row Level Security enabled:

✅ **Warehouse Data** - Admin/Owner/Manager only
✅ **Payment Data** - Outlet users can view their own
✅ **Attendance** - Employees can view their own
✅ **Incentives** - Employees can view their own
✅ **Stock Opname** - Outlet-specific access

---

## 📈 Performance Optimizations

All critical indexes created:
- Date-based queries
- Foreign key relationships
- Status filtering
- Payment method grouping

**Generated columns** for:
- Payment subtotals
- Stock differences
- Achievement percentages
- Net salary calculations

---

## 🛠️ Next Steps

1. ✅ Deploy migrations to production
2. ⏳ Build frontend UI components
3. ⏳ Implement Bluetooth printer integration
4. ⏳ Create dashboard & reports
5. ⏳ User testing & training

---

## 📞 Support

For questions or issues during deployment:
- Check migration files for detailed comments
- All functions have examples in comments
- Test queries provided for verification

---

## ⚠️ Important Notes

1. **Backup existing data** before running migrations on existing project
2. These migrations are for **NEW Supabase project**
3. RLS policies are enabled - users need proper roles
4. Some features require frontend implementation
5. Test in staging environment first

---

**Last Updated:** 2026-01-17
**Version:** 1.0.0
**Status:** ✅ Ready for Production
