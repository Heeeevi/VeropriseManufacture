-- =====================================================
-- VEROPRISE ERP - SETUP OWNER USER
-- Run this SQL after user registered via Supabase Auth
-- =====================================================

-- USER INFO:
-- ID: f5ea2bae-0fc0-4f76-89b5-6a85a499f7b8
-- Username: veroprise_owner
-- Email: vero@prise.com

-- =====================================================
-- 1. INSERT/UPDATE PROFILE WITH OWNER ROLE
-- =====================================================

INSERT INTO public.profiles (id, email, full_name, phone, role, created_at, updated_at)
VALUES (
    'f5ea2bae-0fc0-4f76-89b5-6a85a499f7b8',
    'vero@prise.com',
    'Veroprise Owner',
    NULL,
    'owner',
    NOW(),
    NOW()
)
ON CONFLICT (id) 
DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    role = 'owner',
    updated_at = NOW();

-- =====================================================
-- 2. CREATE DEMO OUTLET (OPTIONAL)
-- =====================================================

INSERT INTO public.outlets (
    id,
    name,
    address,
    phone,
    email,
    status,
    opening_time,
    closing_time,
    max_booking_days_ahead,
    created_at,
    updated_at
)
VALUES (
    gen_random_uuid(),
    'Veroprise Barbershop - Central',
    'Jl. Contoh No. 123, Jakarta',
    '021-12345678',
    'central@veroprise.com',
    'active',
    '09:00:00',
    '21:00:00',
    30,
    NOW(),
    NOW()
)
RETURNING id; -- Save this ID for next step

-- =====================================================
-- 3. ASSIGN OWNER TO OUTLET
-- Replace 'OUTLET_ID_HERE' with the ID from step 2
-- =====================================================

-- Example:
-- INSERT INTO public.user_outlets (user_id, outlet_id, role, created_at)
-- VALUES (
--     'f5ea2bae-0fc0-4f76-89b5-6a85a499f7b8',
--     'OUTLET_ID_HERE',
--     'owner',
--     NOW()
-- );

-- =====================================================
-- 4. CREATE DEMO WAREHOUSE (OPTIONAL)
-- =====================================================

INSERT INTO public.warehouses (
    code,
    name,
    address,
    phone,
    warehouse_type,
    is_active,
    created_at,
    updated_at
)
VALUES (
    'WH-001',
    'Veroprise Central Warehouse',
    'Jl. Gudang Raya No. 45, Jakarta',
    '021-87654321',
    'central',
    true,
    NOW(),
    NOW()
)
ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    address = EXCLUDED.address,
    phone = EXCLUDED.phone,
    is_active = true,
    updated_at = NOW();

-- =====================================================
-- 5. VERIFY USER SETUP
-- =====================================================

-- Check profile
SELECT id, email, full_name, role, created_at
FROM public.profiles
WHERE id = 'f5ea2bae-0fc0-4f76-89b5-6a85a499f7b8';

-- Check outlets
SELECT id, name, address, status
FROM public.outlets
ORDER BY created_at DESC
LIMIT 5;

-- Check user outlet assignments
SELECT 
    uo.id,
    p.email,
    p.full_name,
    o.name as outlet_name,
    uo.role
FROM public.user_outlets uo
INNER JOIN public.profiles p ON p.id = uo.user_id
INNER JOIN public.outlets o ON o.id = uo.outlet_id
WHERE uo.user_id = 'f5ea2bae-0fc0-4f76-89b5-6a85a499f7b8';

-- =====================================================
-- 6. COMPLETE SETUP (RUN AFTER GETTING OUTLET ID)
-- =====================================================

-- Get the outlet ID first
DO $$
DECLARE
    v_outlet_id UUID;
BEGIN
    -- Get the most recent outlet (assumed to be the one we just created)
    SELECT id INTO v_outlet_id
    FROM public.outlets
    WHERE name = 'Veroprise Barbershop - Central'
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- Assign owner to outlet
    IF v_outlet_id IS NOT NULL THEN
        INSERT INTO public.user_outlets (user_id, outlet_id, role, created_at)
        VALUES (
            'f5ea2bae-0fc0-4f76-89b5-6a85a499f7b8',
            v_outlet_id,
            'owner',
            NOW()
        )
        ON CONFLICT (user_id, outlet_id) DO NOTHING;
        
        RAISE NOTICE 'Owner assigned to outlet: %', v_outlet_id;
    ELSE
        RAISE NOTICE 'No outlet found to assign';
    END IF;
END $$;

-- =====================================================
-- VERIFICATION COMPLETE
-- =====================================================

-- Final check - should return data
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.role as user_role,
    o.name as outlet_name,
    uo.role as outlet_role
FROM public.profiles p
LEFT JOIN public.user_outlets uo ON uo.user_id = p.id
LEFT JOIN public.outlets o ON o.id = uo.outlet_id
WHERE p.id = 'f5ea2bae-0fc0-4f76-89b5-6a85a499f7b8';

-- =====================================================
-- NOTES:
-- =====================================================
-- 1. User must be created in Supabase Auth first (via signup)
-- 2. This SQL will create the profile with 'owner' role
-- 3. Creates a demo outlet and assigns owner to it
-- 4. Creates a demo warehouse
-- 5. Owner can now login and access all features
--
-- After running this SQL:
-- ✅ User can login with: vero@prise.com
-- ✅ User has 'owner' role (full access)
-- ✅ User is assigned to outlet (can manage inventory, POS, etc)
-- ✅ Warehouse is ready for purchase orders
-- =====================================================

COMMENT ON TABLE profiles IS 'Owner user setup completed for f5ea2bae-0fc0-4f76-89b5-6a85a499f7b8';
