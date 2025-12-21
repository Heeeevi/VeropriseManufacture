-- Fix function search path for update_updated_at_column
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER 
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Fix function search path for generate_transaction_number
CREATE OR REPLACE FUNCTION public.generate_transaction_number()
RETURNS TRIGGER 
LANGUAGE plpgsql
SET search_path = public
AS $$
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
$$;