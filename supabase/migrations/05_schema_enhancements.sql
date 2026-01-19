-- =====================================================
-- VEROPRISE ERP - SCHEMA ENHANCEMENTS
-- Harus dijalankan KELIMA setelah 04_hr_attendance_incentives.sql
-- =====================================================

-- =====================================================
-- OUTLETS TABLE - PRINTER SETTINGS
-- =====================================================

-- Add printer settings for receipt printing
ALTER TABLE outlets 
ADD COLUMN IF NOT EXISTS printer_paper_width INTEGER DEFAULT 58;

ALTER TABLE outlets 
ADD COLUMN IF NOT EXISTS receipt_header TEXT;

ALTER TABLE outlets 
ADD COLUMN IF NOT EXISTS receipt_footer TEXT DEFAULT 'Terima kasih atas kunjungan Anda!';

ALTER TABLE outlets 
ADD COLUMN IF NOT EXISTS show_logo_on_receipt BOOLEAN DEFAULT true;

COMMENT ON COLUMN outlets.printer_paper_width IS 'Thermal printer paper width in mm (58 or 80)';
COMMENT ON COLUMN outlets.receipt_header IS 'Custom header text for receipt';
COMMENT ON COLUMN outlets.receipt_footer IS 'Custom footer text for receipt';
COMMENT ON COLUMN outlets.show_logo_on_receipt IS 'Whether to show logo on printed receipt';

-- =====================================================
-- DAILY CLOSING REPORTS - EXPENSE SUMMARY FIELDS
-- =====================================================

-- Add total expenses field
ALTER TABLE daily_closing_reports 
ADD COLUMN IF NOT EXISTS total_expenses DECIMAL(15,2) DEFAULT 0;

-- Add deposit required (calculated field)
-- Note: Using a regular column instead of generated column for flexibility
ALTER TABLE daily_closing_reports 
ADD COLUMN IF NOT EXISTS deposit_required DECIMAL(15,2) DEFAULT 0;

COMMENT ON COLUMN daily_closing_reports.total_expenses IS 'Total expenses for the day from expenses table';
COMMENT ON COLUMN daily_closing_reports.deposit_required IS 'Cash to deposit = total_cash - total_expenses';

-- =====================================================
-- FUNCTION TO AUTO-CALCULATE DEPOSIT REQUIRED
-- =====================================================

-- Function to calculate deposit required when saving closing report
CREATE OR REPLACE FUNCTION calculate_deposit_required()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate: Cash Sales - Expenses = Deposit Required
    NEW.deposit_required := COALESCE(NEW.total_cash, 0) - COALESCE(NEW.total_expenses, 0);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-calculate before insert or update
DROP TRIGGER IF EXISTS trigger_calculate_deposit_required ON daily_closing_reports;
CREATE TRIGGER trigger_calculate_deposit_required
BEFORE INSERT OR UPDATE ON daily_closing_reports
FOR EACH ROW
EXECUTE FUNCTION calculate_deposit_required();

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_daily_closing_expenses ON daily_closing_reports(total_expenses);
CREATE INDEX IF NOT EXISTS idx_daily_closing_deposit ON daily_closing_reports(deposit_required);

-- =====================================================
-- UPDATE EXISTING RECORDS (if any)
-- =====================================================

-- Set default footer for existing outlets without footer
UPDATE outlets 
SET receipt_footer = 'Terima kasih atas kunjungan Anda!'
WHERE receipt_footer IS NULL;

-- Recalculate deposit_required for existing reports
UPDATE daily_closing_reports
SET deposit_required = COALESCE(total_cash, 0) - COALESCE(total_expenses, 0)
WHERE deposit_required IS NULL OR deposit_required = 0;

COMMENT ON TABLE outlets IS 'Veroprise ERP - Outlets with Printer Settings v1.1';
COMMENT ON TABLE daily_closing_reports IS 'Veroprise ERP - Daily Closing Reports with Expense Summary v1.1';
