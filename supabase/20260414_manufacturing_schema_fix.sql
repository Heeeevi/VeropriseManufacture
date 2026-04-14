-- =====================================================
-- VEROPRISE ERP - MANUFACTURING SCHEMA FIX
-- Purpose: Fix missing columns/tables causing runtime errors
-- Date: 2026-04-14
-- =====================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------------------------------
-- UPDATED_AT HELPER
-- -----------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- -----------------------------------------------------
-- PRODUCTS: add missing UoM columns used by frontend
-- -----------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'products'
  ) THEN
    ALTER TABLE public.products
      ADD COLUMN IF NOT EXISTS purchase_unit TEXT,
      ADD COLUMN IF NOT EXISTS base_unit TEXT NOT NULL DEFAULT 'pcs',
      ADD COLUMN IF NOT EXISTS conversion_rate NUMERIC(15,4) NOT NULL DEFAULT 1;
  END IF;
END $$;

-- -----------------------------------------------------
-- BOM TABLE
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS public.product_bom_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  ingredient_product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  quantity NUMERIC(15,4) NOT NULL CHECK (quantity > 0),
  unit TEXT NOT NULL DEFAULT 'pcs',
  yield_percentage NUMERIC(5,2) NOT NULL DEFAULT 100 CHECK (yield_percentage > 0),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT chk_product_bom_not_self CHECK (product_id <> ingredient_product_id),
  CONSTRAINT uq_product_bom_product_ingredient UNIQUE (product_id, ingredient_product_id)
);

CREATE INDEX IF NOT EXISTS idx_product_bom_items_product ON public.product_bom_items(product_id);
CREATE INDEX IF NOT EXISTS idx_product_bom_items_ingredient ON public.product_bom_items(ingredient_product_id);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'product_bom_items'
  ) THEN
    ALTER TABLE public.product_bom_items
      ADD COLUMN IF NOT EXISTS yield_percentage NUMERIC(5,2) NOT NULL DEFAULT 100;
  END IF;
END $$;

DROP TRIGGER IF EXISTS trg_product_bom_items_updated_at ON public.product_bom_items;
CREATE TRIGGER trg_product_bom_items_updated_at
BEFORE UPDATE ON public.product_bom_items
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- -----------------------------------------------------
-- WORK ORDERS
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS public.work_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wo_number TEXT NOT NULL UNIQUE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  target_quantity NUMERIC(15,4) NOT NULL DEFAULT 0 CHECK (target_quantity >= 0),
  warehouse_id UUID NOT NULL REFERENCES public.warehouses(id) ON DELETE RESTRICT,
  status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'kitting', 'in_progress', 'completed', 'cancelled')),
  planned_date DATE,
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  assigned_to UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  notes TEXT,
  progress_percentage NUMERIC(5,2) NOT NULL DEFAULT 0,
  item_completion_percentage NUMERIC(5,2) NOT NULL DEFAULT 0,
  produced_quantity NUMERIC(15,4) NOT NULL DEFAULT 0,
  progress_updated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.work_order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  work_order_id UUID NOT NULL REFERENCES public.work_orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  planned_quantity NUMERIC(15,4) NOT NULL DEFAULT 0 CHECK (planned_quantity >= 0),
  actual_quantity NUMERIC(15,4) DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'picked')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_work_orders_product ON public.work_orders(product_id);
CREATE INDEX IF NOT EXISTS idx_work_orders_warehouse ON public.work_orders(warehouse_id);
CREATE INDEX IF NOT EXISTS idx_work_orders_status ON public.work_orders(status);
CREATE INDEX IF NOT EXISTS idx_work_order_items_work_order ON public.work_order_items(work_order_id);
CREATE INDEX IF NOT EXISTS idx_work_order_items_product ON public.work_order_items(product_id);

DROP TRIGGER IF EXISTS trg_work_orders_updated_at ON public.work_orders;
CREATE TRIGGER trg_work_orders_updated_at
BEFORE UPDATE ON public.work_orders
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_work_order_items_updated_at ON public.work_order_items;
CREATE TRIGGER trg_work_order_items_updated_at
BEFORE UPDATE ON public.work_order_items
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- -----------------------------------------------------
-- DISASSEMBLY
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS public.disassemblies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  disassembly_number TEXT NOT NULL UNIQUE,
  source_product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  source_warehouse_id UUID NOT NULL REFERENCES public.warehouses(id) ON DELETE RESTRICT,
  target_warehouse_id UUID NOT NULL REFERENCES public.warehouses(id) ON DELETE RESTRICT,
  quantity_used NUMERIC(15,4) NOT NULL DEFAULT 0 CHECK (quantity_used >= 0),
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'completed', 'cancelled')),
  performed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  completed_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.disassembly_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  disassembly_id UUID NOT NULL REFERENCES public.disassemblies(id) ON DELETE CASCADE,
  result_product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  quantity_produced NUMERIC(15,4) NOT NULL DEFAULT 0 CHECK (quantity_produced >= 0),
  cost_allocation_percentage NUMERIC(5,2) NOT NULL DEFAULT 100 CHECK (cost_allocation_percentage >= 0 AND cost_allocation_percentage <= 100),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_disassemblies_source_product ON public.disassemblies(source_product_id);
