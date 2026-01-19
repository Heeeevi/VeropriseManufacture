-- =====================================================
-- VEROPRISE ERP - HR ATTENDANCE & INCENTIVES SYSTEM
-- Harus dijalankan KEEMPAT setelah 03_multi_payment_system.sql
-- =====================================================

-- =====================================================
-- ENUMS
-- =====================================================

CREATE TYPE attendance_status AS ENUM ('present', 'late', 'absent', 'leave', 'sick', 'holiday', 'off');
CREATE TYPE target_type AS ENUM ('product_quantity', 'product_value', 'total_sales', 'category_sales');
CREATE TYPE target_period AS ENUM ('daily', 'weekly', 'monthly', 'quarterly');
CREATE TYPE incentive_type AS ENUM ('fixed', 'percentage', 'tiered');

-- =====================================================
-- ATTENDANCE TABLES
-- =====================================================

-- Attendance table
CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    attendance_date DATE NOT NULL,
    shift_id UUID REFERENCES shifts(id) ON DELETE SET NULL,
    
    -- Clock times
    clock_in TIMESTAMPTZ,
    clock_out TIMESTAMPTZ,
    
    -- Status
    status attendance_status NOT NULL DEFAULT 'present',
    
    -- Calculated fields
    hours_worked DECIMAL(5,2) DEFAULT 0,
    overtime_hours DECIMAL(5,2) DEFAULT 0,
    late_duration_minutes INTEGER DEFAULT 0,
    
    -- Break time
    break_start TIMESTAMPTZ,
    break_end TIMESTAMPTZ,
    break_duration_minutes INTEGER DEFAULT 0,
    
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(employee_id, attendance_date)
);

-- =====================================================
-- SALES TARGET & INCENTIVE TABLES
-- =====================================================

-- Sales targets table
CREATE TABLE sales_targets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    
    -- Target configuration
    target_name TEXT NOT NULL,
    target_type target_type NOT NULL,
    target_period target_period NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    
    -- Target values
    target_quantity DECIMAL(15,2),
    target_value DECIMAL(15,2),
    
    -- Incentive configuration
    incentive_type incentive_type NOT NULL,
    fixed_amount DECIMAL(15,2) DEFAULT 0,
    percentage_rate DECIMAL(5,2) DEFAULT 0,
    
    -- Tiered incentives (JSON format)
    tiers JSONB,
    -- Example: [{"min": 100, "max": 200, "amount": 50000}, {"min": 200, "max": null, "amount": 100000}]
    
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CHECK (
        (employee_id IS NOT NULL OR employee_id IS NULL) AND
        (target_type = 'product_quantity' AND product_id IS NOT NULL) OR
        (target_type = 'product_value' AND product_id IS NOT NULL) OR
        (target_type = 'total_sales' AND product_id IS NULL) OR
        (target_type = 'category_sales' AND category_id IS NOT NULL)
    )
);

