-- Create app_role enum for the 4 user types
CREATE TYPE public.app_role AS ENUM ('owner', 'manager', 'staff', 'investor');

-- Create user_roles table for role management (separate from profiles for security)
CREATE TABLE public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    role app_role NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    UNIQUE (user_id, role)
);

-- Enable RLS on user_roles
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Security definer function to check roles (prevents recursive RLS issues)
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role app_role)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _user_id
      AND role = _role
  )
$$;

-- Function to get user's primary role
CREATE OR REPLACE FUNCTION public.get_user_role(_user_id UUID)
RETURNS app_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role
  FROM public.user_roles
  WHERE user_id = _user_id
  LIMIT 1
$$;

-- Profiles table for user information
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    avatar_url TEXT,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Outlets table for multiple coffee shop locations
CREATE TABLE public.outlets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

ALTER TABLE public.outlets ENABLE ROW LEVEL SECURITY;

-- User-outlet assignments (managers/staff assigned to specific outlets)
CREATE TABLE public.user_outlets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    outlet_id UUID REFERENCES public.outlets(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    UNIQUE (user_id, outlet_id)
);

ALTER TABLE public.user_outlets ENABLE ROW LEVEL SECURITY;

-- Product categories
CREATE TABLE public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Products/Menu items
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(12,2) NOT NULL,
    cost_price DECIMAL(12,2) DEFAULT 0,
    image_url TEXT,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Shifts for staff session tracking
CREATE TABLE public.shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    outlet_id UUID REFERENCES public.outlets(id) ON DELETE CASCADE NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    ended_at TIMESTAMP WITH TIME ZONE,
    opening_cash DECIMAL(12,2) DEFAULT 0,
    closing_cash DECIMAL(12,2),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;

-- Payment method enum
CREATE TYPE public.payment_method AS ENUM ('cash', 'qris', 'transfer', 'card', 'split');

-- Transactions (sales)
CREATE TABLE public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    outlet_id UUID REFERENCES public.outlets(id) ON DELETE CASCADE NOT NULL,
    shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL NOT NULL,
    transaction_number TEXT NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    discount DECIMAL(12,2) DEFAULT 0,
    tax DECIMAL(12,2) DEFAULT 0,
    total DECIMAL(12,2) NOT NULL,
    payment_method payment_method NOT NULL,
    payment_details JSONB,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Transaction items (line items)
CREATE TABLE public.transaction_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID REFERENCES public.transactions(id) ON DELETE CASCADE NOT NULL,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    cost_price DECIMAL(12,2) DEFAULT 0,
    subtotal DECIMAL(12,2) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

ALTER TABLE public.transaction_items ENABLE ROW LEVEL SECURITY;

-- Expense categories
CREATE TABLE public.expense_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

ALTER TABLE public.expense_categories ENABLE ROW LEVEL SECURITY;

-- Expenses/Purchases
CREATE TABLE public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    outlet_id UUID REFERENCES public.outlets(id) ON DELETE CASCADE NOT NULL,
    category_id UUID REFERENCES public.expense_categories(id) ON DELETE SET NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL NOT NULL,
    approved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    description TEXT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    receipt_url TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    notes TEXT,
    expense_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

-- Inventory items (ingredients/supplies)
CREATE TABLE public.inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    unit TEXT NOT NULL,
    min_stock DECIMAL(12,2) DEFAULT 0,
    current_stock DECIMAL(12,2) DEFAULT 0,
    cost_per_unit DECIMAL(12,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;

-- Outlet inventory (stock per outlet)
CREATE TABLE public.outlet_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    outlet_id UUID REFERENCES public.outlets(id) ON DELETE CASCADE NOT NULL,
    inventory_item_id UUID REFERENCES public.inventory_items(id) ON DELETE CASCADE NOT NULL,
    quantity DECIMAL(12,2) DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    UNIQUE (outlet_id, inventory_item_id)
);

ALTER TABLE public.outlet_inventory ENABLE ROW LEVEL SECURITY;

-- Inventory transactions (stock in/out/waste/transfer)
CREATE TYPE public.inventory_transaction_type AS ENUM ('purchase', 'usage', 'waste', 'transfer_in', 'transfer_out', 'adjustment');

