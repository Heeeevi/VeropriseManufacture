-- =====================================================
-- VEROPRISE ERP - WAREHOUSE MANAGEMENT SYSTEM
-- Harus dijalankan KEDUA setelah 01_base_schema.sql
-- =====================================================

-- =====================================================
-- ENUMS
-- =====================================================

CREATE TYPE warehouse_type AS ENUM ('central', 'regional');
CREATE TYPE po_status AS ENUM ('draft', 'submitted', 'approved', 'received', 'cancelled');
CREATE TYPE stock_transfer_status AS ENUM ('draft', 'submitted', 'approved', 'in_transit', 'received', 'cancelled');
CREATE TYPE stock_opname_status AS ENUM ('draft', 'in_progress', 'completed', 'approved');

-- =====================================================
-- WAREHOUSE TABLES
-- =====================================================

-- Warehouses table
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

-- Warehouse inventory table
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

-- Stock transfer orders table (Warehouse → Outlet)
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

-- Stock opname table (Physical count)
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

-- Daily closing reports table
CREATE TABLE daily_closing_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_number TEXT NOT NULL UNIQUE,
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    closing_date DATE NOT NULL,
    
    -- Sales summary
    total_sales DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_transactions INTEGER NOT NULL DEFAULT 0,
    
    -- Cash summary
    cash_in_register DECIMAL(15,2) NOT NULL DEFAULT 0,
    expected_cash DECIMAL(15,2) NOT NULL DEFAULT 0,
    cash_difference DECIMAL(15,2) GENERATED ALWAYS AS (cash_in_register - expected_cash) STORED,
    
    -- Multi-payment breakdown
    total_cash DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_qris DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_transfer DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_olshop DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_debit_card DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_credit_card DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_other DECIMAL(15,2) NOT NULL DEFAULT 0,
    
    -- Bank deposit
    bank_deposit_amount DECIMAL(15,2) DEFAULT 0,
    bank_deposit_proof TEXT,
    
    closed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(outlet_id, closing_date)
);

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX idx_warehouse_inventory_warehouse ON warehouse_inventory(warehouse_id);
CREATE INDEX idx_warehouse_inventory_product ON warehouse_inventory(product_id);
CREATE INDEX idx_suppliers_code ON suppliers(code);
CREATE INDEX idx_purchase_orders_warehouse ON purchase_orders(warehouse_id);
CREATE INDEX idx_purchase_orders_supplier ON purchase_orders(supplier_id);
CREATE INDEX idx_purchase_orders_status ON purchase_orders(status);
CREATE INDEX idx_purchase_order_items_po ON purchase_order_items(purchase_order_id);
CREATE INDEX idx_purchase_order_items_product ON purchase_order_items(product_id);
CREATE INDEX idx_stock_transfer_orders_warehouse ON stock_transfer_orders(from_warehouse_id);
CREATE INDEX idx_stock_transfer_orders_outlet ON stock_transfer_orders(to_outlet_id);
CREATE INDEX idx_stock_transfer_orders_status ON stock_transfer_orders(status);
CREATE INDEX idx_stock_transfer_items_sto ON stock_transfer_items(stock_transfer_order_id);
CREATE INDEX idx_stock_transfer_items_product ON stock_transfer_items(product_id);
CREATE INDEX idx_stock_opname_warehouse ON stock_opname(warehouse_id);
CREATE INDEX idx_stock_opname_outlet ON stock_opname(outlet_id);
CREATE INDEX idx_stock_opname_items_opname ON stock_opname_items(stock_opname_id);
CREATE INDEX idx_stock_opname_items_product ON stock_opname_items(product_id);
CREATE INDEX idx_daily_closing_outlet_date ON daily_closing_reports(outlet_id, closing_date);

-- =====================================================
-- TRIGGERS
-- =====================================================

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

CREATE TRIGGER update_daily_closing_reports_updated_at BEFORE UPDATE ON daily_closing_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function to update warehouse inventory after PO received
CREATE OR REPLACE FUNCTION update_warehouse_inventory_from_po()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process when status changes to 'received'
    IF NEW.status = 'received' AND OLD.status != 'received' THEN
        -- Update warehouse inventory for each PO item
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
            
        -- Record inventory transaction
        INSERT INTO inventory_transactions (
            outlet_id, product_id, transaction_type, quantity, unit_cost, total_cost,
            reference_id, reference_type, performed_by
        )
        SELECT 
            (SELECT id FROM outlets LIMIT 1), -- Temporary outlet reference
            poi.product_id,
            'in'::inventory_transaction_type,
            poi.received_quantity,
            poi.unit_price,
            poi.subtotal,
            NEW.id,
            'purchase_order',
            NEW.received_by
        FROM purchase_order_items poi
        WHERE poi.purchase_order_id = NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_warehouse_inventory_from_po
AFTER UPDATE ON purchase_orders
FOR EACH ROW
EXECUTE FUNCTION update_warehouse_inventory_from_po();

