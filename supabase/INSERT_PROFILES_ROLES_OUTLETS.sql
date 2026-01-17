-- =====================================================
-- INSERT PROFILES, ROLES, DAN OUTLET ASSIGNMENT
-- =====================================================
-- ⚠️ BACA DULU: supabase/CARA_BUAT_USER_OWNER.md
-- 
-- STEP 1: Buat user dulu via Supabase Dashboard:
--   1. Dashboard > Authentication > Users > Add User
--   2. User 1: barberdoc@mail.com / barberdoc123
--   3. User 2: barberdocmalayu@mail.com / malayudoc123
--   4. CENTANG "Auto Confirm User"
--   5. COPY UUID masing-masing user
--
-- STEP 2: GANTI <UUID_USER_1> dan <UUID_USER_2> di bawah dengan UUID yang Anda copy
-- STEP 3: Jalankan SQL ini di SQL Editor
-- =====================================================

-- Insert Profiles
INSERT INTO public.profiles (user_id, full_name, phone)
VALUES 
  ('<UUID_USER_1>', 'BarberDoc Owner Hampor', '6289530078075'),
  ('<UUID_USER_2>', 'BarberDoc Owner Malayu', '6289530078076')
ON CONFLICT (user_id) DO NOTHING;

-- Insert User Roles (Owner)
INSERT INTO public.user_roles (user_id, role)
VALUES 
  ('<UUID_USER_1>', 'owner'),
  ('<UUID_USER_2>', 'owner')
ON CONFLICT (user_id, role) DO NOTHING;

-- Insert User Outlets Assignment
-- User 1 -> BarberDoc Hampor
INSERT INTO public.user_outlets (user_id, outlet_id)
VALUES ('<UUID_USER_1>', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890')
ON CONFLICT (user_id, outlet_id) DO NOTHING;

-- User 2 -> BarberDoc Cabang Malayu
INSERT INTO public.user_outlets (user_id, outlet_id)
VALUES ('<UUID_USER_2>', 'b2c3d4e5-f6a7-8901-bcde-f12345678901')
ON CONFLICT (user_id, outlet_id) DO NOTHING;

-- =====================================================
-- ✅ SELESAI!
-- =====================================================
-- 
-- Verifikasi dengan query ini:
-- 
-- SELECT p.user_id, p.full_name, u.email, ur.role, o.name AS outlet
-- FROM profiles p
-- JOIN auth.users u ON p.user_id = u.id
-- JOIN user_roles ur ON p.user_id = ur.user_id
-- JOIN user_outlets uo ON p.user_id = uo.user_id
-- JOIN outlets o ON uo.outlet_id = o.id
-- WHERE u.email IN ('barberdoc@mail.com', 'barberdocmalayu@mail.com');
-- =====================================================
