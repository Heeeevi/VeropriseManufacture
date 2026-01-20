-- =====================================================
-- VEROPRISE ERP - COMPLETE DATABASE SCHEMA
-- Version: 1.0 - Production Ready
-- Description: Consolidated schema for retail ERP with 
--              inventory, multi-payment POS, HR & payroll
-- =====================================================

-- =====================================================
-- EXTENSIONS
-- =====================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- ENUMS - All type definitions
-- =====================================================

-- Core Enums
CREATE TYPE user_role AS ENUM ('owner', 'manager', 'staff', 'customer');
CREATE TYPE outlet_status AS ENUM ('active', 'inactive', 'maintenance');
CREATE TYPE transaction_status AS ENUM ('pending', 'completed', 'cancelled', 'refunded');
CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'completed', 'cancelled', 'no_show');
CREATE TYPE shift_type AS ENUM ('opening', 'closing', 'full_day');
CREATE TYPE expense_category AS ENUM ('operational', 'maintenance', 'marketing', 'salary', 'utilities', 'supplies', 'other');
CREATE TYPE inventory_transaction_type AS ENUM ('in', 'out', 'adjustment', 'waste', 'transfer', 'return');

-- Warehouse Enums
CREATE TYPE warehouse_type AS ENUM ('central', 'regional');
CREATE TYPE po_status AS ENUM ('draft', 'submitted', 'approved', 'received', 'cancelled');
CREATE TYPE stock_transfer_status AS ENUM ('draft', 'submitted', 'approved', 'in_transit', 'received', 'cancelled');
CREATE TYPE stock_opname_status AS ENUM ('draft', 'in_progress', 'completed', 'approved');

-- Payment Enums
CREATE TYPE payment_method AS ENUM ('cash', 'qris', 'transfer', 'olshop', 'debit_card', 'credit_card', 'other');
CREATE TYPE payment_status AS ENUM ('paid', 'partial', 'pending', 'refunded');

-- HR Enums
CREATE TYPE attendance_status AS ENUM ('present', 'late', 'absent', 'leave', 'sick', 'holiday', 'off');
CREATE TYPE target_type AS ENUM ('product_quantity', 'product_value', 'total_sales', 'category_sales');
CREATE TYPE target_period AS ENUM ('daily', 'weekly', 'monthly', 'quarterly');
CREATE TYPE incentive_type AS ENUM ('fixed', 'percentage', 'tiered');

-- =====================================================
-- CORE TABLES
-- =====================================================

-- Profiles table (extends auth.users)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    role user_role NOT NULL DEFAULT 'customer',
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Outlets table (Toko/Cabang)
CREATE TABLE outlets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    status outlet_status NOT NULL DEFAULT 'active',
    is_active BOOLEAN NOT NULL DEFAULT true,
    opening_time TIME,
    closing_time TIME,
    max_booking_days_ahead INTEGER DEFAULT 30,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- User outlets (many-to-many relationship)
CREATE TABLE user_outlets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    role user_role NOT NULL DEFAULT 'staff',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, outlet_id)
);

-- =====================================================
-- WAREHOUSE TABLES (Gudang Pusat)
-- =====================================================

