-- =====================================================
-- VEROPRISE ERP - WORK ORDER PROGRESS TRACKING
-- Target: Supabase PostgreSQL
-- Date: 2026-04-14
-- =====================================================

-- Add progress-related columns to work_orders if the table exists.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'work_orders'
  ) THEN
    ALTER TABLE public.work_orders
      ADD COLUMN IF NOT EXISTS progress_percentage NUMERIC(5,2) NOT NULL DEFAULT 0,
      ADD COLUMN IF NOT EXISTS item_completion_percentage NUMERIC(5,2) NOT NULL DEFAULT 0,
      ADD COLUMN IF NOT EXISTS produced_quantity NUMERIC(15,4) NOT NULL DEFAULT 0,
      ADD COLUMN IF NOT EXISTS progress_updated_at TIMESTAMPTZ;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.recalculate_work_order_progress(p_work_order_id UUID)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  v_status TEXT;
  v_target_qty NUMERIC(15,4);
  v_existing_produced NUMERIC(15,4);
  v_picked_count INTEGER;
  v_total_count INTEGER;
  v_item_ratio NUMERIC;
  v_progress NUMERIC;
  v_output_progress NUMERIC;
  v_produced_qty NUMERIC(15,4);
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'work_orders'
  ) THEN
    RETURN;
  END IF;

  SELECT status, target_quantity, produced_quantity
  INTO v_status, v_target_qty, v_existing_produced
  FROM public.work_orders
  WHERE id = p_work_order_id;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'work_order_items'
  ) THEN
    SELECT
      COUNT(*) FILTER (WHERE status = 'picked'),
      COUNT(*)
    INTO v_picked_count, v_total_count
    FROM public.work_order_items
    WHERE work_order_id = p_work_order_id;
  ELSE
    v_picked_count := 0;
    v_total_count := 0;
  END IF;

  v_item_ratio := CASE
    WHEN COALESCE(v_total_count, 0) = 0 THEN 0
    ELSE (v_picked_count::NUMERIC / v_total_count::NUMERIC)
  END;

  IF v_status = 'completed' THEN
    v_progress := 100;
    v_produced_qty := GREATEST(COALESCE(v_existing_produced, 0), COALESCE(v_target_qty, 0));
  ELSIF v_status = 'cancelled' THEN
    v_progress := 0;
    v_produced_qty := COALESCE(v_existing_produced, 0);
  ELSIF v_status = 'planned' THEN
    v_progress := LEAST(95, 8 + (v_item_ratio * 33));
    v_produced_qty := COALESCE(v_existing_produced, 0);
  ELSIF v_status = 'kitting' THEN
    v_progress := LEAST(95, 30 + (v_item_ratio * 33));
    v_produced_qty := COALESCE(v_existing_produced, 0);
  ELSIF v_status = 'in_progress' THEN
    v_progress := LEAST(95, 62 + (v_item_ratio * 33));
    v_produced_qty := COALESCE(v_existing_produced, 0);
  ELSE
    v_progress := LEAST(95, v_item_ratio * 100);
    v_produced_qty := COALESCE(v_existing_produced, 0);
  END IF;

  v_output_progress := CASE
    WHEN COALESCE(v_target_qty, 0) <= 0 THEN 0
    ELSE LEAST(100, (COALESCE(v_produced_qty, 0) / v_target_qty) * 100)
  END;

  IF v_status <> 'completed' AND v_status <> 'cancelled' THEN
    v_progress := GREATEST(v_progress, LEAST(95, v_output_progress));
  END IF;

  UPDATE public.work_orders
  SET
    progress_percentage = ROUND(v_progress, 2),
    item_completion_percentage = ROUND(v_item_ratio * 100, 2),
    produced_quantity = v_produced_qty,
    progress_updated_at = NOW()
  WHERE id = p_work_order_id;
END;
$$;

-- Trigger for item-level changes.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'work_order_items'
  ) THEN
    CREATE OR REPLACE FUNCTION public.trg_recalculate_work_order_progress_from_items()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $func_items$
    DECLARE
      v_work_order_id UUID;
    BEGIN
      v_work_order_id := COALESCE(NEW.work_order_id, OLD.work_order_id);
      PERFORM public.recalculate_work_order_progress(v_work_order_id);
      RETURN COALESCE(NEW, OLD);
    END;
    $func_items$;

    DROP TRIGGER IF EXISTS trg_work_order_items_recalculate_progress ON public.work_order_items;
    CREATE TRIGGER trg_work_order_items_recalculate_progress
    AFTER INSERT OR UPDATE OR DELETE ON public.work_order_items
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_recalculate_work_order_progress_from_items();
  END IF;
END $$;

-- Trigger for status changes on work_orders.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'work_orders'
  ) THEN
    CREATE OR REPLACE FUNCTION public.trg_recalculate_work_order_progress_from_wo()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $func_wo$
    BEGIN
      PERFORM public.recalculate_work_order_progress(NEW.id);
      RETURN NEW;
    END;
    $func_wo$;

    DROP TRIGGER IF EXISTS trg_work_orders_recalculate_progress ON public.work_orders;
    CREATE TRIGGER trg_work_orders_recalculate_progress
    AFTER INSERT OR UPDATE OF status, target_quantity ON public.work_orders
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_recalculate_work_order_progress_from_wo();
  END IF;
END $$;

-- Backfill existing work orders when possible.
DO $$
DECLARE
  wo RECORD;
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'work_orders'
  ) THEN
    FOR wo IN SELECT id FROM public.work_orders LOOP
      PERFORM public.recalculate_work_order_progress(wo.id);
    END LOOP;
  END IF;
END $$;
