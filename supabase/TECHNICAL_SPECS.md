# 🔧 TECHNICAL SPECIFICATIONS - Veroprise ERP Customization

## 📐 System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     FRONTEND (React + TypeScript)            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   POS    │  │ Warehouse│  │    HR    │  │ Reports  │   │
│  │  Multi   │  │ Transfer │  │Attendance│  │Dashboard │   │
│  │ Payment  │  │  & PO    │  │Incentive │  │& Analytics│   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└──────────────────────┬──────────────────────────────────────┘
                       │ REST API / Realtime
┌──────────────────────┴──────────────────────────────────────┐
│              SUPABASE (Backend + Database)                   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  PostgreSQL Database with RLS                          │ │
│  │  - 15 Main Tables                                      │ │
│  │  - 40+ RLS Policies                                    │ │
│  │  - 6 Major Functions                                   │ │
│  │  - 20+ Triggers                                        │ │
│  │  - 30+ Indexes                                         │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────────────────┐
│                  HARDWARE INTEGRATION                        │
│  ┌──────────────────────┐  ┌──────────────────────┐        │
│  │  Bluetooth Printer   │  │  Barcode Scanner     │        │
│  │  (ESC/POS Protocol)  │  │  (Optional)          │        │
│  └──────────────────────┘  └──────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗄️ Database Schema Details

### **1. Warehouse System**

#### Table: `warehouses`
```sql
Purpose: Master data gudang/warehouse
Key Fields:
- id (UUID, PK)
- code (VARCHAR, UNIQUE) - WH-001, WH-002
- name (VARCHAR) - Nama gudang
- warehouse_type (VARCHAR) - 'central', 'regional'
- is_active (BOOLEAN)

Business Rules:
- Code must be unique
- Can have multiple warehouses
- Central warehouse untuk pusat distribusi
```

#### Table: `warehouse_inventory`
```sql
Purpose: Stock di gudang
Key Fields:
- warehouse_id (FK to warehouses)
- product_id (FK to products)
- quantity (DECIMAL) - Stock saat ini
- min_stock (DECIMAL) - Alert jika < min
- cost_per_unit (DECIMAL) - Harga pokok

Business Rules:
- UNIQUE constraint (warehouse_id, product_id)
- Quantity cannot be negative
- Auto-alert when quantity <= min_stock
```

#### Table: `purchase_orders` & `purchase_order_items`
```sql
Purpose: PO dari supplier ke gudang
Workflow States:
1. draft - PO baru dibuat
2. submitted - Submitted ke supplier
3. approved - Approved internal
4. received - Barang sudah diterima
5. cancelled - Dibatalkan

Key Fields (Header):
- po_number (VARCHAR, UNIQUE) - PO-2026-0001
- warehouse_id (FK)
- supplier_id (FK)
- total_amount (DECIMAL)
- status (VARCHAR)
- order_date, expected_delivery_date

Key Fields (Items):
- po_id (FK)
- product_id (FK)
- quantity_ordered (DECIMAL)
- quantity_received (DECIMAL)
- unit_price (DECIMAL)
- subtotal (GENERATED) - auto calculated

Business Rules:
- PO number auto-generated
- Items can't be edited after status = 'received'
- Stock updated only when status = 'received'
```

#### Table: `stock_transfer_orders` & `stock_transfer_items`
```sql
Purpose: Transfer stock gudang → outlet
Workflow States:
1. pending - Request dari outlet
2. approved - Approved warehouse
3. in_transit - Sedang dikirim
4. received - Diterima outlet
5. cancelled - Dibatalkan

Key Fields (Header):
- transfer_number (VARCHAR, UNIQUE) - STO-2026-0001
- from_warehouse_id (FK)
- to_outlet_id (FK)
- status (VARCHAR)
- requested_by, approved_by, received_by (FK to users)

Key Fields (Items):
- transfer_id (FK)
- product_id (FK)
- quantity_requested (DECIMAL)
- quantity_approved (DECIMAL)
- quantity_received (DECIMAL)

Business Rules:
- Only approved quantity will be transferred
- Stock reduced from warehouse when status = 'in_transit'
- Stock added to outlet when status = 'received'
- Can't modify after status = 'received'
```