CREATE TABLE public.inventory_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    outlet_id UUID REFERENCES public.outlets(id) ON DELETE CASCADE NOT NULL,
    inventory_item_id UUID REFERENCES public.inventory_items(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL NOT NULL,
    type inventory_transaction_type NOT NULL,
    quantity DECIMAL(12,2) NOT NULL,
    reference_id UUID,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

ALTER TABLE public.inventory_transactions ENABLE ROW LEVEL SECURITY;

-- Audit trail for complete transparency
CREATE TABLE public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    table_name TEXT NOT NULL,
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Session logs for tracking who opened what
CREATE TABLE public.session_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    action TEXT NOT NULL,
    details JSONB,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

ALTER TABLE public.session_logs ENABLE ROW LEVEL SECURITY;

-- ============== RLS POLICIES ==============

-- User roles policies
CREATE POLICY "Users can view their own roles" ON public.user_roles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Owners can manage all roles" ON public.user_roles
    FOR ALL USING (public.has_role(auth.uid(), 'owner'));

-- Profiles policies
CREATE POLICY "Users can view all profiles" ON public.profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Outlets policies
CREATE POLICY "Authenticated users can view outlets" ON public.outlets
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Owners can manage outlets" ON public.outlets
    FOR ALL USING (public.has_role(auth.uid(), 'owner'));

-- User outlets policies
CREATE POLICY "Users can view their outlet assignments" ON public.user_outlets
    FOR SELECT USING (auth.uid() = user_id OR public.has_role(auth.uid(), 'owner'));

CREATE POLICY "Owners can manage outlet assignments" ON public.user_outlets
    FOR ALL USING (public.has_role(auth.uid(), 'owner'));

-- Categories policies
CREATE POLICY "Authenticated users can view categories" ON public.categories
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Owners and managers can manage categories" ON public.categories
    FOR ALL USING (public.has_role(auth.uid(), 'owner') OR public.has_role(auth.uid(), 'manager'));

-- Products policies
CREATE POLICY "Authenticated users can view products" ON public.products
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Owners and managers can manage products" ON public.products
    FOR ALL USING (public.has_role(auth.uid(), 'owner') OR public.has_role(auth.uid(), 'manager'));

-- Shifts policies
CREATE POLICY "Users can view their own shifts" ON public.shifts
    FOR SELECT USING (
        auth.uid() = user_id 
        OR public.has_role(auth.uid(), 'owner') 
        OR public.has_role(auth.uid(), 'manager')
    );

CREATE POLICY "Staff can create their own shifts" ON public.shifts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Staff can update their own shifts" ON public.shifts
    FOR UPDATE USING (auth.uid() = user_id);

-- Transactions policies
CREATE POLICY "Staff can view transactions from their outlet" ON public.transactions
    FOR SELECT USING (
        auth.uid() = user_id 
        OR public.has_role(auth.uid(), 'owner') 
        OR public.has_role(auth.uid(), 'manager')
        OR public.has_role(auth.uid(), 'investor')
    );

CREATE POLICY "Staff can create transactions" ON public.transactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Transaction items policies
CREATE POLICY "View transaction items with transaction access" ON public.transaction_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.transactions t 
            WHERE t.id = transaction_id 
            AND (t.user_id = auth.uid() 
                OR public.has_role(auth.uid(), 'owner') 
                OR public.has_role(auth.uid(), 'manager')
                OR public.has_role(auth.uid(), 'investor'))
        )
    );

CREATE POLICY "Staff can create transaction items" ON public.transaction_items
    FOR INSERT WITH CHECK (true);

-- Expense categories policies
CREATE POLICY "Authenticated users can view expense categories" ON public.expense_categories
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Owners can manage expense categories" ON public.expense_categories
    FOR ALL USING (public.has_role(auth.uid(), 'owner'));

-- Expenses policies
CREATE POLICY "Users can view expenses" ON public.expenses
    FOR SELECT USING (
        auth.uid() = user_id 
        OR public.has_role(auth.uid(), 'owner') 
        OR public.has_role(auth.uid(), 'manager')
        OR public.has_role(auth.uid(), 'investor')
    );

