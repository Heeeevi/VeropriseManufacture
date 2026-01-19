-- =====================================================
-- ASSIGN NEW OWNER USER
-- User ID: 6bf35817-979d-4b8b-ad54-7a1e5c1148a7
-- Email: vero@prise.com
-- =====================================================

-- 1. Create/Update profile with owner role
INSERT INTO public.profiles (id, email, full_name, phone, role, created_at, updated_at)
VALUES (
    '6bf35817-979d-4b8b-ad54-7a1e5c1148a7',
    'vero@prise.com',
    'Veroprise Owner',
    '081234567890',
    'owner',
    NOW(),
    NOW()
)
ON CONFLICT (id) 
DO UPDATE SET
    role = 'owner',
    full_name = EXCLUDED.full_name,
    updated_at = NOW();

-- 2. Create outlet if not exists
INSERT INTO public.outlets (
    name,
    address,
    phone,
    email,
    status,
    opening_time,
    closing_time,
    max_booking_days_ahead
)
VALUES (
    'Veroprise Barbershop - Central',
    'Jl. Contoh No. 123, Jakarta Pusat',
    '021-12345678',
    'central@veroprise.com',
    'active',
    '09:00:00',
    '21:00:00',
    30
)
ON CONFLICT DO NOTHING;

-- 3. Assign owner to outlet
DO $$
DECLARE
    v_outlet_id UUID;
BEGIN
    -- Get the outlet
    SELECT id INTO v_outlet_id
    FROM public.outlets
    WHERE name = 'Veroprise Barbershop - Central'
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- Assign owner
    IF v_outlet_id IS NOT NULL THEN
        INSERT INTO public.user_outlets (user_id, outlet_id, role)
        VALUES (
            '6bf35817-979d-4b8b-ad54-7a1e5c1148a7',
            v_outlet_id,
            'owner'
        )
        ON CONFLICT (user_id, outlet_id) DO UPDATE SET role = 'owner';
        
        RAISE NOTICE '✅ Owner assigned to outlet: %', v_outlet_id;
    ELSE
        RAISE NOTICE '❌ No outlet found';
    END IF;
END $$;

-- 4. Create warehouse if not exists
INSERT INTO public.warehouses (
    code,
    name,
    address,
    phone,
    warehouse_type,
    is_active
)
VALUES (
    'WH-001',
    'Veroprise Central Warehouse',
    'Jl. Gudang Raya No. 45, Jakarta',
    '021-87654321',
    'central',
    true
)
ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    is_active = true,
    updated_at = NOW();

-- 5. Verify setup
SELECT 
    '✅ User Profile' as step,
    p.email,
    p.full_name,
    p.role::text as role
FROM public.profiles p
WHERE p.id = '6bf35817-979d-4b8b-ad54-7a1e5c1148a7'

UNION ALL

SELECT 
    '✅ Outlet Assignment' as step,
    o.name as email,
    uo.role::text as full_name,
    'assigned' as role
FROM public.user_outlets uo
INNER JOIN public.outlets o ON o.id = uo.outlet_id
WHERE uo.user_id = '6bf35817-979d-4b8b-ad54-7a1e5c1148a7'

UNION ALL

SELECT 
    '✅ Warehouse' as step,
    w.code as email,
    w.name as full_name,
    w.warehouse_type::text as role
FROM public.warehouses w
WHERE w.code = 'WH-001'
LIMIT 1;

-- =====================================================
-- EXPECTED RESULT:
-- ✅ User Profile  | vero@prise.com | Veroprise Owner | owner
-- ✅ Outlet Assignment | Veroprise Barbershop - Central | owner | assigned
-- ✅ Warehouse | WH-001 | Veroprise Central Warehouse | central
-- =====================================================

-- Final verification
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.role::text as user_role,
    o.name as outlet_name,
    uo.role::text as outlet_role
FROM public.profiles p
LEFT JOIN public.user_outlets uo ON uo.user_id = p.id
LEFT JOIN public.outlets o ON o.id = uo.outlet_id
WHERE p.id = '6bf35817-979d-4b8b-ad54-7a1e5c1148a7';

-- =====================================================
-- DONE! User vero@prise.com is now owner with full access
-- =====================================================
