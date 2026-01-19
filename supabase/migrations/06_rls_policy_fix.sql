-- =====================================================
-- VEROPRISE ERP - RLS POLICY FIX
-- Harus dijalankan KEENAM setelah 05_schema_enhancements.sql
-- Menambahkan INSERT/UPDATE/DELETE policies yang kurang
-- =====================================================

-- =====================================================
-- OUTLETS - Owner dapat mengelola outlets
-- =====================================================

-- Drop existing policies if any conflicts
DROP POLICY IF EXISTS "Owners can manage outlets" ON outlets;
DROP POLICY IF EXISTS "Managers can manage outlets" ON outlets;

-- Owner can do everything with outlets
CREATE POLICY "Owners can manage outlets" ON outlets FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'owner'))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'owner'));

-- Managers can insert and update outlets (but not delete)
CREATE POLICY "Managers can insert outlets" ON outlets FOR INSERT
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

CREATE POLICY "Managers can update outlets" ON outlets FOR UPDATE
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

-- =====================================================
-- USER_OUTLETS - Owner dapat assign users ke outlets
-- =====================================================

DROP POLICY IF EXISTS "Owners can manage user_outlets" ON user_outlets;

CREATE POLICY "Owners can manage user_outlets" ON user_outlets FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'owner'))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'owner'));

-- =====================================================
-- PRODUCTS - Staff dapat mengelola products di outlet mereka
-- =====================================================

DROP POLICY IF EXISTS "Users can insert products in their outlets" ON products;
DROP POLICY IF EXISTS "Users can update products in their outlets" ON products;
DROP POLICY IF EXISTS "Users can delete products in their outlets" ON products;
DROP POLICY IF EXISTS "Owners can manage all products" ON products;

-- Owner and Manager can manage all products
CREATE POLICY "Owners can manage all products" ON products FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

-- Staff can manage products in their outlets
CREATE POLICY "Staff can insert products in their outlets" ON products FOR INSERT
WITH CHECK (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = products.outlet_id
));

CREATE POLICY "Staff can update products in their outlets" ON products FOR UPDATE
USING (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = products.outlet_id
));

-- =====================================================
-- CATEGORIES - Owner/Manager dapat mengelola categories
-- =====================================================

DROP POLICY IF EXISTS "Owners can manage categories" ON categories;

CREATE POLICY "Owners can manage categories" ON categories FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

-- =====================================================
-- EMPLOYEES - Owner/Manager dapat mengelola employees
-- =====================================================

DROP POLICY IF EXISTS "Owners can manage employees" ON employees;
DROP POLICY IF EXISTS "Users can insert employees in their outlets" ON employees;
DROP POLICY IF EXISTS "Users can update employees in their outlets" ON employees;

CREATE POLICY "Owners can manage employees" ON employees FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

-- =====================================================
-- SHIFTS - Staff dapat mengelola shifts di outlet mereka
-- =====================================================

DROP POLICY IF EXISTS "Users can insert shifts in their outlets" ON shifts;
DROP POLICY IF EXISTS "Users can update shifts in their outlets" ON shifts;
DROP POLICY IF EXISTS "Owners can manage shifts" ON shifts;

CREATE POLICY "Owners can manage shifts" ON shifts FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

CREATE POLICY "Staff can manage shifts in their outlets" ON shifts FOR INSERT
WITH CHECK (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = shifts.outlet_id
));

-- =====================================================
-- INVENTORY - Staff dapat mengelola inventory di outlet mereka
-- =====================================================

DROP POLICY IF EXISTS "Users can insert inventory in their outlets" ON inventory;
DROP POLICY IF EXISTS "Users can update inventory in their outlets" ON inventory;
DROP POLICY IF EXISTS "Owners can manage inventory" ON inventory;

CREATE POLICY "Owners can manage inventory" ON inventory FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

CREATE POLICY "Staff can manage inventory in their outlets" ON inventory FOR ALL
USING (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = inventory.outlet_id
))
WITH CHECK (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = inventory.outlet_id
));