-- Warehouses table (Gudang)
CREATE TABLE warehouses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    warehouse_type warehouse_type NOT NULL DEFAULT 'regional',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Suppliers table (Partner Vendors)
CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    contact_person TEXT,
    phone TEXT NOT NULL,
    email TEXT,
    address TEXT,
    tax_id TEXT,
    payment_terms INTEGER DEFAULT 30,
    credit_limit DECIMAL(15,2) DEFAULT 0,
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Categories table
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    color TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Products table
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    outlet_id UUID REFERENCES outlets(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(15,2) NOT NULL,
    cost DECIMAL(15,2) NOT NULL DEFAULT 0,
    sku TEXT,
    barcode TEXT,
    image_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_service BOOLEAN NOT NULL DEFAULT false,
    duration_minutes INTEGER DEFAULT 0,
    commission_rate DECIMAL(5,2) DEFAULT 0,
    stock_quantity INTEGER DEFAULT 0,
    min_stock INTEGER DEFAULT 0,
    max_stock INTEGER,
    reorder_point INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Warehouse inventory table (Stok di Gudang)
CREATE TABLE warehouse_inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity DECIMAL(15,2) NOT NULL DEFAULT 0,
    min_stock DECIMAL(15,2) NOT NULL DEFAULT 0,
    max_stock DECIMAL(15,2),
    last_restock_date TIMESTAMPTZ,
    cost_per_unit DECIMAL(15,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(warehouse_id, product_id)
);

-- Outlet Inventory table (Stok di Toko)
CREATE TABLE inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity DECIMAL(15,2) NOT NULL DEFAULT 0,
    min_quantity DECIMAL(15,2) NOT NULL DEFAULT 0,
    max_quantity DECIMAL(15,2),
    unit TEXT NOT NULL DEFAULT 'pcs',
    last_restock_date TIMESTAMPTZ,
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(outlet_id, product_id)
);

-- Inventory transactions table (Log pergerakan stok)
CREATE TABLE inventory_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    transaction_type inventory_transaction_type NOT NULL,
    quantity DECIMAL(15,2) NOT NULL,
    unit_cost DECIMAL(15,2),
    total_cost DECIMAL(15,2),
    reference_id UUID,
    reference_type TEXT, -- 'purchase_order', 'stock_transfer', 'sale', 'stock_opname', etc.
    notes TEXT,
    performed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- PURCHASE ORDER (Barang dari Supplier → Gudang)
-- =====================================================

-- Purchase orders table
CREATE TABLE purchase_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    po_number TEXT NOT NULL UNIQUE,
    warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE RESTRICT,
    supplier_id UUID REFERENCES suppliers(id) ON DELETE RESTRICT,
    supplier_name TEXT,
    status po_status NOT NULL DEFAULT 'draft',
    total_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    ordered_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    ordered_date DATE NOT NULL DEFAULT CURRENT_DATE,
    approved_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    approved_date TIMESTAMPTZ,
    received_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    received_date TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Purchase order items table