#### Table: `stock_opname` & `stock_opname_items`
```sql
Purpose: Physical count bulanan
Location Types:
- 'warehouse' - Opname di gudang
- 'outlet' - Opname di toko

Workflow States:
1. draft - Baru dibuat
2. in_progress - Sedang counting
3. completed - Counting selesai
4. approved - Approved & adjustment applied

Key Fields (Header):
- opname_number (VARCHAR, UNIQUE) - SO-2026-01-001
- location_type (VARCHAR)
- warehouse_id or outlet_id (FK)
- opname_date (DATE)
- period_month, period_year (INT)
- status (VARCHAR)

Key Fields (Items):
- opname_id (FK)
- product_id (FK)
- system_quantity (DECIMAL) - Qty di system
- physical_quantity (DECIMAL) - Qty hasil hitung
- difference (GENERATED) - physical - system
- difference_value (DECIMAL) - Nilai selisih

Business Rules:
- One opname per location per month
- System quantity auto-filled from current stock
- Physical quantity manual input
- Adjustment applied when status = 'approved'
```

#### Table: `daily_closing_reports`
```sql
Purpose: Laporan akhir hari per outlet
Key Fields:
- outlet_id (FK)
- closing_date (DATE)
- shift_id (FK, optional)
- total_sales (DECIMAL)
- cash_sales, qris_sales, transfer_sales, etc. (DECIMAL)
- total_expenses (DECIMAL)
- cash_to_deposit (GENERATED) - Cash - Expenses

Business Rules:
- UNIQUE constraint (outlet_id, closing_date)
- Auto-calculate from transactions & payments
- Cash deposit formula: Cash Sales - Expenses
```

---

### **2. Multi-Payment System**

#### Table: `transaction_payments`
```sql
Purpose: Track pembayaran per transaksi
Payment Methods:
- 'cash' - Tunai
- 'qris' - QRIS/QR Payment
- 'transfer' - Transfer bank
- 'olshop' - Marketplace (Tokped, Shopee, etc)
- 'debit_card' - Kartu debit
- 'credit_card' - Kartu kredit
- 'other' - Lainnya

Key Fields:
- transaction_id (FK to transactions)
- payment_method (VARCHAR)
- amount (DECIMAL)
- payment_date (TIMESTAMPTZ)
- reference_number (VARCHAR) - Nomor referensi
- bank_name (VARCHAR) - Untuk transfer
- card_number_last4 (VARCHAR) - 4 digit terakhir kartu

Business Rules:
- Sum of payments can equal or exceed transaction total
- Each payment logged separately
- Auto-update transaction.payment_status
```

#### Enhanced: `transactions` table
```sql
New Fields:
- payment_status (VARCHAR) - 'paid', 'partial', 'pending', 'refunded'
- total_paid (DECIMAL) - Sum of all payments
- remaining_amount (DECIMAL) - Total - Total Paid
- is_multi_payment (BOOLEAN) - True if >1 payment

Auto-Calculations:
- total_paid updated via trigger
- payment_status auto-determined
- is_multi_payment = true if payment count > 1
```

---

### **3. HR Enhancement**

#### Table: `attendance`
```sql
Purpose: Absensi karyawan (auto from shift)
Status Types:
- 'present' - Hadir
- 'late' - Terlambat
- 'absent' - Tidak hadir
- 'leave' - Cuti
- 'sick' - Sakit
- 'holiday' - Libur
- 'off' - Off

Key Fields:
- employee_id (FK)
- outlet_id (FK)
- attendance_date (DATE)
- shift_id (FK)
- clock_in, clock_out (TIMESTAMPTZ)
- status (VARCHAR)
- hours_worked (DECIMAL) - Auto calculated
- overtime_hours (DECIMAL)
- late_duration_minutes (INT)

Business Rules:
- UNIQUE constraint (employee_id, attendance_date)
- Auto-created when employee assigned to shift
- Hours worked = clock_out - clock_in - break
- Late if clock_in > shift_start + 15 min grace
- Overtime if hours_worked > 8
```

#### Table: `sales_targets`
```sql
Purpose: Setup target penjualan & incentive
Target Types:
- 'product_quantity' - Qty produk tertentu
- 'product_value' - Nilai produk tertentu
- 'total_sales' - Total penjualan
- 'category_sales' - Penjualan kategori

Target Periods:
- 'daily' - Harian
- 'weekly' - Mingguan
- 'monthly' - Bulanan
- 'quarterly' - Kuartalan

Incentive Types:
- 'fixed' - Fixed amount (Rp 50,000)
- 'percentage' - Percentage of sales (5%)
- 'tiered' - Multiple tiers (100-200: Rp 50k, >200: Rp 100k)

Key Fields:
- target_name (VARCHAR)
- target_type, target_period (VARCHAR)
- product_id, category_id (FK, optional)
- outlet_id (FK, optional) - Null = all outlets
- target_value (DECIMAL)
- incentive_type (VARCHAR)
- incentive_amount, incentive_percentage (DECIMAL)
- tiers (JSONB) - For tiered incentives
- start_date, end_date (DATE)
- is_active (BOOLEAN)

Business Rules:
- Can have multiple active targets
- Product/category specific or general
- Outlet specific or company-wide
- Auto-checked at end of day
```

