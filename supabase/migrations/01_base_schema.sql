-- =====================================================
-- VEROPRISE ERP - BASE SCHEMA
-- Harus dijalankan PERTAMA KALI di Supabase SQL Editor
-- =====================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- ENUMS
-- =====================================================

CREATE TYPE user_role AS ENUM ('owner', 'manager', 'staff', 'customer');
CREATE TYPE outlet_status AS ENUM ('active', 'inactive', 'maintenance');
CREATE TYPE transaction_status AS ENUM ('pending', 'completed', 'cancelled', 'refunded');
CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'completed', 'cancelled', 'no_show');
CREATE TYPE shift_type AS ENUM ('opening', 'closing', 'full_day');
CREATE TYPE expense_category AS ENUM ('operational', 'maintenance', 'marketing', 'salary', 'utilities', 'supplies', 'other');
CREATE TYPE inventory_transaction_type AS ENUM ('in', 'out', 'adjustment', 'waste', 'transfer', 'return');

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

-- Outlets table
CREATE TABLE outlets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    status outlet_status NOT NULL DEFAULT 'active',
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

-- Categories table
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    color TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Products table
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
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

-- Inventory table
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

-- Inventory transactions table
CREATE TABLE inventory_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    transaction_type inventory_transaction_type NOT NULL,
    quantity DECIMAL(15,2) NOT NULL,
    unit_cost DECIMAL(15,2),
    total_cost DECIMAL(15,2),
    reference_id UUID,
    reference_type TEXT,
    notes TEXT,
    performed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

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
    quantity DECIMAL(15,2) NOT NULL,
    unit_price DECIMAL(15,2) NOT NULL,
    discount DECIMAL(15,2) NOT NULL DEFAULT 0,
    subtotal DECIMAL(15,2) NOT NULL,
    commission_amount DECIMAL(15,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

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

CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_user_outlets_user ON user_outlets(user_id);
CREATE INDEX idx_user_outlets_outlet ON user_outlets(outlet_id);
CREATE INDEX idx_employees_outlet ON employees(outlet_id);
CREATE INDEX idx_employees_user ON employees(user_id);
CREATE INDEX idx_shifts_outlet_date ON shifts(outlet_id, shift_date);
CREATE INDEX idx_shifts_employee ON shifts(employee_id);
CREATE INDEX idx_products_outlet ON products(outlet_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_inventory_outlet_product ON inventory(outlet_id, product_id);
CREATE INDEX idx_inventory_transactions_outlet ON inventory_transactions(outlet_id);
CREATE INDEX idx_inventory_transactions_product ON inventory_transactions(product_id);
CREATE INDEX idx_transactions_outlet_date ON transactions(outlet_id, transaction_date);
CREATE INDEX idx_transactions_employee ON transactions(employee_id);
CREATE INDEX idx_transaction_items_transaction ON transaction_items(transaction_id);
CREATE INDEX idx_transaction_items_product ON transaction_items(product_id);
CREATE INDEX idx_bookings_outlet_date ON bookings(outlet_id, booking_date);
CREATE INDEX idx_bookings_employee ON bookings(employee_id);
CREATE INDEX idx_expenses_outlet_date ON expenses(outlet_id, expense_date);

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Outlets policies
CREATE POLICY "Users can view outlets they belong to" ON outlets FOR SELECT
USING (EXISTS (SELECT 1 FROM user_outlets WHERE user_id = auth.uid() AND outlet_id = outlets.id));

-- User outlets policies
CREATE POLICY "Users can view own outlet assignments" ON user_outlets FOR SELECT
USING (user_id = auth.uid());

-- Employees policies
CREATE POLICY "Users can view employees in their outlets" ON employees FOR SELECT
USING (EXISTS (SELECT 1 FROM user_outlets WHERE user_id = auth.uid() AND outlet_id = employees.outlet_id));

-- Shifts policies
CREATE POLICY "Users can view shifts in their outlets" ON shifts FOR SELECT
USING (EXISTS (SELECT 1 FROM user_outlets WHERE user_id = auth.uid() AND outlet_id = shifts.outlet_id));

-- Categories policies
CREATE POLICY "Anyone can view active categories" ON categories FOR SELECT USING (is_active = true);

-- Products policies
CREATE POLICY "Users can view products in their outlets" ON products FOR SELECT
USING (EXISTS (SELECT 1 FROM user_outlets WHERE user_id = auth.uid() AND outlet_id = products.outlet_id));

-- Inventory policies
CREATE POLICY "Users can view inventory in their outlets" ON inventory FOR SELECT
USING (EXISTS (SELECT 1 FROM user_outlets WHERE user_id = auth.uid() AND outlet_id = inventory.outlet_id));

-- Inventory transactions policies
CREATE POLICY "Users can view inventory transactions in their outlets" ON inventory_transactions FOR SELECT
USING (EXISTS (SELECT 1 FROM user_outlets WHERE user_id = auth.uid() AND outlet_id = inventory_transactions.outlet_id));

-- Transactions policies
CREATE POLICY "Users can view transactions in their outlets" ON transactions FOR SELECT
USING (EXISTS (SELECT 1 FROM user_outlets WHERE user_id = auth.uid() AND outlet_id = transactions.outlet_id));

-- Transaction items policies
CREATE POLICY "Users can view transaction items in their outlets" ON transaction_items FOR SELECT
USING (EXISTS (
    SELECT 1 FROM transactions t
    INNER JOIN user_outlets uo ON uo.outlet_id = t.outlet_id
    WHERE t.id = transaction_items.transaction_id AND uo.user_id = auth.uid()
));

-- Bookings policies
CREATE POLICY "Users can view bookings in their outlets" ON bookings FOR SELECT
USING (EXISTS (SELECT 1 FROM user_outlets WHERE user_id = auth.uid() AND outlet_id = bookings.outlet_id));

CREATE POLICY "Public can create bookings" ON bookings FOR INSERT
WITH CHECK (true);

-- Expenses policies
CREATE POLICY "Users can view expenses in their outlets" ON expenses FOR SELECT
USING (EXISTS (SELECT 1 FROM user_outlets WHERE user_id = auth.uid() AND outlet_id = expenses.outlet_id));

-- =====================================================
-- INITIAL DATA
-- =====================================================

-- Insert default categories
INSERT INTO categories (name, description, icon, color) VALUES
('Haircut', 'Basic haircut services', 'scissors', '#3B82F6'),
('Shaving', 'Shaving and beard services', 'razor', '#10B981'),
('Coloring', 'Hair coloring services', 'paint', '#F59E0B'),
('Treatment', 'Hair treatment services', 'heart', '#EF4444'),
('Products', 'Hair care products', 'shopping-bag', '#8B5CF6');

COMMENT ON DATABASE postgres IS 'Veroprise ERP - Base Schema v1.0';