-- =====================================================
-- INVENTORY_TRANSACTIONS - Staff dapat insert di outlet mereka
-- =====================================================

DROP POLICY IF EXISTS "Users can insert inventory transactions" ON inventory_transactions;
DROP POLICY IF EXISTS "Owners can manage inventory transactions" ON inventory_transactions;

CREATE POLICY "Owners can manage inventory transactions" ON inventory_transactions FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

CREATE POLICY "Staff can insert inventory transactions" ON inventory_transactions FOR INSERT
WITH CHECK (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = inventory_transactions.outlet_id
));

-- =====================================================
-- TRANSACTIONS - Staff dapat membuat transaksi di outlet mereka
-- =====================================================

DROP POLICY IF EXISTS "Users can insert transactions in their outlets" ON transactions;
DROP POLICY IF EXISTS "Users can update transactions in their outlets" ON transactions;
DROP POLICY IF EXISTS "Owners can manage transactions" ON transactions;

CREATE POLICY "Owners can manage transactions" ON transactions FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

CREATE POLICY "Staff can manage transactions in their outlets" ON transactions FOR ALL
USING (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = transactions.outlet_id
))
WITH CHECK (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = transactions.outlet_id
));

-- =====================================================
-- TRANSACTION_ITEMS - Mengikuti transaksi
-- =====================================================

DROP POLICY IF EXISTS "Users can insert transaction items" ON transaction_items;
DROP POLICY IF EXISTS "Owners can manage transaction items" ON transaction_items;

CREATE POLICY "Owners can manage transaction items" ON transaction_items FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

CREATE POLICY "Staff can insert transaction items" ON transaction_items FOR INSERT
WITH CHECK (EXISTS (
    SELECT 1 FROM transactions t
    INNER JOIN user_outlets uo ON uo.outlet_id = t.outlet_id
    WHERE t.id = transaction_items.transaction_id AND uo.user_id = auth.uid()
));

-- =====================================================
-- EXPENSES - Staff dapat mengelola expenses di outlet mereka
-- =====================================================

DROP POLICY IF EXISTS "Users can insert expenses in their outlets" ON expenses;
DROP POLICY IF EXISTS "Users can update expenses in their outlets" ON expenses;
DROP POLICY IF EXISTS "Owners can manage expenses" ON expenses;

CREATE POLICY "Owners can manage expenses" ON expenses FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

CREATE POLICY "Staff can manage expenses in their outlets" ON expenses FOR ALL
USING (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = expenses.outlet_id
))
WITH CHECK (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = expenses.outlet_id
));

-- =====================================================
-- BOOKINGS - Staff dapat mengelola bookings di outlet mereka
-- =====================================================

DROP POLICY IF EXISTS "Users can update bookings in their outlets" ON bookings;
DROP POLICY IF EXISTS "Owners can manage bookings" ON bookings;

CREATE POLICY "Owners can manage bookings" ON bookings FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

CREATE POLICY "Staff can update bookings in their outlets" ON bookings FOR UPDATE
USING (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = bookings.outlet_id
));

-- =====================================================
-- WAREHOUSES - Owner/Manager dapat mengelola warehouses
-- =====================================================

DROP POLICY IF EXISTS "Owners can manage warehouses" ON warehouses;

CREATE POLICY "Owners can manage warehouses" ON warehouses FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

-- =====================================================
-- WAREHOUSE_INVENTORY - Owner/Manager dapat mengelola
-- =====================================================

DROP POLICY IF EXISTS "Owners can manage warehouse inventory" ON warehouse_inventory;

CREATE POLICY "Owners can manage warehouse inventory" ON warehouse_inventory FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

-- =====================================================
-- SUPPLIERS - Owner/Manager dapat mengelola suppliers
-- =====================================================

DROP POLICY IF EXISTS "Owners can manage suppliers" ON suppliers;

CREATE POLICY "Owners can manage suppliers" ON suppliers FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

