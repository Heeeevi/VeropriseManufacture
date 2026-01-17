-- =====================================================
-- INSERT 2 USER OWNER - BarberDoc ERP
-- =====================================================
-- IMPORTANT: User creation harus dilakukan via Supabase Dashboard atau Auth API
-- karena password harus di-hash dengan bcrypt oleh Supabase Auth
-- 
-- Script ini hanya untuk INSERT profiles, user_roles, dan user_outlets
-- setelah user dibuat via Dashboard
-- =====================================================

-- STEP 1: Buat user via Supabase Dashboard terlebih dahulu
-- =====================================================
-- Go to: Supabase Dashboard > Authentication > Users > Add User
-- 
-- User 1:
--   Email: barberdoc@mail.com
--   Password: barberdoc123
--   Auto Confirm: Yes
--   Copy the UUID yang dihasilkan
--
-- User 2:
--   Email: barberdocmalayu@mail.com
--   Password: malayudoc123
--   Auto Confirm: Yes
--   Copy the UUID yang dihasilkan

-- =====================================================
-- STEP 2: INSERT Profiles, Roles, dan Outlet Assignment
-- =====================================================
-- Ganti 'USER1-UUID-HERE' dan 'USER2-UUID-HERE' dengan UUID yang didapat dari step 1

-- Insert Profiles
INSERT INTO public.profiles (user_id, full_name, phone)
VALUES 
  ('USER1-UUID-HERE', 'barberdoc_owner', '081234567890'),
  ('USER2-UUID-HERE', 'barberdoc_malayu', '081234567891');

-- Insert User Roles (Owner)
INSERT INTO public.user_roles (user_id, role)
VALUES 
  ('USER1-UUID-HERE', 'owner'),
  ('USER2-UUID-HERE', 'owner');

-- Insert User Outlets Assignment
-- User 1 -> BarberDoc Hampor
INSERT INTO public.user_outlets (user_id, outlet_id)
VALUES ('USER1-UUID-HERE', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');

-- User 2 -> BarberDoc Cabang Malayu
INSERT INTO public.user_outlets (user_id, outlet_id)
VALUES ('USER2-UUID-HERE', 'b2c3d4e5-f6a7-8901-bcde-f12345678901');

-- =====================================================
-- DONE!
-- =====================================================

-- Hasil:
-- ✅ 2 User Owner dengan profile lengkap
-- ✅ Role 'owner' assigned
-- ✅ Outlet assigned (1 user per outlet)
--
-- Login Credentials:
-- User 1: barberdoc@mail.com / barberdoc123
-- User 2: barberdocmalayu@mail.com / malayudoc123

-- =====================================================
-- ALTERNATIVE: Buat User via SQL (Experimental - Not Recommended)
-- =====================================================
-- Jika ingin coba buat user langsung via SQL (tidak disarankan):
-- 
-- INSERT INTO auth.users (
--   instance_id,
--   id,
--   aud,
--   role,
--   email,
--   encrypted_password,
--   email_confirmed_at,
--   raw_app_meta_data,
--   raw_user_meta_data,
--   created_at,
--   updated_at,
--   confirmation_token,
--   recovery_token,
--   email_change_token_new
-- )
-- VALUES (
--   '00000000-0000-0000-0000-000000000000',
--   gen_random_uuid(),
--   'authenticated',
--   'authenticated',
--   'barberdoc@mail.com',
--   crypt('barberdoc123', gen_salt('bf')), -- Requires pgcrypto extension
--   NOW(),
--   '{"provider":"email","providers":["email"]}',
--   '{}',
--   NOW(),
--   NOW(),
--   '',
--   '',
--   ''
-- );
-- 
-- NOTE: Method ini butuh extension pgcrypto dan mungkin tidak bekerja dengan RLS
-- Lebih baik gunakan Supabase Dashboard atau Auth API