CREATE POLICY "Staff can create expenses" ON public.expenses
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Managers and owners can update expenses" ON public.expenses
    FOR UPDATE USING (public.has_role(auth.uid(), 'owner') OR public.has_role(auth.uid(), 'manager'));

-- Inventory items policies
CREATE POLICY "Authenticated users can view inventory items" ON public.inventory_items
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Owners and managers can manage inventory items" ON public.inventory_items
    FOR ALL USING (public.has_role(auth.uid(), 'owner') OR public.has_role(auth.uid(), 'manager'));

-- Outlet inventory policies
CREATE POLICY "Authenticated users can view outlet inventory" ON public.outlet_inventory
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Staff can update outlet inventory" ON public.outlet_inventory
    FOR ALL USING (
        public.has_role(auth.uid(), 'owner') 
        OR public.has_role(auth.uid(), 'manager')
        OR public.has_role(auth.uid(), 'staff')
    );

-- Inventory transactions policies
CREATE POLICY "Users can view inventory transactions" ON public.inventory_transactions
    FOR SELECT USING (
        public.has_role(auth.uid(), 'owner') 
        OR public.has_role(auth.uid(), 'manager')
        OR auth.uid() = user_id
    );

CREATE POLICY "Staff can create inventory transactions" ON public.inventory_transactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Audit logs policies (read-only, only owners can view)
CREATE POLICY "Owners can view audit logs" ON public.audit_logs
    FOR SELECT USING (public.has_role(auth.uid(), 'owner'));

CREATE POLICY "System can insert audit logs" ON public.audit_logs
    FOR INSERT WITH CHECK (true);

-- Session logs policies
CREATE POLICY "Owners can view all session logs" ON public.session_logs
    FOR SELECT USING (public.has_role(auth.uid(), 'owner'));

CREATE POLICY "Users can view own session logs" ON public.session_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create session logs" ON public.session_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============== TRIGGERS ==============

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_outlets_updated_at BEFORE UPDATE ON public.outlets
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON public.products
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_expenses_updated_at BEFORE UPDATE ON public.expenses
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_inventory_items_updated_at BEFORE UPDATE ON public.inventory_items
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_outlet_inventory_updated_at BEFORE UPDATE ON public.outlet_inventory
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (user_id, full_name)
    VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.email));
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Generate transaction number function
CREATE OR REPLACE FUNCTION public.generate_transaction_number()
RETURNS TRIGGER AS $$
DECLARE
    outlet_code TEXT;
    today_count INTEGER;
BEGIN
    -- Get outlet abbreviation
    SELECT UPPER(LEFT(name, 3)) INTO outlet_code FROM public.outlets WHERE id = NEW.outlet_id;
    
    -- Count today's transactions for this outlet
    SELECT COUNT(*) + 1 INTO today_count 
    FROM public.transactions 
    WHERE outlet_id = NEW.outlet_id 
    AND DATE(created_at) = CURRENT_DATE;
    
    -- Generate number: OUTLET-YYYYMMDD-####
    NEW.transaction_number := COALESCE(outlet_code, 'TRX') || '-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD(today_count::TEXT, 4, '0');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER generate_transaction_number_trigger
    BEFORE INSERT ON public.transactions
    FOR EACH ROW EXECUTE FUNCTION public.generate_transaction_number();

-- Insert default expense categories
INSERT INTO public.expense_categories (name, description) VALUES
    ('Bahan Baku', 'Pembelian bahan baku kopi, susu, dll'),
    ('Operasional', 'Biaya operasional harian'),
    ('Gaji', 'Pembayaran gaji karyawan'),
    ('Utilitas', 'Listrik, air, internet'),
    ('Peralatan', 'Pembelian/perbaikan peralatan'),
    ('Marketing', 'Biaya promosi dan marketing'),
    ('Lain-lain', 'Pengeluaran lainnya');

-- Insert default product categories
INSERT INTO public.categories (name, sort_order) VALUES
    ('Coffee', 1),
    ('Non-Coffee', 2),
    ('Tea', 3),
    ('Food', 4),
    ('Snacks', 5);

-- Enable realtime for key tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.transactions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.shifts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.outlet_inventory;