-- Employee incentives table (calculated results)
CREATE TABLE employee_incentives (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sales_target_id UUID NOT NULL REFERENCES sales_targets(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    
    -- Period
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Achievement
    achieved_quantity DECIMAL(15,2) DEFAULT 0,
    achieved_value DECIMAL(15,2) DEFAULT 0,
    target_quantity DECIMAL(15,2),
    target_value DECIMAL(15,2),
    achievement_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Incentive calculation
    incentive_amount DECIMAL(15,2) DEFAULT 0,
    is_paid BOOLEAN DEFAULT false,
    paid_date DATE,
    
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(sales_target_id, employee_id, period_start, period_end)
);

-- =====================================================
-- ENHANCE EXISTING TABLES
-- =====================================================

-- Add payroll fields to employees table
ALTER TABLE employees
ADD COLUMN IF NOT EXISTS overtime_rate DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS allowance_transport DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS allowance_meal DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS allowance_other DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS tax_id TEXT,
ADD COLUMN IF NOT EXISTS bank_account TEXT,
ADD COLUMN IF NOT EXISTS bank_name TEXT;

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX idx_attendance_employee_date ON attendance(employee_id, attendance_date);
CREATE INDEX idx_attendance_outlet_date ON attendance(outlet_id, attendance_date);
CREATE INDEX idx_attendance_shift ON attendance(shift_id);
CREATE INDEX idx_attendance_status ON attendance(status);
CREATE INDEX idx_sales_targets_outlet ON sales_targets(outlet_id);
CREATE INDEX idx_sales_targets_employee ON sales_targets(employee_id);
CREATE INDEX idx_sales_targets_product ON sales_targets(product_id);
CREATE INDEX idx_sales_targets_period ON sales_targets(start_date, end_date);
CREATE INDEX idx_employee_incentives_employee ON employee_incentives(employee_id);
CREATE INDEX idx_employee_incentives_target ON employee_incentives(sales_target_id);
CREATE INDEX idx_employee_incentives_period ON employee_incentives(period_start, period_end);

-- =====================================================
-- TRIGGERS
-- =====================================================

CREATE TRIGGER update_attendance_updated_at BEFORE UPDATE ON attendance
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sales_targets_updated_at BEFORE UPDATE ON sales_targets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_employee_incentives_updated_at BEFORE UPDATE ON employee_incentives
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function to automatically create attendance from shift
CREATE OR REPLACE FUNCTION auto_create_attendance_from_shift()
RETURNS TRIGGER AS $$
BEGIN
    -- Create attendance record when shift is created
    INSERT INTO attendance (employee_id, outlet_id, attendance_date, shift_id, status)
    VALUES (NEW.employee_id, NEW.outlet_id, NEW.shift_date, NEW.id, 'present')
    ON CONFLICT (employee_id, attendance_date) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_create_attendance
AFTER INSERT ON shifts
FOR EACH ROW
EXECUTE FUNCTION auto_create_attendance_from_shift();

-- Function to calculate work hours
CREATE OR REPLACE FUNCTION calculate_work_hours()
RETURNS TRIGGER AS $$
DECLARE
    v_scheduled_start TIME;
    v_scheduled_end TIME;
    v_work_minutes INTEGER;
    v_scheduled_minutes INTEGER;
    v_late_minutes INTEGER;
BEGIN
    -- Only calculate if both clock_in and clock_out are set
    IF NEW.clock_in IS NOT NULL AND NEW.clock_out IS NOT NULL THEN
        -- Calculate total work minutes
        v_work_minutes := EXTRACT(EPOCH FROM (NEW.clock_out - NEW.clock_in))::INTEGER / 60;
        
        -- Subtract break duration
        v_work_minutes := v_work_minutes - NEW.break_duration_minutes;
        
        -- Convert to hours
        NEW.hours_worked := v_work_minutes::DECIMAL / 60;
        
        -- Get scheduled times from shift
        IF NEW.shift_id IS NOT NULL THEN
            SELECT start_time, end_time INTO v_scheduled_start, v_scheduled_end
            FROM shifts WHERE id = NEW.shift_id;
            
            -- Calculate scheduled work minutes
            v_scheduled_minutes := EXTRACT(EPOCH FROM (v_scheduled_end::TIME - v_scheduled_start::TIME))::INTEGER / 60;
            
            -- Calculate overtime (work beyond scheduled hours)
            IF v_work_minutes > v_scheduled_minutes THEN
                NEW.overtime_hours := (v_work_minutes - v_scheduled_minutes)::DECIMAL / 60;
            END IF;
            
            -- Calculate late duration
            IF NEW.clock_in::TIME > v_scheduled_start THEN
                v_late_minutes := EXTRACT(EPOCH FROM (NEW.clock_in::TIME - v_scheduled_start))::INTEGER / 60;
                NEW.late_duration_minutes := v_late_minutes;
                
                -- Update status to 'late' if more than 15 minutes
                IF v_late_minutes > 15 THEN
                    NEW.status := 'late';
                END IF;
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_work_hours
BEFORE INSERT OR UPDATE ON attendance
FOR EACH ROW
EXECUTE FUNCTION calculate_work_hours();

-- Function to calculate employee incentives
CREATE OR REPLACE FUNCTION calculate_employee_incentives(
    p_sales_target_id UUID,
    p_employee_id UUID,
    p_period_start DATE,
    p_period_end DATE
)
RETURNS DECIMAL(15,2) AS $$
DECLARE
    v_target RECORD;
    v_achieved_qty DECIMAL(15,2);
    v_achieved_val DECIMAL(15,2);
    v_achievement_pct DECIMAL(5,2);
    v_incentive DECIMAL(15,2);
    v_tier JSONB;
BEGIN
    -- Get target configuration
    SELECT * INTO v_target FROM sales_targets WHERE id = p_sales_target_id;
    
    -- Calculate achievement based on target type
    IF v_target.target_type = 'product_quantity' THEN
        -- Sum quantity sold for specific product
        SELECT COALESCE(SUM(ti.quantity), 0)
        INTO v_achieved_qty
        FROM transaction_items ti
        INNER JOIN transactions t ON t.id = ti.transaction_id
        WHERE t.employee_id = p_employee_id
            AND t.outlet_id = v_target.outlet_id
            AND ti.product_id = v_target.product_id
            AND DATE(t.transaction_date) BETWEEN p_period_start AND p_period_end
            AND t.status = 'completed';
            
        v_achievement_pct := (v_achieved_qty / NULLIF(v_target.target_quantity, 0)) * 100;
        
    ELSIF v_target.target_type = 'product_value' THEN
        -- Sum value sold for specific product
        SELECT COALESCE(SUM(ti.subtotal), 0)
        INTO v_achieved_val
        FROM transaction_items ti
        INNER JOIN transactions t ON t.id = ti.transaction_id
        WHERE t.employee_id = p_employee_id
            AND t.outlet_id = v_target.outlet_id
            AND ti.product_id = v_target.product_id
            AND DATE(t.transaction_date) BETWEEN p_period_start AND p_period_end
            AND t.status = 'completed';
            
        v_achievement_pct := (v_achieved_val / NULLIF(v_target.target_value, 0)) * 100;
        
    ELSIF v_target.target_type = 'total_sales' THEN
        -- Sum total sales value
        SELECT COALESCE(SUM(t.total), 0)
        INTO v_achieved_val
        FROM transactions t
        WHERE t.employee_id = p_employee_id
            AND t.outlet_id = v_target.outlet_id
            AND DATE(t.transaction_date) BETWEEN p_period_start AND p_period_end
            AND t.status = 'completed';
            
        v_achievement_pct := (v_achieved_val / NULLIF(v_target.target_value, 0)) * 100;
        
    ELSIF v_target.target_type = 'category_sales' THEN
        -- Sum sales value for specific category
        SELECT COALESCE(SUM(ti.subtotal), 0)
        INTO v_achieved_val
        FROM transaction_items ti
        INNER JOIN transactions t ON t.id = ti.transaction_id
        INNER JOIN products p ON p.id = ti.product_id
        WHERE t.employee_id = p_employee_id
            AND t.outlet_id = v_target.outlet_id
            AND p.category_id = v_target.category_id
            AND DATE(t.transaction_date) BETWEEN p_period_start AND p_period_end
            AND t.status = 'completed';
            
        v_achievement_pct := (v_achieved_val / NULLIF(v_target.target_value, 0)) * 100;
    END IF;
    
    -- Calculate incentive based on type
    IF v_target.incentive_type = 'fixed' THEN
        -- Fixed amount if target achieved
        IF v_achievement_pct >= 100 THEN
            v_incentive := v_target.fixed_amount;
        ELSE
            v_incentive := 0;
        END IF;
        
    ELSIF v_target.incentive_type = 'percentage' THEN
        -- Percentage of achieved value
        v_incentive := COALESCE(v_achieved_val, 0) * (v_target.percentage_rate / 100);
        
    ELSIF v_target.incentive_type = 'tiered' THEN
        -- Tiered based on achievement
        v_incentive := 0;
        
        FOR v_tier IN SELECT * FROM jsonb_array_elements(v_target.tiers)
        LOOP
            IF COALESCE(v_achieved_qty, v_achieved_val, 0) >= (v_tier->>'min')::DECIMAL AND
               (v_tier->>'max' IS NULL OR COALESCE(v_achieved_qty, v_achieved_val, 0) <= (v_tier->>'max')::DECIMAL) THEN
                v_incentive := (v_tier->>'amount')::DECIMAL;
                EXIT;
            END IF;
        END LOOP;
    END IF;
    
    -- Insert or update incentive record
    INSERT INTO employee_incentives (
        sales_target_id, employee_id, outlet_id,
        period_start, period_end,
        achieved_quantity, achieved_value,
        target_quantity, target_value,
        achievement_percentage, incentive_amount
    ) VALUES (
        p_sales_target_id, p_employee_id, v_target.outlet_id,
        p_period_start, p_period_end,
        v_achieved_qty, v_achieved_val,
        v_target.target_quantity, v_target.target_value,
        v_achievement_pct, v_incentive
    )
    ON CONFLICT (sales_target_id, employee_id, period_start, period_end)
    DO UPDATE SET
        achieved_quantity = EXCLUDED.achieved_quantity,
        achieved_value = EXCLUDED.achieved_value,
        achievement_percentage = EXCLUDED.achievement_percentage,
        incentive_amount = EXCLUDED.incentive_amount,
        updated_at = NOW();
    
    RETURN v_incentive;
END;
$$ LANGUAGE plpgsql;

-- Function to auto-calculate incentives after transaction completion
CREATE OR REPLACE FUNCTION auto_calculate_incentives_after_sale()
RETURNS TRIGGER AS $$
DECLARE
    v_target RECORD;
    v_period_start DATE;
    v_period_end DATE;
BEGIN
    -- Only process completed transactions
    IF NEW.status = 'completed' AND NEW.employee_id IS NOT NULL THEN
        -- Find all active sales targets for this employee/outlet
        FOR v_target IN 
            SELECT * FROM sales_targets
            WHERE outlet_id = NEW.outlet_id
                AND (employee_id = NEW.employee_id OR employee_id IS NULL)
                AND is_active = true
                AND NEW.transaction_date::DATE BETWEEN start_date AND end_date
        LOOP
            -- Calculate period based on target period
            CASE v_target.target_period
                WHEN 'daily' THEN
                    v_period_start := NEW.transaction_date::DATE;
                    v_period_end := NEW.transaction_date::DATE;
                WHEN 'weekly' THEN
                    v_period_start := DATE_TRUNC('week', NEW.transaction_date)::DATE;
                    v_period_end := (DATE_TRUNC('week', NEW.transaction_date) + INTERVAL '6 days')::DATE;
                WHEN 'monthly' THEN
                    v_period_start := DATE_TRUNC('month', NEW.transaction_date)::DATE;
                    v_period_end := (DATE_TRUNC('month', NEW.transaction_date) + INTERVAL '1 month' - INTERVAL '1 day')::DATE;
                WHEN 'quarterly' THEN
                    v_period_start := DATE_TRUNC('quarter', NEW.transaction_date)::DATE;
                    v_period_end := (DATE_TRUNC('quarter', NEW.transaction_date) + INTERVAL '3 months' - INTERVAL '1 day')::DATE;
            END CASE;
            
            -- Calculate incentive
            PERFORM calculate_employee_incentives(
                v_target.id,
                NEW.employee_id,
                v_period_start,
                v_period_end
            );
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_calculate_incentives
AFTER INSERT OR UPDATE ON transactions
FOR EACH ROW
EXECUTE FUNCTION auto_calculate_incentives_after_sale();

-- =====================================================
-- RLS POLICIES
-- =====================================================

ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_targets ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_incentives ENABLE ROW LEVEL SECURITY;

-- Attendance policies
CREATE POLICY "Users can view attendance for their outlets" ON attendance FOR SELECT
USING (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = attendance.outlet_id
));