#### Table: `employee_incentives`
```sql
Purpose: Track bonus yang didapat karyawan
Status Flow:
1. pending - Baru tercapai, belum approved
2. approved - Approved manager, siap dibayar
3. paid - Sudah dibayar/masuk payroll
4. cancelled - Dibatalkan

Key Fields:
- employee_id (FK)
- target_id (FK to sales_targets)
- outlet_id (FK)
- period_date (DATE)
- target_value, achieved_value (DECIMAL)
- achievement_percentage (GENERATED)
- incentive_amount (DECIMAL)
- transaction_ids (UUID[]) - Array of transactions
- status (VARCHAR)

Business Rules:
- Auto-created by check_daily_sales_target_achievement()
- Links to specific transactions
- Requires approval before payment
- Added to payroll when status = 'approved'
```

#### Enhanced: `payroll` table
```sql
New Fields:
- total_incentives (DECIMAL) - Sum of approved incentives
- attendance_days (INT) - Days worked
- late_count (INT) - Times late
- absent_count (INT) - Days absent
- overtime_hours (DECIMAL) - Total overtime
- overtime_pay (DECIMAL) - Overtime payment
- deductions (DECIMAL) - Potongan
- net_salary (GENERATED) - Base + Incentives + Overtime - Deductions

Auto-Calculations:
- total_incentives from employee_incentives
- attendance data from attendance table
- net_salary auto-calculated
```

---

## 🔄 Business Processes

### **Process 1: Purchase Order Flow**
```
1. Create PO (status: draft)
   ↓
2. Submit to Supplier (status: submitted)
   ↓
3. Internal Approval (status: approved)
   ↓
4. Receive Goods (status: received)
   → Auto-update warehouse_inventory (+quantity)
   ↓
5. Close PO
```

### **Process 2: Stock Transfer Flow**
```
1. Outlet Request Stock (status: pending)
   → Create stock_transfer_order
   ↓
2. Warehouse Review & Approve (status: approved)
   → Set quantity_approved
   ↓
3. Ship Goods (status: in_transit)
   → warehouse_inventory (-quantity_approved)
   ↓
4. Outlet Receive (status: received)
   → outlet inventory (+quantity_received)
   ↓
5. Close Transfer
```

### **Process 3: POS Transaction with Multi-Payment**
```
1. Create Transaction
   ↓
2. Add Items
   ↓
3. Add Multiple Payments
   - Customer pays: Rp 100,000
   - Payment 1: Transfer Rp 50,000 (DP)
   - Payment 2: Cash Rp 50,000 (Pelunasan)
   ↓
4. Trigger: update_transaction_payment_status()
   - Calculate total_paid = 100,000
   - Set payment_status = 'paid'
   - Set is_multi_payment = true
   ↓
5. Update Stock (-quantity)
   ↓
6. Print Receipt with Payment Breakdown
```

### **Process 4: Daily Closing**
```
1. End of Day
   ↓
2. Calculate Totals:
   - Cash Sales: Rp 5,000,000
   - QRIS Sales: Rp 2,000,000
   - Transfer: Rp 1,000,000
   - Olshop: Rp 500,000
   - Total Sales: Rp 8,500,000
   ↓
3. Calculate Expenses:
   - Operasional: Rp 300,000
   - Lain-lain: Rp 200,000
   - Total: Rp 500,000
   ↓
4. Calculate Cash Deposit:
   = Cash Sales - Expenses
   = 5,000,000 - 500,000
   = Rp 4,500,000
   ↓
5. Create daily_closing_report
   ↓
6. Manager Review & Approve
```

### **Process 5: Attendance & Incentive**
```
1. Create Shift & Assign Employee
   ↓
2. Trigger: auto_create_attendance_from_shift()
   → Create attendance record (status: present)
   ↓
3. Employee Clock In
   → Update attendance.clock_in
   ↓
4. Employee Clock Out
   → Update attendance.clock_out
   → Trigger: calculate_hours_worked()
     - Calculate hours worked
     - Detect overtime
     - Detect late
   ↓
5. Employee Makes Sales (Transactions)
   ↓
6. End of Day: Check Achievement
   → Call: check_daily_sales_target_achievement()
     - Check each active target
     - If target met → Create employee_incentive
   ↓
7. Manager Reviews Incentives
   ↓
8. Approve Incentive (status: approved)
   ↓
9. Add to Payroll
```