-- =====================================================
-- PURCHASE_ORDERS - Owner/Manager dapat mengelola PO
-- =====================================================

DROP POLICY IF EXISTS "Owners can manage purchase orders" ON purchase_orders;

CREATE POLICY "Owners can manage purchase orders" ON purchase_orders FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

-- =====================================================
-- PURCHASE_ORDER_ITEMS - Owner/Manager dapat mengelola
-- =====================================================

DROP POLICY IF EXISTS "Owners can manage PO items" ON purchase_order_items;

CREATE POLICY "Owners can manage PO items" ON purchase_order_items FOR ALL
USING (EXISTS (
    SELECT 1 FROM purchase_orders po
    INNER JOIN profiles p ON p.id = auth.uid()
    WHERE po.id = purchase_order_items.purchase_order_id AND p.role IN ('owner', 'manager')
))
WITH CHECK (EXISTS (
    SELECT 1 FROM purchase_orders po
    INNER JOIN profiles p ON p.id = auth.uid()
    WHERE po.id = purchase_order_items.purchase_order_id AND p.role IN ('owner', 'manager')
));

-- =====================================================
-- STOCK_TRANSFER_ORDERS - Staff dapat request, Owner approve
-- =====================================================

DROP POLICY IF EXISTS "Owners can manage stock transfers" ON stock_transfer_orders;
DROP POLICY IF EXISTS "Staff can request stock transfers" ON stock_transfer_orders;

CREATE POLICY "Owners can manage stock transfers" ON stock_transfer_orders FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

CREATE POLICY "Staff can request stock transfers" ON stock_transfer_orders FOR INSERT
WITH CHECK (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = stock_transfer_orders.to_outlet_id
));

-- =====================================================
-- STOCK_TRANSFER_ITEMS - Mengikuti stock transfer order
-- =====================================================

DROP POLICY IF EXISTS "Owners can manage stock transfer items" ON stock_transfer_items;

CREATE POLICY "Owners can manage stock transfer items" ON stock_transfer_items FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

-- =====================================================
-- STOCK_OPNAME - Staff dapat create, Owner approve
-- =====================================================

DROP POLICY IF EXISTS "Owners can manage stock opname" ON stock_opname;
DROP POLICY IF EXISTS "Staff can create stock opname" ON stock_opname;

CREATE POLICY "Owners can manage stock opname" ON stock_opname FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

CREATE POLICY "Staff can create stock opname for their outlets" ON stock_opname FOR INSERT
WITH CHECK (
    stock_opname.outlet_id IS NULL 
    OR EXISTS (
        SELECT 1 FROM user_outlets 
        WHERE user_id = auth.uid() AND outlet_id = stock_opname.outlet_id
    )
);

-- =====================================================
-- STOCK_OPNAME_ITEMS - Mengikuti stock opname
-- =====================================================

DROP POLICY IF EXISTS "Owners can manage stock opname items" ON stock_opname_items;

CREATE POLICY "Owners can manage stock opname items" ON stock_opname_items FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

-- =====================================================
-- DAILY_CLOSING_REPORTS - Staff dapat create, Owner approve
-- =====================================================

DROP POLICY IF EXISTS "Owners can manage closing reports" ON daily_closing_reports;
DROP POLICY IF EXISTS "Staff can create closing reports" ON daily_closing_reports;

CREATE POLICY "Owners can manage closing reports" ON daily_closing_reports FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')))
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('owner', 'manager')));

CREATE POLICY "Staff can create closing reports for their outlets" ON daily_closing_reports FOR INSERT
WITH CHECK (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = daily_closing_reports.outlet_id
));

CREATE POLICY "Staff can update closing reports for their outlets" ON daily_closing_reports FOR UPDATE
USING (EXISTS (
    SELECT 1 FROM user_outlets 
    WHERE user_id = auth.uid() AND outlet_id = daily_closing_reports.outlet_id
));

COMMENT ON SCHEMA public IS 'Veroprise ERP - Complete RLS Policies v1.0';
