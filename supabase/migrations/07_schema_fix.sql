-- =====================================================
-- VEROPRISE ERP - SCHEMA FIX
-- Harus dijalankan KETUJUH setelah 06_rls_policy_fix.sql
-- Menambahkan tabel dan kolom yang kurang
-- =====================================================

-- =====================================================
-- POS_SHIFTS - Untuk shift kasir di POS
-- =====================================================
CREATE TABLE IF NOT EXISTS pos_shifts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE SET NULL,
    opening_cash DECIMAL(15,2) NOT NULL DEFAULT 0,
    closing_cash DECIMAL(15,2),
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index
CREATE INDEX IF NOT EXISTS idx_pos_shifts_outlet ON pos_shifts(outlet_id);
CREATE INDEX IF NOT EXISTS idx_pos_shifts_user ON pos_shifts(user_id);
CREATE INDEX IF NOT EXISTS idx_pos_shifts_active ON pos_shifts(outlet_id, user_id) WHERE ended_at IS NULL;

-- Trigger for updated_at
CREATE TRIGGER update_pos_shifts_updated_at 
    BEFORE UPDATE ON pos_shifts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS for pos_shifts
ALTER TABLE pos_shifts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own shifts" ON pos_shifts FOR SELECT
USING (user_id = auth.uid() OR EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')
));

CREATE POLICY "Users can insert their own shifts" ON pos_shifts FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own shifts" ON pos_shifts FOR UPDATE
USING (user_id = auth.uid() OR EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')
));

-- =====================================================
-- Add missing columns to transactions table
-- =====================================================
ALTER TABLE transactions 
ADD COLUMN IF NOT EXISTS shift_id UUID REFERENCES pos_shifts(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'cash';

-- =====================================================
-- Add missing columns to bookings table for frontend compatibility
-- =====================================================
-- The bookings table already has booking_date and booking_time
-- Add payment_amount and payment_method if not exists
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS payment_amount DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS payment_method TEXT,
ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'unpaid',
ADD COLUMN IF NOT EXISTS confirmed_by UUID REFERENCES profiles(id),
ADD COLUMN IF NOT EXISTS confirmed_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS transaction_id UUID REFERENCES transactions(id);

-- =====================================================
-- PAYROLL tables for HR module
-- =====================================================
CREATE TABLE IF NOT EXISTS payroll_runs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    period TEXT NOT NULL, -- Format: YYYY-MM
    total_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'draft', -- draft, paid
    created_by UUID REFERENCES profiles(id),
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(outlet_id, period)
);

CREATE TABLE IF NOT EXISTS payroll_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payroll_run_id UUID NOT NULL REFERENCES payroll_runs(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    base_salary DECIMAL(15,2) NOT NULL DEFAULT 0,
    allowances DECIMAL(15,2) NOT NULL DEFAULT 0,
    deductions DECIMAL(15,2) NOT NULL DEFAULT 0,
    net_salary DECIMAL(15,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS for payroll tables
ALTER TABLE payroll_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view payroll in their outlets" ON payroll_runs FOR SELECT
USING (EXISTS (
    SELECT 1 FROM user_outlets WHERE user_id = auth.uid() AND outlet_id = payroll_runs.outlet_id
) OR EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')
));

CREATE POLICY "Owners can manage payroll" ON payroll_runs FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

CREATE POLICY "Users can view payroll items" ON payroll_items FOR SELECT
USING (EXISTS (
    SELECT 1 FROM payroll_runs pr 
    WHERE pr.id = payroll_items.payroll_run_id
    AND EXISTS (
        SELECT 1 FROM user_outlets WHERE user_id = auth.uid() AND outlet_id = pr.outlet_id
    )
));

CREATE POLICY "Owners can manage payroll items" ON payroll_items FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

-- =====================================================
-- EXPENSE_CATEGORIES table for categorizing expenses
-- =====================================================
CREATE TABLE IF NOT EXISTS expense_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add category_id to expenses if not exists
ALTER TABLE expenses 
ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES expense_categories(id);

-- RLS for expense_categories
ALTER TABLE expense_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view expense categories" ON expense_categories FOR SELECT
USING (true);

CREATE POLICY "Owners can manage expense categories" ON expense_categories FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

COMMENT ON SCHEMA public IS 'Veroprise ERP - Schema Fix v1.0';
