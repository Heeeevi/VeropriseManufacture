-- =====================================================
-- COMPREHENSIVE SCHEMA FIX - Run this if you have missing tables/columns
-- =====================================================

-- 1. POS SHIFTS TABLE
CREATE TABLE IF NOT EXISTS pos_shifts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    opening_cash DECIMAL(15,2) NOT NULL DEFAULT 0,
    closing_cash DECIMAL(15,2),
    expected_cash DECIMAL(15,2),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE pos_shifts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view pos_shifts" ON pos_shifts;
CREATE POLICY "Users can view pos_shifts" ON pos_shifts FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage pos_shifts" ON pos_shifts;
CREATE POLICY "Users can manage pos_shifts" ON pos_shifts FOR ALL USING (true) WITH CHECK (true);

-- 2. TRANSACTIONS - Add split payment columns
ALTER TABLE transactions 
ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'cash',
ADD COLUMN IF NOT EXISTS payment_details JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS deposit_amount DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS balance_due DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_split_payment BOOLEAN DEFAULT false;

-- 3. PURCHASE ORDERS - Make po_number nullable or add default
ALTER TABLE purchase_orders 
ALTER COLUMN po_number DROP NOT NULL;

-- Or set a default
-- ALTER TABLE purchase_orders ALTER COLUMN po_number SET DEFAULT 'PO-' || to_char(NOW(), 'YYYYMMDD-HH24MISS');

-- 4. WAREHOUSES TABLE
CREATE TABLE IF NOT EXISTS warehouses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    address TEXT,
    warehouse_type TEXT NOT NULL DEFAULT 'central',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE warehouses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view warehouses" ON warehouses;
CREATE POLICY "Users can view warehouses" ON warehouses FOR SELECT USING (true);

DROP POLICY IF EXISTS "Managers can manage warehouses" ON warehouses;
CREATE POLICY "Managers can manage warehouses" ON warehouses FOR ALL 
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

-- 5. WAREHOUSE INVENTORY
CREATE TABLE IF NOT EXISTS warehouse_inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity DECIMAL(15,2) NOT NULL DEFAULT 0,
    min_stock DECIMAL(15,2) NOT NULL DEFAULT 0,
    cost_per_unit DECIMAL(15,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(warehouse_id, product_id)
);

ALTER TABLE warehouse_inventory ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view warehouse_inventory" ON warehouse_inventory;
CREATE POLICY "Users can view warehouse_inventory" ON warehouse_inventory FOR SELECT USING (true);

DROP POLICY IF EXISTS "Managers can manage warehouse_inventory" ON warehouse_inventory;
CREATE POLICY "Managers can manage warehouse_inventory" ON warehouse_inventory FOR ALL USING (true) WITH CHECK (true);

-- 6. STOCK TRANSFERS
CREATE TABLE IF NOT EXISTS stock_transfers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_warehouse_id UUID REFERENCES warehouses(id),
    destination_outlet_id UUID REFERENCES outlets(id),
    status TEXT NOT NULL DEFAULT 'pending',
    transfer_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE stock_transfers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view stock_transfers" ON stock_transfers;
CREATE POLICY "Users can view stock_transfers" ON stock_transfers FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage stock_transfers" ON stock_transfers;
CREATE POLICY "Users can manage stock_transfers" ON stock_transfers FOR ALL USING (true) WITH CHECK (true);

-- 7. SUPPLIERS TABLE
CREATE TABLE IF NOT EXISTS suppliers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    contact_person TEXT,
    phone TEXT,
    email TEXT,
    address TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view suppliers" ON suppliers;
CREATE POLICY "Users can view suppliers" ON suppliers FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage suppliers" ON suppliers;
CREATE POLICY "Users can manage suppliers" ON suppliers FOR ALL USING (true) WITH CHECK (true);

