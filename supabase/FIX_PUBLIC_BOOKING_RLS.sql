-- =====================================================
-- FIX PUBLIC BOOKING RLS - ALLOW ANONYMOUS ACCESS
-- =====================================================
-- Run this in Supabase SQL Editor
-- This allows public (non-authenticated) users to:
-- 1. Create bookings
-- 2. View booked slots (to show availability)
-- =====================================================

-- ==========================================
-- STEP 1: Drop all existing booking policies
-- ==========================================
DROP POLICY IF EXISTS "bookings_select" ON public.bookings;
DROP POLICY IF EXISTS "bookings_select_public" ON public.bookings;
DROP POLICY IF EXISTS "bookings_insert" ON public.bookings;
DROP POLICY IF EXISTS "bookings_insert_public" ON public.bookings;
DROP POLICY IF EXISTS "bookings_insert_auth" ON public.bookings;
DROP POLICY IF EXISTS "bookings_update" ON public.bookings;
DROP POLICY IF EXISTS "bookings_delete" ON public.bookings;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.bookings;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.bookings;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.bookings;
DROP POLICY IF EXISTS "Allow public to create bookings" ON public.bookings;
DROP POLICY IF EXISTS "Allow authenticated to read bookings" ON public.bookings;
DROP POLICY IF EXISTS "Users can view bookings for their outlets" ON public.bookings;
DROP POLICY IF EXISTS "Users can create bookings" ON public.bookings;
DROP POLICY IF EXISTS "Users can update bookings for their outlets" ON public.bookings;

-- ==========================================
-- STEP 2: Create new policies
-- ==========================================

-- Allow ANYONE (anonymous) to read bookings for slot availability
CREATE POLICY "bookings_select_public" ON public.bookings
  FOR SELECT TO anon
  USING (true);

-- Allow authenticated users to read all bookings (for staff management)
CREATE POLICY "bookings_select_auth" ON public.bookings
  FOR SELECT TO authenticated
  USING (true);

-- Allow ANYONE (anonymous) to create bookings - THIS IS THE KEY FOR PUBLIC BOOKING
CREATE POLICY "bookings_insert_public" ON public.bookings
  FOR INSERT TO anon
  WITH CHECK (true);

-- Allow authenticated users to create bookings too
CREATE POLICY "bookings_insert_auth" ON public.bookings
  FOR INSERT TO authenticated
  WITH CHECK (true);

-- Allow authenticated users to update bookings (confirm, cancel, etc)
CREATE POLICY "bookings_update_auth" ON public.bookings
  FOR UPDATE TO authenticated
  USING (true) WITH CHECK (true);

-- Allow authenticated users to delete bookings
CREATE POLICY "bookings_delete_auth" ON public.bookings
  FOR DELETE TO authenticated
  USING (true);

-- ==========================================
-- STEP 3: Also allow anon to read outlets (to select outlet in form)
-- ==========================================
DROP POLICY IF EXISTS "outlets_select_public" ON public.outlets;
DROP POLICY IF EXISTS "Anyone can view active outlets" ON public.outlets;

-- Allow anyone to read active outlets
CREATE POLICY "outlets_select_public" ON public.outlets
  FOR SELECT TO anon
  USING (is_active = true);

-- ==========================================
-- STEP 4: Ensure RLS is enabled
-- ==========================================
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outlets ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- VERIFY
-- ==========================================
SELECT 'Public Booking RLS Fixed!' as status;

SELECT 
  schemaname,
  tablename, 
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE tablename IN ('bookings', 'outlets')
ORDER BY tablename, policyname;