-- Function to update inventories after stock transfer received
CREATE OR REPLACE FUNCTION update_inventory_from_stock_transfer()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process when status changes to 'received'
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
            
        -- Record inventory transactions (warehouse out)
        INSERT INTO inventory_transactions (
            outlet_id, product_id, transaction_type, quantity, unit_cost,
            reference_id, reference_type, performed_by
        )
        SELECT 
            NEW.to_outlet_id,
            sti.product_id,
            'transfer'::inventory_transaction_type,
            -sti.quantity_received,
            sti.unit_cost,
            NEW.id,
            'stock_transfer',
            NEW.received_by
        FROM stock_transfer_items sti
        WHERE sti.stock_transfer_order_id = NEW.id;
        
        -- Record inventory transactions (outlet in)
        INSERT INTO inventory_transactions (
            outlet_id, product_id, transaction_type, quantity, unit_cost,
            reference_id, reference_type, performed_by
        )
        SELECT 
            NEW.to_outlet_id,
            sti.product_id,
            'in'::inventory_transaction_type,
            sti.quantity_received,
            sti.unit_cost,
            NEW.id,
            'stock_transfer',
            NEW.received_by
        FROM stock_transfer_items sti
        WHERE sti.stock_transfer_order_id = NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_inventory_from_stock_transfer
AFTER UPDATE ON stock_transfer_orders
FOR EACH ROW
EXECUTE FUNCTION update_inventory_from_stock_transfer();

-- Function to apply stock opname adjustments
CREATE OR REPLACE FUNCTION apply_stock_opname_adjustments()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process when status changes to 'approved'
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
                
            -- Record adjustment transactions
            INSERT INTO inventory_transactions (
                outlet_id, product_id, transaction_type, quantity, unit_cost, total_cost,
                reference_id, reference_type, performed_by, notes
            )
            SELECT 
                (SELECT id FROM outlets LIMIT 1),
                soi.product_id,
                'adjustment'::inventory_transaction_type,
                soi.difference,
                soi.unit_cost,
                soi.total_loss,
                NEW.id,
                'stock_opname',
                NEW.approved_by,
                'Stock opname adjustment'
            FROM stock_opname_items soi
            WHERE soi.stock_opname_id = NEW.id AND soi.difference != 0;
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
                
            -- Record adjustment transactions
            INSERT INTO inventory_transactions (
                outlet_id, product_id, transaction_type, quantity, unit_cost, total_cost,
                reference_id, reference_type, performed_by, notes
            )
            SELECT 
                NEW.outlet_id,
                soi.product_id,
                'adjustment'::inventory_transaction_type,
                soi.difference,
                soi.unit_cost,
                soi.total_loss,
                NEW.id,
                'stock_opname',
                NEW.approved_by,
                'Stock opname adjustment'
            FROM stock_opname_items soi
            WHERE soi.stock_opname_id = NEW.id AND soi.difference != 0;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_apply_stock_opname_adjustments
AFTER UPDATE ON stock_opname
FOR EACH ROW
EXECUTE FUNCTION apply_stock_opname_adjustments();

-- =====================================================
-- RLS POLICIES
-- =====================================================

ALTER TABLE warehouses ENABLE ROW LEVEL SECURITY;
ALTER TABLE warehouse_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_transfer_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_transfer_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_opname ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_opname_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_closing_reports ENABLE ROW LEVEL SECURITY;

-- Warehouses policies (Owner/Manager only)
CREATE POLICY "Owner and managers can view warehouses" ON warehouses FOR SELECT
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

-- Warehouse inventory policies
CREATE POLICY "Authorized users can view warehouse inventory" ON warehouse_inventory FOR SELECT
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

-- Suppliers policies
CREATE POLICY "Authorized users can view suppliers" ON suppliers FOR SELECT
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

-- Purchase orders policies
CREATE POLICY "Authorized users can view purchase orders" ON purchase_orders FOR SELECT
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

-- Purchase order items policies
CREATE POLICY "Authorized users can view PO items" ON purchase_order_items FOR SELECT
USING (EXISTS (
    SELECT 1 FROM purchase_orders po
    INNER JOIN profiles p ON p.id = auth.uid()
    WHERE po.id = purchase_order_items.purchase_order_id AND p.role IN ('owner', 'manager')
));

-- Stock transfer orders policies
CREATE POLICY "Users can view stock transfers for their outlets" ON stock_transfer_orders FOR SELECT
USING (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = stock_transfer_orders.to_outlet_id
));

-- Stock transfer items policies
CREATE POLICY "Users can view stock transfer items" ON stock_transfer_items FOR SELECT
USING (EXISTS (
    SELECT 1 FROM stock_transfer_orders sto
    INNER JOIN user_outlets uo ON uo.outlet_id = sto.to_outlet_id
    WHERE sto.id = stock_transfer_items.stock_transfer_order_id AND uo.user_id = auth.uid()
));

-- Stock opname policies
CREATE POLICY "Users can view stock opname for their outlets" ON stock_opname FOR SELECT
USING (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() 
    AND (outlet_id = stock_opname.outlet_id OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
));

-- Stock opname items policies
CREATE POLICY "Users can view stock opname items" ON stock_opname_items FOR SELECT
USING (EXISTS (
    SELECT 1 FROM stock_opname so
    LEFT JOIN user_outlets uo ON uo.outlet_id = so.outlet_id
    WHERE so.id = stock_opname_items.stock_opname_id 
    AND (uo.user_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
));

-- Daily closing reports policies
CREATE POLICY "Users can view closing reports for their outlets" ON daily_closing_reports FOR SELECT
USING (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = daily_closing_reports.outlet_id
));

COMMENT ON TABLE warehouses IS 'Veroprise ERP - Warehouse System v1.0';