-- 8. SALES TARGETS
CREATE TABLE IF NOT EXISTS sales_targets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    outlet_id UUID REFERENCES outlets(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    target_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    target_date DATE NOT NULL,
    period_type TEXT NOT NULL DEFAULT 'monthly',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE sales_targets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view sales_targets" ON sales_targets;
CREATE POLICY "Users can view sales_targets" ON sales_targets FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage sales_targets" ON sales_targets;
CREATE POLICY "Users can manage sales_targets" ON sales_targets FOR ALL USING (true) WITH CHECK (true);

-- 9. EMPLOYEE BONUSES
CREATE TABLE IF NOT EXISTS employee_bonuses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    payroll_item_id UUID,
    bonus_type TEXT NOT NULL,
    description TEXT,
    amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    achievement_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE employee_bonuses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view employee_bonuses" ON employee_bonuses;
CREATE POLICY "Users can view employee_bonuses" ON employee_bonuses FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage employee_bonuses" ON employee_bonuses;
CREATE POLICY "Users can manage employee_bonuses" ON employee_bonuses FOR ALL USING (true) WITH CHECK (true);

-- 10. ATTENDANCES
CREATE TABLE IF NOT EXISTS attendances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    shift_id UUID REFERENCES pos_shifts(id) ON DELETE SET NULL,
    attendance_date DATE NOT NULL DEFAULT CURRENT_DATE,
    check_in TIMESTAMPTZ,
    check_out TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'present',
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(employee_id, attendance_date)
);

ALTER TABLE attendances ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view attendances" ON attendances;
CREATE POLICY "Users can view attendances" ON attendances FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage attendances" ON attendances;
CREATE POLICY "Users can manage attendances" ON attendances FOR ALL USING (true) WITH CHECK (true);

-- 11. DAILY CLOSINGS
CREATE TABLE IF NOT EXISTS daily_closings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    shift_id UUID REFERENCES pos_shifts(id) ON DELETE SET NULL,
    closing_date DATE NOT NULL,
    total_sales DECIMAL(15,2) NOT NULL DEFAULT 0,
    cash_sales DECIMAL(15,2) NOT NULL DEFAULT 0,
    qris_sales DECIMAL(15,2) NOT NULL DEFAULT 0,
    transfer_sales DECIMAL(15,2) NOT NULL DEFAULT 0,
    olshop_sales DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_expenses DECIMAL(15,2) NOT NULL DEFAULT 0,
    cash_to_deposit DECIMAL(15,2) NOT NULL DEFAULT 0,
    opening_cash DECIMAL(15,2) NOT NULL DEFAULT 0,
    closing_cash DECIMAL(15,2) NOT NULL DEFAULT 0,
    discrepancy DECIMAL(15,2) NOT NULL DEFAULT 0,
    stock_snapshot JSONB DEFAULT '[]'::jsonb,
    closed_by UUID REFERENCES profiles(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(outlet_id, closing_date)
);

ALTER TABLE daily_closings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view daily_closings" ON daily_closings;
CREATE POLICY "Users can view daily_closings" ON daily_closings FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage daily_closings" ON daily_closings;
CREATE POLICY "Users can manage daily_closings" ON daily_closings FOR ALL USING (true) WITH CHECK (true);

-- 12. STOCK OPNAMES
CREATE TABLE IF NOT EXISTS stock_opnames (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warehouse_id UUID REFERENCES warehouses(id) ON DELETE CASCADE,
    opname_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status TEXT NOT NULL DEFAULT 'draft',
    notes TEXT,
    created_by UUID REFERENCES profiles(id),
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE stock_opnames ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view stock_opnames" ON stock_opnames;
CREATE POLICY "Users can view stock_opnames" ON stock_opnames FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage stock_opnames" ON stock_opnames;
CREATE POLICY "Users can manage stock_opnames" ON stock_opnames FOR ALL USING (true) WITH CHECK (true);

-- 13. Insert sample warehouse if none exists
INSERT INTO warehouses (code, name, warehouse_type) 
SELECT 'WH-CENTRAL', 'Gudang Pusat', 'central'
WHERE NOT EXISTS (SELECT 1 FROM warehouses WHERE code = 'WH-CENTRAL');

COMMENT ON SCHEMA public IS 'Veroprise ERP - Complete Schema Fix v2.0';
