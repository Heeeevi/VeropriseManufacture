-- =====================================================
-- VEROPRISE ERP - MULTI-PAYMENT SYSTEM
-- Harus dijalankan KETIGA setelah 02_warehouse_system.sql
-- =====================================================

-- =====================================================
-- ENUMS
-- =====================================================

CREATE TYPE payment_method AS ENUM ('cash', 'qris', 'transfer', 'olshop', 'debit_card', 'credit_card', 'other');
CREATE TYPE payment_status AS ENUM ('paid', 'partial', 'pending', 'refunded');

-- =====================================================
-- ALTER EXISTING TABLES
-- =====================================================

-- Add payment status and multi-payment fields to transactions table
ALTER TABLE transactions 
ADD COLUMN IF NOT EXISTS payment_status payment_status DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS payment_method payment_method, -- Legacy field
ADD COLUMN IF NOT EXISTS total_paid DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS remaining_amount DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_multi_payment BOOLEAN DEFAULT false;

-- =====================================================
-- NEW TABLES
-- =====================================================

-- Transaction payments table (multiple payments per transaction)
CREATE TABLE transaction_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    payment_method payment_method NOT NULL,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    payment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Payment-specific details
    reference_number TEXT,
    card_number_last4 TEXT,
    bank_name TEXT,
    notes TEXT,
    
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX idx_transaction_payments_transaction ON transaction_payments(transaction_id);
CREATE INDEX idx_transaction_payments_method ON transaction_payments(payment_method);
CREATE INDEX idx_transaction_payments_date ON transaction_payments(payment_date);
CREATE INDEX idx_transactions_payment_status ON transactions(payment_status);

-- =====================================================
-- TRIGGERS
-- =====================================================

CREATE TRIGGER update_transaction_payments_updated_at BEFORE UPDATE ON transaction_payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function to update transaction payment status and totals
CREATE OR REPLACE FUNCTION update_transaction_payment_status()
RETURNS TRIGGER AS $$
DECLARE
    v_total_paid DECIMAL(15,2);
    v_remaining DECIMAL(15,2);
    v_transaction_total DECIMAL(15,2);
    v_payment_count INTEGER;
    v_new_status payment_status;
BEGIN
    -- Get transaction total
    SELECT total INTO v_transaction_total
    FROM transactions
    WHERE id = COALESCE(NEW.transaction_id, OLD.transaction_id);
    
    -- Calculate total paid from all payments
    SELECT COALESCE(SUM(amount), 0), COUNT(*)
    INTO v_total_paid, v_payment_count
    FROM transaction_payments
    WHERE transaction_id = COALESCE(NEW.transaction_id, OLD.transaction_id);
    
    -- Calculate remaining amount
    v_remaining := v_transaction_total - v_total_paid;
    
    -- Determine payment status
    IF v_total_paid = 0 THEN
        v_new_status := 'pending';
    ELSIF v_total_paid >= v_transaction_total THEN
        v_new_status := 'paid';
        v_remaining := 0;
    ELSE
        v_new_status := 'partial';
    END IF;
    
    -- Update transaction
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
AFTER INSERT ON transaction_payments
FOR EACH ROW
EXECUTE FUNCTION update_transaction_payment_status();

CREATE TRIGGER trigger_update_transaction_payment_status_update
AFTER UPDATE ON transaction_payments
FOR EACH ROW
EXECUTE FUNCTION update_transaction_payment_status();

CREATE TRIGGER trigger_update_transaction_payment_status_delete
AFTER DELETE ON transaction_payments
FOR EACH ROW
EXECUTE FUNCTION update_transaction_payment_status();

-- Function to calculate cash deposit (only cash and QRIS payments)
CREATE OR REPLACE FUNCTION calculate_cash_deposit(p_outlet_id UUID, p_date DATE)
RETURNS DECIMAL(15,2) AS $$
DECLARE
    v_cash_total DECIMAL(15,2);
BEGIN
    -- Sum all cash and QRIS payments for completed transactions on the given date
    SELECT COALESCE(SUM(tp.amount), 0)
    INTO v_cash_total
    FROM transaction_payments tp
    INNER JOIN transactions t ON t.id = tp.transaction_id
    WHERE t.outlet_id = p_outlet_id
        AND DATE(t.transaction_date) = p_date
        AND t.status = 'completed'
        AND tp.payment_method IN ('cash', 'qris');
    
    RETURN v_cash_total;
END;
$$ LANGUAGE plpgsql;

