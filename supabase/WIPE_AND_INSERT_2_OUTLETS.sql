-- =====================================================
-- BARBERDOC ERP - WIPE ALL DATA & INSERT 2 OUTLETS
-- =====================================================
-- Script ini akan:
-- 1. Menghapus SEMUA data dari semua tabel
-- 2. Insert 2 outlet: BarberDoc Hampor & BarberDoc Cabang Malayu
-- 3. Insert kategori dan produk default
-- =====================================================

-- STEP 1: WIPE ALL DATA (cascade akan handle foreign keys)
-- =====================================================

-- Delete transaction-related data first
DELETE FROM public.transaction_items;
DELETE FROM public.transactions;

-- Delete booking data
DELETE FROM public.bookings;

-- Delete inventory-related data
DELETE FROM public.inventory_transactions;
DELETE FROM public.product_recipes;
DELETE FROM public.inventory_items;

-- Delete purchase order data
DELETE FROM public.purchase_order_items;
DELETE FROM public.purchase_orders;

-- Delete vendor data
DELETE FROM public.vendors;

-- Delete HR/Payroll data
DELETE FROM public.payroll;
DELETE FROM public.attendance;

-- Delete expenses
DELETE FROM public.expenses;

-- Delete products and categories
DELETE FROM public.products;
DELETE FROM public.categories;

-- Delete shifts
DELETE FROM public.shifts;

-- Delete outlet assignments
DELETE FROM public.user_outlets;

-- Delete outlets (will cascade to related data)
DELETE FROM public.outlets;

-- Delete profiles (will cascade user_outlets)
DELETE FROM public.profiles;

-- Note: auth.users cannot be deleted via SQL, must use Supabase dashboard or Auth API

-- =====================================================
-- STEP 2: INSERT 2 OUTLETS
-- =====================================================

INSERT INTO public.outlets (id, name, address, phone, is_active, created_at, updated_at)
VALUES 
  (
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    'BarberDoc Hampor',
    'Jl. Hampor Raya No. 123, Jakarta',
    '081234567890',
    true,
    NOW(),
    NOW()
  ),
  (
    'b2c3d4e5-f6a7-8901-bcde-f12345678901',
    'BarberDoc Cabang Malayu',
    'Jl. Malayu No. 456, Jakarta',
    '081234567891',
    true,
    NOW(),
    NOW()
  );

-- =====================================================
-- STEP 3: INSERT DEFAULT CATEGORIES
-- =====================================================

INSERT INTO public.categories (id, name, description, icon, sort_order, created_at, updated_at)
VALUES
  ('cat-haircut', 'Haircut', 'Potong rambut pria', '✂️', 1, NOW(), NOW()),
  ('cat-shaving', 'Shaving', 'Cukur dan perawatan jenggot', '🪒', 2, NOW(), NOW()),
  ('cat-treatment', 'Treatment', 'Perawatan rambut dan kulit kepala', '💆', 3, NOW(), NOW()),
  ('cat-coloring', 'Coloring', 'Pewarnaan rambut', '🎨', 4, NOW(), NOW());

-- =====================================================
-- STEP 4: INSERT DEFAULT PRODUCTS/SERVICES
-- =====================================================

-- Haircut Services
INSERT INTO public.products (category_id, name, description, price, cost_price, is_active)
VALUES
  ('cat-haircut', 'Potong Rambut Dewasa', 'Potong rambut pria dewasa standar', 50000, 10000, true),
  ('cat-haircut', 'Potong Rambut Anak', 'Potong rambut anak-anak (0-12 tahun)', 35000, 8000, true),
  ('cat-haircut', 'Premium Cut & Style', 'Potong rambut + styling premium', 80000, 15000, true);

-- Shaving Services
INSERT INTO public.products (category_id, name, description, price, cost_price, is_active)
VALUES
  ('cat-shaving', 'Cukur Jenggot', 'Cukur dan rapikan jenggot', 30000, 5000, true),
  ('cat-shaving', 'Cukur Kumis', 'Cukur dan rapikan kumis', 20000, 3000, true),
  ('cat-shaving', 'Full Shaving', 'Cukur jenggot + kumis + rapikan', 45000, 8000, true);

-- Treatment Services
INSERT INTO public.products (category_id, name, description, price, cost_price, is_active)
VALUES
  ('cat-treatment', 'Hair Spa', 'Perawatan spa untuk rambut', 100000, 25000, true),
  ('cat-treatment', 'Creambath', 'Perawatan creambath rambut', 75000, 20000, true),
  ('cat-treatment', 'Scalp Treatment', 'Perawatan kulit kepala', 90000, 22000, true);

-- Coloring Services
INSERT INTO public.products (category_id, name, description, price, cost_price, is_active)
VALUES
  ('cat-coloring', 'Hair Color Basic', 'Pewarnaan rambut warna dasar', 150000, 40000, true),
  ('cat-coloring', 'Hair Color Premium', 'Pewarnaan rambut warna premium', 250000, 70000, true),
  ('cat-coloring', 'Bleaching', 'Bleaching rambut', 200000, 50000, true);

-- =====================================================
-- STEP 5: INSERT SAMPLE INVENTORY ITEMS (Optional)
-- =====================================================

-- Inventory untuk Outlet Hampor
INSERT INTO public.inventory_items (outlet_id, name, unit, quantity, min_stock, cost_per_unit)
VALUES
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Gunting Rambut', 'pcs', 5, 2, 50000),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Sisir', 'pcs', 10, 3, 15000),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Pomade', 'botol', 20, 5, 35000),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Shampoo', 'botol', 15, 5, 45000),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Hair Tonic', 'botol', 12, 4, 55000);

-- Inventory untuk Outlet Malayu
INSERT INTO public.inventory_items (outlet_id, name, unit, quantity, min_stock, cost_per_unit)
VALUES
  ('b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Gunting Rambut', 'pcs', 5, 2, 50000),
  ('b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Sisir', 'pcs', 10, 3, 15000),
  ('b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Pomade', 'botol', 20, 5, 35000),
  ('b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Shampoo', 'botol', 15, 5, 45000),
  ('b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Hair Tonic', 'botol', 12, 4, 55000);

-- =====================================================
-- DONE!
-- =====================================================

-- Hasil:
-- ✅ Semua data lama terhapus
-- ✅ 2 Outlet: BarberDoc Hampor & BarberDoc Cabang Malayu
-- ✅ 4 Kategori produk
-- ✅ 12 Produk/layanan default
-- ✅ 10 Item inventory (5 per outlet)
--
-- Next Steps:
-- 1. Buat user baru via Supabase Auth
-- 2. Assign user ke outlet via user_outlets table
-- 3. Mulai menggunakan sistem