CREATE TABLE purchase_order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    purchase_order_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity DECIMAL(15,2) NOT NULL,
    unit_price DECIMAL(15,2) NOT NULL,
    subtotal DECIMAL(15,2) NOT NULL,
    received_quantity DECIMAL(15,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- STOCK TRANSFER (Gudang → Toko)
-- =====================================================

-- Stock transfer orders table
CREATE TABLE stock_transfer_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transfer_number TEXT NOT NULL UNIQUE,
    from_warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE RESTRICT,
    to_outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE RESTRICT,
    status stock_transfer_status NOT NULL DEFAULT 'draft',
    requested_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    requested_date DATE NOT NULL DEFAULT CURRENT_DATE,
    approved_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    approved_date TIMESTAMPTZ,
    sent_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    sent_date TIMESTAMPTZ,
    received_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    received_date TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Stock transfer items table
CREATE TABLE stock_transfer_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stock_transfer_order_id UUID NOT NULL REFERENCES stock_transfer_orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity_requested DECIMAL(15,2) NOT NULL,
    quantity_sent DECIMAL(15,2) DEFAULT 0,
    quantity_received DECIMAL(15,2) DEFAULT 0,
    unit_cost DECIMAL(15,2) NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- STOCK OPNAME (Audit Stok Bulanan)
-- =====================================================

-- Stock opname table (Warehouse or Outlet)
CREATE TABLE stock_opname (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    opname_number TEXT NOT NULL UNIQUE,
    warehouse_id UUID REFERENCES warehouses(id) ON DELETE CASCADE,
    outlet_id UUID REFERENCES outlets(id) ON DELETE CASCADE,
    opname_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status stock_opname_status NOT NULL DEFAULT 'draft',
    performed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    approved_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    approved_date TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (warehouse_id IS NOT NULL OR outlet_id IS NOT NULL)
);

-- Stock opname items table
CREATE TABLE stock_opname_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stock_opname_id UUID NOT NULL REFERENCES stock_opname(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    system_quantity DECIMAL(15,2) NOT NULL,
    physical_quantity DECIMAL(15,2) NOT NULL,
    difference DECIMAL(15,2) GENERATED ALWAYS AS (physical_quantity - system_quantity) STORED,
    unit_cost DECIMAL(15,2) NOT NULL,
    total_loss DECIMAL(15,2) GENERATED ALWAYS AS ((physical_quantity - system_quantity) * unit_cost) STORED,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- EMPLOYEES & HR
-- =====================================================

-- Employees table
CREATE TABLE employees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    employee_code TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    address TEXT,
    position TEXT NOT NULL,
    hire_date DATE NOT NULL,
    resign_date DATE,
    basic_salary DECIMAL(15,2) NOT NULL DEFAULT 0,
    overtime_rate DECIMAL(15,2) DEFAULT 0,
    allowance_transport DECIMAL(15,2) DEFAULT 0,
    allowance_meal DECIMAL(15,2) DEFAULT 0,
    allowance_other DECIMAL(15,2) DEFAULT 0,
    tax_id TEXT,
    bank_account TEXT,
    bank_name TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    photo_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Shifts table
CREATE TABLE shifts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    shift_date DATE NOT NULL,
    shift_type shift_type NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Attendance table (Absensi)
CREATE TABLE attendances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    attendance_date DATE NOT NULL,
    shift_id UUID REFERENCES shifts(id) ON DELETE SET NULL,
    check_in TIMESTAMPTZ,
    check_out TIMESTAMPTZ,
    status attendance_status NOT NULL DEFAULT 'present',
    hours_worked DECIMAL(5,2) DEFAULT 0,
    overtime_hours DECIMAL(5,2) DEFAULT 0,
    late_duration_minutes INTEGER DEFAULT 0,
    break_start TIMESTAMPTZ,
    break_end TIMESTAMPTZ,
    break_duration_minutes INTEGER DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(employee_id, attendance_date)
);

-- =====================================================
-- SALES TARGETS & INCENTIVES (Bonus Kinerja)
-- =====================================================

-- Sales targets table
CREATE TABLE sales_targets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    target_name TEXT NOT NULL,
    target_type target_type NOT NULL,
    target_period target_period NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    target_date DATE NOT NULL DEFAULT CURRENT_DATE,
    target_amount DECIMAL(15,2) DEFAULT 0,
    target_quantity DECIMAL(15,2),
    target_value DECIMAL(15,2),
    incentive_type incentive_type NOT NULL DEFAULT 'fixed',
    fixed_amount DECIMAL(15,2) DEFAULT 0,
    percentage_rate DECIMAL(5,2) DEFAULT 0,
    tiers JSONB, -- [{\"min\": 100, \"max\": 200, \"amount\": 50000}, ...]
    period_type TEXT DEFAULT 'monthly',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Employee incentives table (calculated results)
CREATE TABLE employee_incentives (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sales_target_id UUID NOT NULL REFERENCES sales_targets(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    achieved_quantity DECIMAL(15,2) DEFAULT 0,
    achieved_value DECIMAL(15,2) DEFAULT 0,
    target_quantity DECIMAL(15,2),
    target_value DECIMAL(15,2),
    achievement_percentage DECIMAL(5,2) DEFAULT 0,
    incentive_amount DECIMAL(15,2) DEFAULT 0,
    is_paid BOOLEAN DEFAULT false,
    paid_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(sales_target_id, employee_id, period_start, period_end)
);

-- Employee bonuses table (Manual bonuses)
CREATE TABLE employee_bonuses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    bonus_type TEXT NOT NULL, -- 'performance', 'target_achievement', 'attendance', 'thr', 'other'
    amount DECIMAL(15,2) NOT NULL,
    description TEXT,
    achievement_date DATE NOT NULL,
    is_paid BOOLEAN DEFAULT false,
    paid_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- TRANSACTIONS & MULTI-PAYMENT (POS)
-- =====================================================

-- Transactions table (POS sales)
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    employee_id UUID REFERENCES employees(id) ON DELETE SET NULL,
    customer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    transaction_number TEXT NOT NULL UNIQUE,
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    subtotal DECIMAL(15,2) NOT NULL DEFAULT 0,
    tax DECIMAL(15,2) NOT NULL DEFAULT 0,
    discount DECIMAL(15,2) NOT NULL DEFAULT 0,
    total DECIMAL(15,2) NOT NULL DEFAULT 0,
    status transaction_status NOT NULL DEFAULT 'pending',
    payment_method payment_method,
    payment_status payment_status DEFAULT 'pending',
    total_paid DECIMAL(15,2) DEFAULT 0,
    remaining_amount DECIMAL(15,2) DEFAULT 0,
    is_multi_payment BOOLEAN DEFAULT false,
    is_split_payment BOOLEAN DEFAULT false,
    payment_details JSONB, -- [{method: 'cash', amount: 50000}, {method: 'qris', amount: 30000}]
    notes TEXT,
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Transaction items table
CREATE TABLE transaction_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    employee_id UUID REFERENCES employees(id) ON DELETE SET NULL,
    product_name TEXT,
    quantity DECIMAL(15,2) NOT NULL,
    unit_price DECIMAL(15,2) NOT NULL,
    cost_price DECIMAL(15,2) DEFAULT 0,
    discount DECIMAL(15,2) NOT NULL DEFAULT 0,
    subtotal DECIMAL(15,2) NOT NULL,
    commission_amount DECIMAL(15,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Transaction payments table (multiple payments per transaction)
CREATE TABLE transaction_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    payment_method payment_method NOT NULL,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    payment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reference_number TEXT,
    card_number_last4 TEXT,
    bank_name TEXT,
    notes TEXT,
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- DAILY CLOSING (Laporan Harian)
-- =====================================================

-- Daily closings table
CREATE TABLE daily_closings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    closing_date DATE NOT NULL,
    total_sales DECIMAL(15,2) NOT NULL DEFAULT 0,
    cash_sales DECIMAL(15,2) NOT NULL DEFAULT 0,
    qris_sales DECIMAL(15,2) DEFAULT 0,
    transfer_sales DECIMAL(15,2) DEFAULT 0,
    olshop_sales DECIMAL(15,2) DEFAULT 0,
    total_expenses DECIMAL(15,2) NOT NULL DEFAULT 0,
    cash_to_deposit DECIMAL(15,2) NOT NULL DEFAULT 0, -- Uang setor = Cash Sales - Expenses
    closing_cash DECIMAL(15,2) NOT NULL DEFAULT 0,    -- Uang fisik (aktual)
    discrepancy DECIMAL(15,2) DEFAULT 0,              -- Selisih
    closed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(outlet_id, closing_date)
);

-- Daily closing reports table (Alternative view)
CREATE TABLE daily_closing_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_number TEXT NOT NULL UNIQUE,
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    closing_date DATE NOT NULL,
    total_sales DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_transactions INTEGER NOT NULL DEFAULT 0,
    cash_in_register DECIMAL(15,2) NOT NULL DEFAULT 0,
    expected_cash DECIMAL(15,2) NOT NULL DEFAULT 0,
    cash_difference DECIMAL(15,2) GENERATED ALWAYS AS (cash_in_register - expected_cash) STORED,
    total_cash DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_qris DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_transfer DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_olshop DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_debit_card DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_credit_card DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_other DECIMAL(15,2) NOT NULL DEFAULT 0,
    bank_deposit_amount DECIMAL(15,2) DEFAULT 0,
    bank_deposit_proof TEXT,
    closed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(outlet_id, closing_date)
);

-- =====================================================
-- BOOKINGS & EXPENSES
-- =====================================================

-- Bookings table
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    employee_id UUID REFERENCES employees(id) ON DELETE SET NULL,
    product_id UUID REFERENCES products(id) ON DELETE RESTRICT,
    booking_number TEXT NOT NULL UNIQUE,
    customer_name TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    customer_email TEXT,
    booking_date DATE NOT NULL,
    booking_time TIME NOT NULL,
    end_time TIME,
    status booking_status NOT NULL DEFAULT 'pending',
    payment_status TEXT DEFAULT 'unpaid',
    payment_amount DECIMAL(15,2) DEFAULT 0,
    notes TEXT,
    reminder_sent BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Expenses table
CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    category expense_category NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    description TEXT NOT NULL,
    expense_date DATE NOT NULL,
    status TEXT DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    receipt_url TEXT,
    approved_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,
    created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- INDEXES
-- =====================================================

-- Core indexes
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_user_outlets_user ON user_outlets(user_id);
CREATE INDEX idx_user_outlets_outlet ON user_outlets(outlet_id);
CREATE INDEX idx_employees_outlet ON employees(outlet_id);
CREATE INDEX idx_employees_user ON employees(user_id);

-- Product & Inventory indexes
CREATE INDEX idx_products_outlet ON products(outlet_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_inventory_outlet_product ON inventory(outlet_id, product_id);
CREATE INDEX idx_inventory_transactions_outlet ON inventory_transactions(outlet_id);
CREATE INDEX idx_inventory_transactions_product ON inventory_transactions(product_id);
CREATE INDEX idx_warehouse_inventory_warehouse ON warehouse_inventory(warehouse_id);
CREATE INDEX idx_warehouse_inventory_product ON warehouse_inventory(product_id);

-- Purchase & Transfer indexes
CREATE INDEX idx_purchase_orders_warehouse ON purchase_orders(warehouse_id);
CREATE INDEX idx_purchase_orders_supplier ON purchase_orders(supplier_id);
CREATE INDEX idx_purchase_orders_status ON purchase_orders(status);
CREATE INDEX idx_purchase_order_items_po ON purchase_order_items(purchase_order_id);
CREATE INDEX idx_stock_transfer_orders_warehouse ON stock_transfer_orders(from_warehouse_id);
CREATE INDEX idx_stock_transfer_orders_outlet ON stock_transfer_orders(to_outlet_id);
CREATE INDEX idx_stock_transfer_orders_status ON stock_transfer_orders(status);
CREATE INDEX idx_stock_opname_warehouse ON stock_opname(warehouse_id);
CREATE INDEX idx_stock_opname_outlet ON stock_opname(outlet_id);

-- Transaction indexes
CREATE INDEX idx_transactions_outlet_date ON transactions(outlet_id, transaction_date);
CREATE INDEX idx_transactions_employee ON transactions(employee_id);
CREATE INDEX idx_transactions_payment_status ON transactions(payment_status);
CREATE INDEX idx_transaction_items_transaction ON transaction_items(transaction_id);
CREATE INDEX idx_transaction_items_product ON transaction_items(product_id);
CREATE INDEX idx_transaction_payments_transaction ON transaction_payments(transaction_id);
CREATE INDEX idx_transaction_payments_method ON transaction_payments(payment_method);

-- HR indexes
CREATE INDEX idx_shifts_outlet_date ON shifts(outlet_id, shift_date);
CREATE INDEX idx_shifts_employee ON shifts(employee_id);
CREATE INDEX idx_attendance_employee_date ON attendances(employee_id, attendance_date);
CREATE INDEX idx_attendance_outlet_date ON attendances(outlet_id, attendance_date);
CREATE INDEX idx_attendance_status ON attendances(status);
CREATE INDEX idx_sales_targets_outlet ON sales_targets(outlet_id);
CREATE INDEX idx_sales_targets_employee ON sales_targets(employee_id);
CREATE INDEX idx_employee_incentives_employee ON employee_incentives(employee_id);

-- Report indexes
CREATE INDEX idx_daily_closing_outlet_date ON daily_closings(outlet_id, closing_date);
CREATE INDEX idx_daily_closing_reports_outlet_date ON daily_closing_reports(outlet_id, closing_date);
CREATE INDEX idx_bookings_outlet_date ON bookings(outlet_id, booking_date);
CREATE INDEX idx_expenses_outlet_date ON expenses(outlet_id, expense_date);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Updated at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_outlets_updated_at BEFORE UPDATE ON outlets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON employees
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_shifts_updated_at BEFORE UPDATE ON shifts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_inventory_updated_at BEFORE UPDATE ON inventory
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_expenses_updated_at BEFORE UPDATE ON expenses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_warehouses_updated_at BEFORE UPDATE ON warehouses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_warehouse_inventory_updated_at BEFORE UPDATE ON warehouse_inventory
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_suppliers_updated_at BEFORE UPDATE ON suppliers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_purchase_orders_updated_at BEFORE UPDATE ON purchase_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_stock_transfer_orders_updated_at BEFORE UPDATE ON stock_transfer_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_stock_opname_updated_at BEFORE UPDATE ON stock_opname
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_attendances_updated_at BEFORE UPDATE ON attendances
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_sales_targets_updated_at BEFORE UPDATE ON sales_targets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_employee_incentives_updated_at BEFORE UPDATE ON employee_incentives
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_transaction_payments_updated_at BEFORE UPDATE ON transaction_payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_daily_closings_updated_at BEFORE UPDATE ON daily_closings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_daily_closing_reports_updated_at BEFORE UPDATE ON daily_closing_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCTIONS - INVENTORY AUTOMATION
-- =====================================================

-- Function to update warehouse inventory after PO received
-- (Supplier → Gudang: Stock gudang otomatis bertambah)
CREATE OR REPLACE FUNCTION update_warehouse_inventory_from_po()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'received' AND OLD.status != 'received' THEN
        INSERT INTO warehouse_inventory (warehouse_id, product_id, quantity, cost_per_unit)
        SELECT 
            NEW.warehouse_id,
            poi.product_id,
            poi.received_quantity,
            poi.unit_price
        FROM purchase_order_items poi
        WHERE poi.purchase_order_id = NEW.id
        ON CONFLICT (warehouse_id, product_id) 
        DO UPDATE SET
            quantity = warehouse_inventory.quantity + EXCLUDED.quantity,
            cost_per_unit = EXCLUDED.cost_per_unit,
            last_restock_date = NOW(),
            updated_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_warehouse_inventory_from_po
AFTER UPDATE ON purchase_orders
FOR EACH ROW EXECUTE FUNCTION update_warehouse_inventory_from_po();

-- Function to update inventories after stock transfer received
-- (Gudang → Toko: Stock gudang berkurang, stock toko bertambah)
CREATE OR REPLACE FUNCTION update_inventory_from_stock_transfer()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'received' AND OLD.status != 'received' THEN
        -- Decrease warehouse inventory
        UPDATE warehouse_inventory
        SET quantity = quantity - sti.quantity_received,
            updated_at = NOW()
        FROM stock_transfer_items sti
        WHERE sti.stock_transfer_order_id = NEW.id
            AND warehouse_inventory.warehouse_id = NEW.from_warehouse_id
            AND warehouse_inventory.product_id = sti.product_id;
            
        -- Increase outlet inventory
        INSERT INTO inventory (outlet_id, product_id, quantity)
        SELECT 
            NEW.to_outlet_id,
            sti.product_id,
            sti.quantity_received
        FROM stock_transfer_items sti
        WHERE sti.stock_transfer_order_id = NEW.id
        ON CONFLICT (outlet_id, product_id)
        DO UPDATE SET
            quantity = inventory.quantity + EXCLUDED.quantity,
            last_restock_date = NOW(),
            updated_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_inventory_from_stock_transfer
AFTER UPDATE ON stock_transfer_orders
FOR EACH ROW EXECUTE FUNCTION update_inventory_from_stock_transfer();

-- Function to apply stock opname adjustments
CREATE OR REPLACE FUNCTION apply_stock_opname_adjustments()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'approved' AND OLD.status != 'approved' THEN
        -- Update warehouse inventory if opname is for warehouse
        IF NEW.warehouse_id IS NOT NULL THEN
            UPDATE warehouse_inventory
            SET quantity = soi.physical_quantity,
                updated_at = NOW()
            FROM stock_opname_items soi
            WHERE soi.stock_opname_id = NEW.id
                AND warehouse_inventory.warehouse_id = NEW.warehouse_id
                AND warehouse_inventory.product_id = soi.product_id;
        END IF;
        
        -- Update outlet inventory if opname is for outlet
        IF NEW.outlet_id IS NOT NULL THEN
            UPDATE inventory
            SET quantity = soi.physical_quantity,
                updated_at = NOW()
            FROM stock_opname_items soi
            WHERE soi.stock_opname_id = NEW.id
                AND inventory.outlet_id = NEW.outlet_id
                AND inventory.product_id = soi.product_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_apply_stock_opname_adjustments
AFTER UPDATE ON stock_opname
FOR EACH ROW EXECUTE FUNCTION apply_stock_opname_adjustments();

-- =====================================================
-- FUNCTIONS - PAYMENT AUTOMATION
-- =====================================================

-- Function to update transaction payment status
CREATE OR REPLACE FUNCTION update_transaction_payment_status()
RETURNS TRIGGER AS $$
DECLARE
    v_total_paid DECIMAL(15,2);
    v_remaining DECIMAL(15,2);
    v_transaction_total DECIMAL(15,2);
    v_payment_count INTEGER;
    v_new_status payment_status;
BEGIN
    SELECT total INTO v_transaction_total
    FROM transactions
    WHERE id = COALESCE(NEW.transaction_id, OLD.transaction_id);
    
    SELECT COALESCE(SUM(amount), 0), COUNT(*)
    INTO v_total_paid, v_payment_count
    FROM transaction_payments
    WHERE transaction_id = COALESCE(NEW.transaction_id, OLD.transaction_id);
    
    v_remaining := v_transaction_total - v_total_paid;
    
    IF v_total_paid = 0 THEN
        v_new_status := 'pending';
    ELSIF v_total_paid >= v_transaction_total THEN
        v_new_status := 'paid';
        v_remaining := 0;
    ELSE
        v_new_status := 'partial';
    END IF;
    
    UPDATE transactions
    SET 
        total_paid = v_total_paid,
        remaining_amount = v_remaining,
        payment_status = v_new_status,
        is_multi_payment = (v_payment_count > 1),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.transaction_id, OLD.transaction_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_transaction_payment_status_insert
AFTER INSERT ON transaction_payments FOR EACH ROW
EXECUTE FUNCTION update_transaction_payment_status();

CREATE TRIGGER trigger_update_transaction_payment_status_update
AFTER UPDATE ON transaction_payments FOR EACH ROW
EXECUTE FUNCTION update_transaction_payment_status();

CREATE TRIGGER trigger_update_transaction_payment_status_delete
AFTER DELETE ON transaction_payments FOR EACH ROW
EXECUTE FUNCTION update_transaction_payment_status();

-- =====================================================
-- FUNCTIONS - HR AUTOMATION
-- =====================================================

-- Auto-create attendance from shift
CREATE OR REPLACE FUNCTION auto_create_attendance_from_shift()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO attendances (employee_id, outlet_id, attendance_date, shift_id, status)
    VALUES (NEW.employee_id, NEW.outlet_id, NEW.shift_date, NEW.id, 'present')
    ON CONFLICT (employee_id, attendance_date) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_create_attendance
AFTER INSERT ON shifts FOR EACH ROW
EXECUTE FUNCTION auto_create_attendance_from_shift();

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE outlets ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_outlets ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE warehouses ENABLE ROW LEVEL SECURITY;
ALTER TABLE warehouse_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_transfer_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_transfer_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_opname ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_opname_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendances ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_targets ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_incentives ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_bonuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_closings ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_closing_reports ENABLE ROW LEVEL SECURITY;

-- Basic RLS Policies (permissive for development)
CREATE POLICY "All users can view categories" ON categories FOR SELECT USING (true);
CREATE POLICY "Authenticated users can manage data" ON profiles FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage outlets" ON outlets FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage user_outlets" ON user_outlets FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage employees" ON employees FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage shifts" ON shifts FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage categories" ON categories FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage products" ON products FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage inventory" ON inventory FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage inventory_transactions" ON inventory_transactions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage transactions" ON transactions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage transaction_items" ON transaction_items FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage transaction_payments" ON transaction_payments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage bookings" ON bookings FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage expenses" ON expenses FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage warehouses" ON warehouses FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage warehouse_inventory" ON warehouse_inventory FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage suppliers" ON suppliers FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage purchase_orders" ON purchase_orders FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage purchase_order_items" ON purchase_order_items FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage stock_transfer_orders" ON stock_transfer_orders FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage stock_transfer_items" ON stock_transfer_items FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage stock_opname" ON stock_opname FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage stock_opname_items" ON stock_opname_items FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage attendances" ON attendances FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage sales_targets" ON sales_targets FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage employee_incentives" ON employee_incentives FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage employee_bonuses" ON employee_bonuses FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage daily_closings" ON daily_closings FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage daily_closing_reports" ON daily_closing_reports FOR ALL USING (true) WITH CHECK (true);

-- =====================================================
-- HELPER VIEWS
-- =====================================================

-- Daily payment summary view
CREATE OR REPLACE VIEW daily_payment_summary AS
SELECT 
    t.outlet_id,
    DATE(t.transaction_date) as transaction_date,
    tp.payment_method,
    COUNT(DISTINCT t.id) as transaction_count,
    SUM(tp.amount) as total_amount
FROM transactions t
INNER JOIN transaction_payments tp ON tp.transaction_id = t.id
WHERE t.status = 'completed'
GROUP BY t.outlet_id, DATE(t.transaction_date), tp.payment_method;

-- Attendance summary view
CREATE OR REPLACE VIEW attendance_summary AS
SELECT 
    e.id as employee_id,
    e.full_name as employee_name,
    a.outlet_id,
    DATE_TRUNC('month', a.attendance_date) as month,
    COUNT(*) FILTER (WHERE a.status = 'present') as present_days,
    COUNT(*) FILTER (WHERE a.status = 'late') as late_days,
    COUNT(*) FILTER (WHERE a.status = 'absent') as absent_days,
    COUNT(*) FILTER (WHERE a.status = 'leave') as leave_days,
    COUNT(*) FILTER (WHERE a.status = 'sick') as sick_days,
    SUM(a.hours_worked) as total_hours,
    SUM(a.overtime_hours) as total_overtime
FROM attendances a
INNER JOIN employees e ON e.id = a.employee_id
GROUP BY e.id, e.full_name, a.outlet_id, DATE_TRUNC('month', a.attendance_date);

-- =====================================================
-- SCHEMA VERSION
-- =====================================================

COMMENT ON DATABASE postgres IS 'Veroprise ERP - Complete Schema v1.0';