### **Process 6: Monthly Stock Opname**
```
1. Create Stock Opname (status: draft)
   → Auto-fill system_quantity from inventory
   ↓
2. Start Counting (status: in_progress)
   ↓
3. Input Physical Count
   → Update physical_quantity for each item
   → Auto-calculate difference
   ↓
4. Complete Counting (status: completed)
   ↓
5. Review Variances
   → Check items with difference != 0
   ↓
6. Manager Approve (status: approved)
   → Apply stock adjustments
   → Update inventory with physical_quantity
   ↓
7. Generate Variance Report
```

---

## 🔐 Security & Permissions

### **Role-Based Access Control (RBAC)**

#### Roles:
```
owner     - Full access to everything
admin     - Full access (company-wide)
manager   - Manage outlet operations
cashier   - POS & daily transactions
staff     - Limited view access
```

#### Permission Matrix:

| Feature | Owner | Admin | Manager | Cashier | Staff |
|---------|-------|-------|---------|---------|-------|
| Warehouses | ✅ | ✅ | ❌ | ❌ | ❌ |
| Purchase Orders | ✅ | ✅ | 👁️ | ❌ | ❌ |
| Stock Transfer | ✅ | ✅ | ✅ | ❌ | ❌ |
| Stock Opname | ✅ | ✅ | ✅ | ❌ | ❌ |
| POS Transactions | ✅ | ✅ | ✅ | ✅ | ❌ |
| Multi-Payment | ✅ | ✅ | ✅ | ✅ | ❌ |
| Daily Closing | ✅ | ✅ | ✅ | ❌ | ❌ |
| Attendance (Own) | ✅ | ✅ | ✅ | 👁️ | 👁️ |
| Attendance (All) | ✅ | ✅ | ✅ | ❌ | ❌ |
| Sales Targets | ✅ | ✅ | 👁️ | 👁️ | 👁️ |
| Incentives (Own) | ✅ | ✅ | ✅ | 👁️ | 👁️ |
| Incentives (All) | ✅ | ✅ | ✅ | ❌ | ❌ |
| Payroll | ✅ | ✅ | 👁️ | ❌ | ❌ |
| Reports | ✅ | ✅ | ✅ | 👁️ | ❌ |

Legend: ✅ Full Access | 👁️ View Only | ❌ No Access

---

## 📊 Performance Specifications

### **Query Performance Targets:**
- List queries: < 100ms
- Aggregation queries: < 500ms
- Report generation: < 2 seconds
- Real-time updates: < 50ms

### **Database Optimization:**
- 30+ indexes on frequently queried columns
- Generated columns for complex calculations
- Materialized views for heavy reports
- Connection pooling

### **Scalability:**
- Support up to 100 outlets
- 10,000 transactions/day
- 1,000 products
- 500 employees
- 1 million rows/table (tested)

---

## 🧪 Testing Requirements

### **Unit Tests:**
- [ ] All database functions
- [ ] Trigger behaviors
- [ ] RLS policies
- [ ] Generated columns

### **Integration Tests:**
- [ ] Complete PO workflow
- [ ] Stock transfer workflow
- [ ] Multi-payment transaction
- [ ] Daily closing calculation
- [ ] Incentive auto-calculation

### **Performance Tests:**
- [ ] Load test with 1000 concurrent users
- [ ] Stress test with 10k transactions
- [ ] Report generation with large datasets

---

## 📱 Frontend Requirements (Phase 2)

### **Technologies:**
- React 18+
- TypeScript
- Tailwind CSS
- Shadcn/UI Components
- React Query (data fetching)
- Zustand (state management)

### **Key Pages to Build:**
1. Warehouse Management
2. Purchase Orders
3. Stock Transfer
4. Stock Opname
5. POS with Multi-Payment Modal
6. Daily Closing
7. Attendance Management
8. Sales Targets Setup
9. Incentive Tracking
10. Enhanced Reports

---

## 🔌 Hardware Integration Specs

### **Bluetooth Printer:**
- Protocol: ESC/POS
- Connection: Bluetooth 4.0+
- Supported models: Most thermal printers
- Paper size: 58mm or 80mm
- Print speed: Minimum 50mm/s

### **Barcode Scanner (Optional):**
- Type: USB or Bluetooth
- Format: EAN-13, Code 128, QR Code
- Speed: 100 scans/second

---

**End of Technical Specifications**