CREATE INDEX IF NOT EXISTS idx_disassemblies_source_warehouse ON public.disassemblies(source_warehouse_id);
CREATE INDEX IF NOT EXISTS idx_disassemblies_target_warehouse ON public.disassemblies(target_warehouse_id);
CREATE INDEX IF NOT EXISTS idx_disassembly_items_disassembly ON public.disassembly_items(disassembly_id);
CREATE INDEX IF NOT EXISTS idx_disassembly_items_result_product ON public.disassembly_items(result_product_id);

DROP TRIGGER IF EXISTS trg_disassemblies_updated_at ON public.disassemblies;
CREATE TRIGGER trg_disassemblies_updated_at
BEFORE UPDATE ON public.disassemblies
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- -----------------------------------------------------
-- POS SHIFTS (required by POS start/end shift flow)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS public.pos_shifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  outlet_id UUID NOT NULL REFERENCES public.outlets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  opening_cash NUMERIC(15,2) NOT NULL DEFAULT 0,
  closing_cash NUMERIC(15,2),
  expected_cash NUMERIC(15,2),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pos_shifts_outlet_user ON public.pos_shifts(outlet_id, user_id);
CREATE INDEX IF NOT EXISTS idx_pos_shifts_active ON public.pos_shifts(outlet_id, user_id, ended_at);
CREATE UNIQUE INDEX IF NOT EXISTS idx_pos_shifts_one_active_shift
  ON public.pos_shifts(outlet_id, user_id)
  WHERE ended_at IS NULL;

DROP TRIGGER IF EXISTS trg_pos_shifts_updated_at ON public.pos_shifts;
CREATE TRIGGER trg_pos_shifts_updated_at
BEFORE UPDATE ON public.pos_shifts
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'transactions'
  ) THEN
    ALTER TABLE public.transactions
      ADD COLUMN IF NOT EXISTS shift_id UUID REFERENCES public.pos_shifts(id) ON DELETE SET NULL;

    CREATE INDEX IF NOT EXISTS idx_transactions_shift_id ON public.transactions(shift_id);
  END IF;
END $$;

-- -----------------------------------------------------
-- RLS + GRANTS
-- -----------------------------------------------------
ALTER TABLE public.product_bom_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.work_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.work_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.disassemblies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.disassembly_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pos_shifts ENABLE ROW LEVEL SECURITY;

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.product_bom_items TO anon, authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.work_orders TO anon, authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.work_order_items TO anon, authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.disassemblies TO anon, authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.disassembly_items TO anon, authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.pos_shifts TO anon, authenticated, service_role;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'product_bom_items' AND policyname = 'Authenticated users can manage product_bom_items'
  ) THEN
    CREATE POLICY "Authenticated users can manage product_bom_items"
    ON public.product_bom_items
    FOR ALL USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'work_orders' AND policyname = 'Authenticated users can manage work_orders'
  ) THEN
    CREATE POLICY "Authenticated users can manage work_orders"
    ON public.work_orders
    FOR ALL USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'work_order_items' AND policyname = 'Authenticated users can manage work_order_items'
  ) THEN
    CREATE POLICY "Authenticated users can manage work_order_items"
    ON public.work_order_items
    FOR ALL USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'disassemblies' AND policyname = 'Authenticated users can manage disassemblies'
  ) THEN
    CREATE POLICY "Authenticated users can manage disassemblies"
    ON public.disassemblies
    FOR ALL USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'disassembly_items' AND policyname = 'Authenticated users can manage disassembly_items'
  ) THEN
    CREATE POLICY "Authenticated users can manage disassembly_items"
    ON public.disassembly_items
    FOR ALL USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'pos_shifts' AND policyname = 'Authenticated users can manage pos_shifts'
  ) THEN
    CREATE POLICY "Authenticated users can manage pos_shifts"
    ON public.pos_shifts
    FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;

-- -----------------------------------------------------
-- POSTGREST CACHE RELOAD
-- -----------------------------------------------------
NOTIFY pgrst, 'reload schema';
