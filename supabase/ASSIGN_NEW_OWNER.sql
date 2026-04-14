-- =====================================================
-- ASSIGN NEW OWNER USER
-- NOTE:
-- 1) User auth (email + password) MUST be created first in Supabase Auth.
-- 2) This script maps that auth user into public.profiles + outlet owner access.
-- =====================================================

DO $$
DECLARE
    v_owner_id_input UUID := '15e4c0e1-77af-4226-bb3e-724d2c98d713';
    v_owner_email TEXT := 'vero@prise.com';
    v_owner_phone TEXT := '081234567890';
    v_owner_name TEXT := 'Veroprise Owner';
    v_owner_id UUID;
    v_outlet_id UUID;
BEGIN
    -- 1) Resolve owner UUID from auth.users (prioritize explicit UUID, fallback by email)
    SELECT id INTO v_owner_id
    FROM auth.users
    WHERE id = v_owner_id_input
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_owner_id IS NULL THEN
        SELECT id INTO v_owner_id
        FROM auth.users
        WHERE email = v_owner_email
        ORDER BY created_at DESC
        LIMIT 1;
    END IF;

    IF v_owner_id IS NULL THEN
        RAISE EXCEPTION 'Owner UUID % / email % tidak ditemukan di auth.users. Buat user ini dulu di Supabase Auth (email + password), lalu jalankan script ini lagi.', v_owner_id_input, v_owner_email;
    END IF;

    SELECT email INTO v_owner_email
    FROM auth.users
    WHERE id = v_owner_id;

    -- 2) Create/Update profile with owner role (id follows auth.users.id)
    INSERT INTO public.profiles (id, email, full_name, phone, role, created_at, updated_at)
    VALUES (
        v_owner_id,
        v_owner_email,
        v_owner_name,
        v_owner_phone,
        'owner',
        NOW(),
        NOW()
    )
    ON CONFLICT (id)
    DO UPDATE SET
        email = EXCLUDED.email,
        role = 'owner',
        full_name = EXCLUDED.full_name,
        phone = EXCLUDED.phone,
        updated_at = NOW();

    -- 3) Create outlet if not exists
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

    -- 4) Assign owner to outlet
    SELECT id INTO v_outlet_id
    FROM public.outlets
    WHERE name = 'Veroprise Barbershop - Central'
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_outlet_id IS NOT NULL THEN
        INSERT INTO public.user_outlets (user_id, outlet_id, role)
        VALUES (
            v_owner_id,
            v_outlet_id,
            'owner'
        )
        ON CONFLICT (user_id, outlet_id) DO UPDATE SET role = 'owner';
        
        RAISE NOTICE '✅ Owner assigned to outlet: %', v_outlet_id;
    ELSE
        RAISE NOTICE '❌ No outlet found';
    END IF;

    -- 5) Create warehouse if not exists
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

    RAISE NOTICE '✅ Owner setup selesai untuk user_id=%', v_owner_id;
END $$;

-- 6. Verify setup
SELECT 
    '✅ User Profile' as step,
    p.email,
    p.full_name,
    p.role::text as role
FROM public.profiles p
WHERE p.email = 'vero@prise.com'

UNION ALL

SELECT 
    '✅ Outlet Assignment' as step,
    o.name as email,
    uo.role::text as full_name,
    'assigned' as role
FROM public.user_outlets uo
INNER JOIN public.outlets o ON o.id = uo.outlet_id
WHERE uo.user_id = (SELECT id FROM public.profiles WHERE email = 'vero@prise.com' LIMIT 1)

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
WHERE p.email = 'vero@prise.com';

-- =====================================================
-- DONE! User vero@prise.com is now owner with full access
-- =====================================================
