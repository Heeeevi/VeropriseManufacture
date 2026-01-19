# 🚀 VEROPRISE ERP - SQL EXECUTION QUICK REFERENCE

```
╔══════════════════════════════════════════════════════════════════╗
║                   SUPABASE SQL EXECUTION ORDER                   ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  1️⃣  01_base_schema.sql                                          ║
║     → Core tables (13 tables)                                    ║
║     → profiles, outlets, employees, products, transactions       ║
║                                                                  ║
║  2️⃣  02_warehouse_system.sql                                     ║
║     → Warehouse management (9 tables)                            ║
║     → warehouses, PO, stock_transfer, stock_opname              ║
║                                                                  ║
║  3️⃣  03_multi_payment_system.sql                                 ║
║     → Multi-payment system (1 table + alter)                     ║
║     → transaction_payments, 7 payment methods                    ║
║                                                                  ║
║  4️⃣  04_hr_attendance_incentives.sql                             ║
║     → HR automation (3 tables + alter)                           ║
║     → attendance, sales_targets, employee_incentives            ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║  ✅ TOTAL: 4 files → 27 tables → 40+ RLS policies               ║
╚══════════════════════════════════════════════════════════════════╝
```

## 📋 CHECKLIST EKSEKUSI

```
□ Open Supabase Dashboard → SQL Editor
□ Run: 01_base_schema.sql
  ✓ Success: 13 tables created
  ✓ Success: Categories seeded

□ Run: 02_warehouse_system.sql
  ✓ Success: 9 tables created
  ✓ Success: Auto-update functions created

□ Run: 03_multi_payment_system.sql
  ✓ Success: transaction_payments table created
  ✓ Success: Data migration completed
  ✓ Success: Views created

□ Run: 04_hr_attendance_incentives.sql
  ✓ Success: 3 tables created
  ✓ Success: Auto-calculate functions created
  ✓ Success: Triggers activated

□ Verify: Check all tables exist
□ Verify: Check RLS policies active
□ Test: Create sample data
```

## 🔍 VERIFICATION QUERIES

### Check Tables (Expected: 27 tables)
```sql
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = 'public';
```

### Check RLS Policies (Expected: 40+)
```sql
SELECT COUNT(*) FROM pg_policies 
WHERE schemaname = 'public';
```

### Check Functions (Expected: 6+)
```sql
SELECT COUNT(*) FROM information_schema.routines 
WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';
```

## ⚠️ COMMON ERRORS

| Error | Cause | Solution |
|-------|-------|----------|
| "relation does not exist" | Wrong order | Run from file 1 again |
| "column already exists" | Already run | Skip error or reset DB |
| "type already exists" | Enum exists | Skip error or drop type |

## 🗑️ RESET DATABASE (IF NEEDED)

```sql
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
```

**WARNING:** This deletes ALL data!

## 📊 TABLE STRUCTURE OVERVIEW

### Base Schema (File 1)
```
profiles         → User management
outlets          → Store/branch management
employees        → Staff management
shifts           → Work schedules
categories       → Product categories
products         → Products & services
inventory        → Stock per outlet
transactions     → POS sales
bookings         → Appointment system
expenses         → Cost tracking
```

### Warehouse System (File 2)
```
warehouses              → Central/regional warehouse
warehouse_inventory     → Stock per warehouse
suppliers               → Vendor management
purchase_orders         → PO dari supplier
stock_transfer_orders   → Warehouse → Outlet
stock_opname            → Physical count
daily_closing_reports   → End of day report
```

### Multi-Payment (File 3)
```
transaction_payments    → Split payment records
  ├─ cash              → Tunai
  ├─ qris              → QRIS/e-wallet
  ├─ transfer          → Bank transfer
  ├─ olshop            → E-commerce
  ├─ debit_card        → Kartu debit
  ├─ credit_card       → Kartu kredit
  └─ other             → Lainnya
```

### HR System (File 4)
```
attendance              → Daily attendance
  ├─ auto-create from shifts
  ├─ clock in/out
  └─ calculate hours & overtime

sales_targets           → Sales goals
  ├─ per product/category
  ├─ daily/weekly/monthly
  └─ fixed/percentage/tiered

employee_incentives     → Auto-calculated bonuses
  ├─ achievement tracking
  ├─ auto-calculate after sale
  └─ payment tracking
```

## 🎯 KEY FEATURES

### Automation
✅ Attendance auto-created from shifts
✅ Work hours auto-calculated
✅ Inventory auto-updated after PO received
✅ Stock auto-transferred between warehouse-outlet
✅ Incentives auto-calculated after sales
✅ Payment status auto-updated
✅ Multi-payment validation

### Security (RLS)
✅ User can only access their outlets
✅ Employees see own attendance/incentives
✅ Managers access warehouse features
✅ Owner has full access
✅ Public can create bookings

### Business Logic
✅ Stock opname adjusts inventory
✅ Late attendance auto-detected
✅ Overtime auto-calculated
✅ Multi-tiered incentive system
✅ Cash deposit calculation
✅ Daily closing validation

## 📞 SUPPORT

If you encounter issues:
1. Check `EXECUTION_GUIDE.md` for detailed steps
2. Check `TROUBLESHOOTING.md` for common solutions
3. Verify execution order is correct
4. Check Supabase logs for specific errors

---

**Generated by:** Veroprise ERP Setup v1.0
**Date:** 2026-01-17
**Status:** ✅ Ready for production
