-- =====================================================
-- FIX: User Outlets RLS Policies
-- Allow owner to manage user-outlet assignments
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "user_outlets_select" ON user_outlets;
DROP POLICY IF EXISTS "user_outlets_insert" ON user_outlets;
DROP POLICY IF EXISTS "user_outlets_update" ON user_outlets;
DROP POLICY IF EXISTS "user_outlets_delete" ON user_outlets;
DROP POLICY IF EXISTS "user_outlets_select_all" ON user_outlets;
DROP POLICY IF EXISTS "user_outlets_insert_admin" ON user_outlets;
DROP POLICY IF EXISTS "user_outlets_update_admin" ON user_outlets;
DROP POLICY IF EXISTS "user_outlets_delete_admin" ON user_outlets;

-- Enable RLS
ALTER TABLE user_outlets ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to view user_outlets
CREATE POLICY "user_outlets_select_all" ON user_outlets
  FOR SELECT TO authenticated
  USING (true);

-- Allow insert for authenticated users (app will control who can assign)
CREATE POLICY "user_outlets_insert_any" ON user_outlets
  FOR INSERT TO authenticated
  WITH CHECK (true);

-- Allow update for authenticated users
CREATE POLICY "user_outlets_update_any" ON user_outlets
  FOR UPDATE TO authenticated
  USING (true)
  WITH CHECK (true);

-- Allow delete for authenticated users
CREATE POLICY "user_outlets_delete_any" ON user_outlets
  FOR DELETE TO authenticated
  USING (true);

-- =====================================================
-- Also fix outlets table RLS if needed
-- =====================================================

DROP POLICY IF EXISTS "outlets_select" ON outlets;
DROP POLICY IF EXISTS "outlets_insert" ON outlets;
DROP POLICY IF EXISTS "outlets_update" ON outlets;
DROP POLICY IF EXISTS "outlets_delete" ON outlets;
DROP POLICY IF EXISTS "outlets_select_all" ON outlets;
DROP POLICY IF EXISTS "outlets_insert_admin" ON outlets;
DROP POLICY IF EXISTS "outlets_update_admin" ON outlets;
DROP POLICY IF EXISTS "outlets_delete_admin" ON outlets;
DROP POLICY IF EXISTS "Outlets are viewable by authenticated users" ON outlets;
DROP POLICY IF EXISTS "Owners can manage outlets" ON outlets;

ALTER TABLE outlets ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to view outlets
CREATE POLICY "outlets_select_all" ON outlets
  FOR SELECT TO authenticated
  USING (true);

-- Allow insert for authenticated users
CREATE POLICY "outlets_insert_any" ON outlets
  FOR INSERT TO authenticated
  WITH CHECK (true);

-- Allow update for authenticated users
CREATE POLICY "outlets_update_any" ON outlets
  FOR UPDATE TO authenticated
  USING (true)
  WITH CHECK (true);

-- Allow delete for authenticated users
CREATE POLICY "outlets_delete_any" ON outlets
  FOR DELETE TO authenticated
  USING (true);

-- =====================================================
-- Verify: Check current user_outlets data
-- =====================================================

-- SELECT * FROM user_outlets;
-- SELECT * FROM outlets;