CREATE POLICY "Users can insert attendance for their outlets" ON attendance FOR INSERT
WITH CHECK (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = attendance.outlet_id
));

CREATE POLICY "Users can update attendance for their outlets" ON attendance FOR UPDATE
USING (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = attendance.outlet_id
));

-- Sales targets policies
CREATE POLICY "Users can view sales targets for their outlets" ON sales_targets FOR SELECT
USING (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = sales_targets.outlet_id
));

CREATE POLICY "Managers can manage sales targets" ON sales_targets FOR ALL
USING (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() 
        AND outlet_id = sales_targets.outlet_id 
        AND role IN ('owner', 'manager')
));

-- Employee incentives policies
CREATE POLICY "Users can view incentives for their outlets" ON employee_incentives FOR SELECT
USING (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = employee_incentives.outlet_id
));

CREATE POLICY "Employees can view own incentives" ON employee_incentives FOR SELECT
USING (EXISTS (
    SELECT 1 FROM employees 
    WHERE id = employee_incentives.employee_id AND user_id = auth.uid()
));

-- =====================================================
-- HELPER VIEWS
-- =====================================================

-- View for attendance summary
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
    SUM(a.overtime_hours) as total_overtime,
    AVG(a.late_duration_minutes) as avg_late_minutes
FROM attendance a
INNER JOIN employees e ON e.id = a.employee_id
GROUP BY e.id, e.full_name, a.outlet_id, DATE_TRUNC('month', a.attendance_date);

-- View for employee performance
CREATE OR REPLACE VIEW employee_performance AS
SELECT 
    e.id as employee_id,
    e.full_name as employee_name,
    e.outlet_id,
    DATE_TRUNC('month', ei.period_start) as month,
    COUNT(DISTINCT ei.sales_target_id) as active_targets,
    AVG(ei.achievement_percentage) as avg_achievement,
    SUM(ei.incentive_amount) as total_incentives,
    SUM(ei.achieved_value) as total_sales_value
FROM employee_incentives ei
INNER JOIN employees e ON e.id = ei.employee_id
GROUP BY e.id, e.full_name, e.outlet_id, DATE_TRUNC('month', ei.period_start);

COMMENT ON TABLE attendance IS 'Veroprise ERP - HR Attendance & Incentives v1.0';