-- Function to get payment breakdown by method
CREATE OR REPLACE FUNCTION get_payment_breakdown(p_outlet_id UUID, p_date DATE)
RETURNS TABLE (
    payment_method payment_method,
    total_amount DECIMAL(15,2),
    transaction_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tp.payment_method,
        SUM(tp.amount) as total_amount,
        COUNT(DISTINCT tp.transaction_id)::INTEGER as transaction_count
    FROM transaction_payments tp
    INNER JOIN transactions t ON t.id = tp.transaction_id
    WHERE t.outlet_id = p_outlet_id
        AND DATE(t.transaction_date) = p_date
        AND t.status = 'completed'
    GROUP BY tp.payment_method
    ORDER BY tp.payment_method;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- DATA MIGRATION
-- =====================================================

-- Migrate existing single payment_method to transaction_payments
INSERT INTO transaction_payments (transaction_id, payment_method, amount, payment_date, created_by)
SELECT 
    id,
    COALESCE(payment_method, 'cash'::payment_method),
    total,
    transaction_date,
    created_by
FROM transactions
WHERE status = 'completed'
    AND id NOT IN (SELECT transaction_id FROM transaction_payments);

-- Update payment status for all transactions
UPDATE transactions t
SET 
    payment_status = CASE
        WHEN t.status = 'completed' THEN 'paid'::payment_status
        WHEN t.status = 'cancelled' THEN 'pending'::payment_status
        WHEN t.status = 'refunded' THEN 'refunded'::payment_status
        ELSE 'pending'::payment_status
    END,
    total_paid = CASE
        WHEN t.status = 'completed' THEN t.total
        ELSE 0
    END,
    remaining_amount = CASE
        WHEN t.status = 'completed' THEN 0
        ELSE t.total
    END,
    is_multi_payment = false
WHERE payment_status IS NULL;

-- =====================================================
-- RLS POLICIES
-- =====================================================

ALTER TABLE transaction_payments ENABLE ROW LEVEL SECURITY;

-- Transaction payments policies
CREATE POLICY "Users can view payments for transactions in their outlets" ON transaction_payments FOR SELECT
USING (EXISTS (
    SELECT 1 FROM transactions t
    INNER JOIN user_outlets uo ON uo.outlet_id = t.outlet_id
    WHERE t.id = transaction_payments.transaction_id AND uo.user_id = auth.uid()
));

CREATE POLICY "Users can insert payments for transactions in their outlets" ON transaction_payments FOR INSERT
WITH CHECK (EXISTS (
    SELECT 1 FROM transactions t
    INNER JOIN user_outlets uo ON uo.outlet_id = t.outlet_id
    WHERE t.id = transaction_payments.transaction_id AND uo.user_id = auth.uid()
));

CREATE POLICY "Users can update payments for transactions in their outlets" ON transaction_payments FOR UPDATE
USING (EXISTS (
    SELECT 1 FROM transactions t
    INNER JOIN user_outlets uo ON uo.outlet_id = t.outlet_id
    WHERE t.id = transaction_payments.transaction_id AND uo.user_id = auth.uid()
));

CREATE POLICY "Users can delete payments for transactions in their outlets" ON transaction_payments FOR DELETE
USING (EXISTS (
    SELECT 1 FROM transactions t
    INNER JOIN user_outlets uo ON uo.outlet_id = t.outlet_id
    WHERE t.id = transaction_payments.transaction_id AND uo.user_id = auth.uid()
));

-- =====================================================
-- HELPER VIEWS
-- =====================================================

-- View for daily payment summary
CREATE OR REPLACE VIEW daily_payment_summary AS
SELECT 
    t.outlet_id,
    DATE(t.transaction_date) as transaction_date,
    tp.payment_method,
    COUNT(DISTINCT t.id) as transaction_count,
    SUM(tp.amount) as total_amount,
    AVG(tp.amount) as avg_amount,
    MIN(tp.amount) as min_amount,
    MAX(tp.amount) as max_amount
FROM transactions t
INNER JOIN transaction_payments tp ON tp.transaction_id = t.id
WHERE t.status = 'completed'
GROUP BY t.outlet_id, DATE(t.transaction_date), tp.payment_method;

-- View for multi-payment transactions
CREATE OR REPLACE VIEW multi_payment_transactions AS
SELECT 
    t.*,
    COUNT(tp.id) as payment_count,
    ARRAY_AGG(DISTINCT tp.payment_method ORDER BY tp.payment_method) as payment_methods,
    ARRAY_AGG(
        json_build_object(
            'method', tp.payment_method,
            'amount', tp.amount,
            'reference', tp.reference_number
        ) ORDER BY tp.payment_date
    ) as payment_details
FROM transactions t
INNER JOIN transaction_payments tp ON tp.transaction_id = t.id
WHERE t.is_multi_payment = true
GROUP BY t.id;

COMMENT ON TABLE transaction_payments IS 'Veroprise ERP - Multi-Payment System v1.0';
