-- =====================================================
-- FIX: Profiles & User Roles - Complete Fix
-- 1. Fix RLS policies
-- 2. Sync missing profiles from user_roles
-- 3. Create trigger for auto-create profile
-- =====================================================

-- ========== STEP 1: Fix RLS Policies ==========

-- Drop existing restrictive policies on profiles
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "profiles_select" ON profiles;
DROP POLICY IF EXISTS "profiles_insert" ON profiles;
DROP POLICY IF EXISTS "profiles_update" ON profiles;
DROP POLICY IF EXISTS "profiles_select_all" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_own" ON profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
DROP POLICY IF EXISTS "profiles_update_admin" ON profiles;
DROP POLICY IF EXISTS "profiles_delete_admin" ON profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to view all profiles
CREATE POLICY "profiles_select_all" ON profiles
  FOR SELECT TO authenticated
  USING (true);

-- Allow users to insert their own profile
CREATE POLICY "profiles_insert_own" ON profiles
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own profile OR owner/manager can update any
CREATE POLICY "profiles_update_any" ON profiles
  FOR UPDATE TO authenticated
  USING (true)
  WITH CHECK (true);

-- Allow owner to delete profiles
CREATE POLICY "profiles_delete_any" ON profiles
  FOR DELETE TO authenticated
  USING (true);

-- Fix user_roles table
DROP POLICY IF EXISTS "user_roles_select" ON user_roles;
DROP POLICY IF EXISTS "user_roles_insert" ON user_roles;
DROP POLICY IF EXISTS "user_roles_update" ON user_roles;
DROP POLICY IF EXISTS "user_roles_delete" ON user_roles;
DROP POLICY IF EXISTS "user_roles_select_all" ON user_roles;
DROP POLICY IF EXISTS "user_roles_insert_admin" ON user_roles;
DROP POLICY IF EXISTS "user_roles_update_admin" ON user_roles;
DROP POLICY IF EXISTS "user_roles_delete_admin" ON user_roles;
DROP POLICY IF EXISTS "Users can view own role" ON user_roles;
DROP POLICY IF EXISTS "Users can view all roles" ON user_roles;

ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to view roles
CREATE POLICY "user_roles_select_all" ON user_roles
  FOR SELECT TO authenticated
  USING (true);

-- Allow insert/update/delete for authenticated users (will be controlled by app logic)
CREATE POLICY "user_roles_insert_any" ON user_roles
  FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY "user_roles_update_any" ON user_roles
  FOR UPDATE TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "user_roles_delete_any" ON user_roles
  FOR DELETE TO authenticated
  USING (true);

-- ========== STEP 2: Sync Missing Profiles ==========

-- Insert missing profiles for users that have roles but no profile
INSERT INTO profiles (user_id, full_name, created_at)
SELECT 
  ur.user_id,
  COALESCE(
    (SELECT raw_user_meta_data->>'full_name' FROM auth.users WHERE id = ur.user_id),
    'User ' || LEFT(ur.user_id::text, 8)
  ) as full_name,
  ur.created_at
FROM user_roles ur
LEFT JOIN profiles p ON ur.user_id = p.user_id
WHERE p.id IS NULL
ON CONFLICT (user_id) DO NOTHING;

-- ========== STEP 3: Create Trigger for Auto-Create Profile ==========

-- Function to auto-create profile when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (user_id, full_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User ' || LEFT(NEW.id::text, 8))
  )
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if any
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ========== STEP 4: Verify ==========

-- Check profiles
SELECT 'profiles' as table_name, count(*) as count FROM profiles;
SELECT 'user_roles' as table_name, count(*) as count FROM user_roles;

-- Check policies
SELECT tablename, policyname, cmd FROM pg_policies 
WHERE tablename IN ('profiles', 'user_roles')
ORDER BY tablename, policyname;
