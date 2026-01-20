-- =====================================================
-- VEROPRISE ERP - SEED DATA
-- Version: 1.0 - Sample Data for Development
-- Description: Demo data for testing all ERP features
-- =====================================================

-- =====================================================
-- CATEGORIES
-- =====================================================

INSERT INTO categories (id, name, description, icon, color, sort_order) VALUES
    ('c1000001-0000-0000-0000-000000000001', 'Produk Rambut', 'Shampoo, conditioner, pomade, dll', 'Package', '#3B82F6', 1),
    ('c1000001-0000-0000-0000-000000000002', 'Peralatan Cukur', 'Gunting, sisir, pisau cukur', 'Scissors', '#10B981', 2),
    ('c1000001-0000-0000-0000-000000000003', 'Skincare', 'Produk perawatan wajah', 'Sparkles', '#F59E0B', 3),
    ('c1000001-0000-0000-0000-000000000004', 'Aksesoris', 'Aksesoris dan perlengkapan', 'Star', '#8B5CF6', 4),
    ('c1000001-0000-0000-0000-000000000005', 'Jasa Potong', 'Layanan potong rambut', 'Scissors', '#EF4444', 5),
    ('c1000001-0000-0000-0000-000000000006', 'Jasa Treatment', 'Layanan treatment rambut', 'Heart', '#EC4899', 6)
ON CONFLICT DO NOTHING;

-- =====================================================
-- WAREHOUSES (Gudang Pusat & Regional)
-- =====================================================

INSERT INTO warehouses (id, code, name, address, phone, warehouse_type, is_active) VALUES
    ('w1000001-0000-0000-0000-000000000001', 'GD-PUSAT', 'Gudang Pusat Jakarta', 'Jl. Industri Raya No. 100, Jakarta Utara', '021-5551234', 'central', true),
    ('w1000001-0000-0000-0000-000000000002', 'GD-JKT-S', 'Gudang Regional Jakarta Selatan', 'Jl. TB Simatupang No. 50', '021-5552345', 'regional', true),
    ('w1000001-0000-0000-0000-000000000003', 'GD-BDG', 'Gudang Regional Bandung', 'Jl. Soekarno Hatta No. 200, Bandung', '022-5553456', 'regional', true)
ON CONFLICT DO NOTHING;

-- =====================================================
-- SUPPLIERS (Partner Vendors)
-- =====================================================

INSERT INTO suppliers (id, code, name, contact_person, phone, email, address, payment_terms, is_active) VALUES
    ('s1000001-0000-0000-0000-000000000001', 'SUP-001', 'PT Produk Rambut Indonesia', 'Budi Santoso', '021-6661234', 'supplier1@produkrambut.com', 'Jl. Raya Industri No. 10, Tangerang', 30, true),
    ('s1000001-0000-0000-0000-000000000002', 'SUP-002', 'CV Alat Cukur Jaya', 'Ahmad Wijaya', '021-6662345', 'sales@alatcukurjaya.com', 'Jl. Mangga Dua Raya No. 55', 14, true),
    ('s1000001-0000-0000-0000-000000000003', 'SUP-003', 'PT Skincare Nusantara', 'Dewi Lestari', '021-6663456', 'order@skincarenusantara.com', 'Jl. Gatot Subroto No. 88, Jakarta', 21, true)
ON CONFLICT DO NOTHING;

-- =====================================================
-- OUTLETS (Toko/Cabang)
-- =====================================================

INSERT INTO outlets (id, name, address, phone, email, status, is_active, opening_time, closing_time) VALUES
    ('o1000001-0000-0000-0000-000000000001', 'Barbershop Pusat - Sudirman', 'Jl. Jend. Sudirman No. 123, Jakarta Pusat', '021-5551001', 'sudirman@barbershop.com', 'active', true, '09:00', '21:00'),
    ('o1000001-0000-0000-0000-000000000002', 'Barbershop Kemang', 'Jl. Kemang Raya No. 45, Jakarta Selatan', '021-5552002', 'kemang@barbershop.com', 'active', true, '09:00', '21:00'),
    ('o1000001-0000-0000-0000-000000000003', 'Barbershop Bandung', 'Jl. Asia Afrika No. 88, Bandung', '022-5553003', 'bandung@barbershop.com', 'active', true, '09:00', '21:00')
ON CONFLICT DO NOTHING;

-- =====================================================
-- PRODUCTS (Barang & Jasa)
-- =====================================================

INSERT INTO products (id, outlet_id, category_id, name, description, price, cost, sku, is_active, is_service, stock_quantity, min_stock, reorder_point) VALUES
    -- Produk Rambut
    ('p1000001-0000-0000-0000-000000000001', 'o1000001-0000-0000-0000-000000000001', 'c1000001-0000-0000-0000-000000000001', 'Pomade Premium', 'Pomade water-based premium 100g', 85000, 45000, 'POM-001', true, false, 50, 10, 15),
    ('p1000001-0000-0000-0000-000000000002', 'o1000001-0000-0000-0000-000000000001', 'c1000001-0000-0000-0000-000000000001', 'Hair Tonic Growth', 'Hair tonic untuk pertumbuhan rambut 200ml', 125000, 65000, 'TON-001', true, false, 30, 5, 10),
    ('p1000001-0000-0000-0000-000000000003', 'o1000001-0000-0000-0000-000000000001', 'c1000001-0000-0000-0000-000000000001', 'Shampoo Anti Ketombe', 'Shampoo khusus anti ketombe 250ml', 65000, 35000, 'SHP-001', true, false, 40, 10, 15),
    ('p1000001-0000-0000-0000-000000000004', 'o1000001-0000-0000-0000-000000000001', 'c1000001-0000-0000-0000-000000000001', 'Hair Wax Matte', 'Hair wax efek matte natural 80g', 75000, 40000, 'WAX-001', true, false, 35, 8, 12),
    
    -- Peralatan Cukur
    ('p1000001-0000-0000-0000-000000000005', 'o1000001-0000-0000-0000-000000000001', 'c1000001-0000-0000-0000-000000000002', 'Sisir Profesional', 'Sisir carbon fiber anti static', 45000, 22000, 'CMB-001', true, false, 25, 5, 8),
    ('p1000001-0000-0000-0000-000000000006', 'o1000001-0000-0000-0000-000000000001', 'c1000001-0000-0000-0000-000000000002', 'Pisau Cukur Classic', 'Pisau cukur stainless steel', 150000, 85000, 'RZR-001', true, false, 15, 3, 5),
    
    -- Skincare
    ('p1000001-0000-0000-0000-000000000007', 'o1000001-0000-0000-0000-000000000001', 'c1000001-0000-0000-0000-000000000003', 'Face Wash Men', 'Sabun muka khusus pria 100ml', 55000, 28000, 'FCW-001', true, false, 60, 15, 20),
    ('p1000001-0000-0000-0000-000000000008', 'o1000001-0000-0000-0000-000000000001', 'c1000001-0000-0000-0000-000000000003', 'Aftershave Balm', 'Aftershave cooling balm 50ml', 95000, 50000, 'AFT-001', true, false, 25, 5, 8),
    
    -- Jasa Potong
    ('p1000001-0000-0000-0000-000000000009', 'o1000001-0000-0000-0000-000000000001', 'c1000001-0000-0000-0000-000000000005', 'Potong Rambut Basic', 'Potong rambut standar', 50000, 0, 'SVC-CUT-01', true, true, 0, 0, 0),
    ('p1000001-0000-0000-0000-000000000010', 'o1000001-0000-0000-0000-000000000001', 'c1000001-0000-0000-0000-000000000005', 'Potong Rambut Premium', 'Potong rambut + styling', 85000, 0, 'SVC-CUT-02', true, true, 0, 0, 0),
    ('p1000001-0000-0000-0000-000000000011', 'o1000001-0000-0000-0000-000000000001', 'c1000001-0000-0000-0000-000000000005', 'Cukur Jenggot', 'Cukur dan trim jenggot', 35000, 0, 'SVC-SHV-01', true, true, 0, 0, 0),
    
    -- Jasa Treatment
    ('p1000001-0000-0000-0000-000000000012', 'o1000001-0000-0000-0000-000000000001', 'c1000001-0000-0000-0000-000000000006', 'Hair Spa', 'Perawatan rambut lengkap 45 menit', 150000, 0, 'SVC-SPA-01', true, true, 0, 0, 0),
    ('p1000001-0000-0000-0000-000000000013', 'o1000001-0000-0000-0000-000000000001', 'c1000001-0000-0000-0000-000000000006', 'Creambath', 'Creambath relaxing 30 menit', 100000, 0, 'SVC-CBT-01', true, true, 0, 0, 0),
    ('p1000001-0000-0000-0000-000000000014', 'o1000001-0000-0000-0000-000000000001', 'c1000001-0000-0000-0000-000000000006', 'Coloring Basic', 'Pewarnaan rambut satu warna', 200000, 0, 'SVC-CLR-01', true, true, 0, 0, 0)
ON CONFLICT DO NOTHING;

-- =====================================================
-- WAREHOUSE INVENTORY (Stok di Gudang Pusat)
-- =====================================================

INSERT INTO warehouse_inventory (warehouse_id, product_id, quantity, min_stock, max_stock, cost_per_unit) VALUES
    ('w1000001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000001', 500, 100, 1000, 45000),
    ('w1000001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000002', 300, 50, 600, 65000),
    ('w1000001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000003', 400, 80, 800, 35000),
    ('w1000001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000004', 350, 70, 700, 40000),
    ('w1000001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000005', 200, 50, 400, 22000),
    ('w1000001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000006', 100, 20, 200, 85000),
    ('w1000001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000007', 500, 100, 1000, 28000),
    ('w1000001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000008', 250, 50, 500, 50000)
ON CONFLICT DO NOTHING;

-- =====================================================
-- OUTLET INVENTORY (Stok di Toko)
-- =====================================================

INSERT INTO inventory (outlet_id, product_id, quantity, min_quantity, max_quantity, unit) VALUES
    ('o1000001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000001', 50, 10, 100, 'pcs'),
    ('o1000001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000002', 30, 5, 60, 'pcs'),
    ('o1000001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000003', 40, 10, 80, 'pcs'),
    ('o1000001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000004', 35, 8, 70, 'pcs'),
    ('o1000001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000005', 25, 5, 50, 'pcs'),
    ('o1000001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000006', 15, 3, 30, 'pcs'),
    ('o1000001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000007', 60, 15, 120, 'pcs'),
    ('o1000001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000008', 25, 5, 50, 'pcs'),
    -- Kemang outlet
    ('o1000001-0000-0000-0000-000000000002', 'p1000001-0000-0000-0000-000000000001', 40, 10, 80, 'pcs'),
    ('o1000001-0000-0000-0000-000000000002', 'p1000001-0000-0000-0000-000000000002', 25, 5, 50, 'pcs'),
    ('o1000001-0000-0000-0000-000000000002', 'p1000001-0000-0000-0000-000000000003', 35, 8, 70, 'pcs')
ON CONFLICT DO NOTHING;

-- =====================================================
-- EMPLOYEES (Karyawan)
-- =====================================================

INSERT INTO employees (id, outlet_id, employee_code, full_name, phone, position, hire_date, basic_salary, is_active) VALUES
    ('e1000001-0000-0000-0000-000000000001', 'o1000001-0000-0000-0000-000000000001', 'EMP-001', 'Rizki Pratama', '081234567001', 'Senior Barber', '2023-01-15', 5000000, true),
    ('e1000001-0000-0000-0000-000000000002', 'o1000001-0000-0000-0000-000000000001', 'EMP-002', 'Dimas Saputra', '081234567002', 'Barber', '2023-03-01', 4000000, true),
    ('e1000001-0000-0000-0000-000000000003', 'o1000001-0000-0000-0000-000000000001', 'EMP-003', 'Yoga Setiawan', '081234567003', 'Junior Barber', '2023-06-15', 3500000, true),
    ('e1000001-0000-0000-0000-000000000004', 'o1000001-0000-0000-0000-000000000001', 'EMP-004', 'Andi Nugroho', '081234567004', 'Kasir', '2023-02-01', 4000000, true),
    ('e1000001-0000-0000-0000-000000000005', 'o1000001-0000-0000-0000-000000000002', 'EMP-005', 'Bayu Kurniawan', '081234567005', 'Senior Barber', '2022-08-01', 5500000, true),
    ('e1000001-0000-0000-0000-000000000006', 'o1000001-0000-0000-0000-000000000002', 'EMP-006', 'Fajar Hidayat', '081234567006', 'Barber', '2023-04-15', 4000000, true)
ON CONFLICT DO NOTHING;

-- =====================================================
-- SHIFTS (Jadwal Kerja)
-- =====================================================

INSERT INTO shifts (outlet_id, employee_id, shift_date, shift_type, start_time, end_time) VALUES
    ('o1000001-0000-0000-0000-000000000001', 'e1000001-0000-0000-0000-000000000001', CURRENT_DATE, 'full_day', '09:00', '21:00'),
    ('o1000001-0000-0000-0000-000000000001', 'e1000001-0000-0000-0000-000000000002', CURRENT_DATE, 'opening', '09:00', '15:00'),
    ('o1000001-0000-0000-0000-000000000001', 'e1000001-0000-0000-0000-000000000003', CURRENT_DATE, 'closing', '15:00', '21:00'),
    ('o1000001-0000-0000-0000-000000000001', 'e1000001-0000-0000-0000-000000000004', CURRENT_DATE, 'full_day', '09:00', '21:00')
ON CONFLICT DO NOTHING;

-- =====================================================
-- SAMPLE PURCHASE ORDER (Supplier → Gudang)
-- =====================================================

INSERT INTO purchase_orders (id, po_number, warehouse_id, supplier_id, supplier_name, status, total_amount, ordered_date) VALUES
    ('po100001-0000-0000-0000-000000000001', 'PO-2024-0001', 'w1000001-0000-0000-0000-000000000001', 's1000001-0000-0000-0000-000000000001', 'PT Produk Rambut Indonesia', 'received', 9000000, CURRENT_DATE - INTERVAL '7 days')
ON CONFLICT DO NOTHING;

INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price, subtotal, received_quantity) VALUES
    ('po100001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000001', 100, 45000, 4500000, 100),
    ('po100001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000002', 50, 65000, 3250000, 50),
    ('po100001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000003', 50, 25000, 1250000, 50)
ON CONFLICT DO NOTHING;

-- =====================================================
-- SAMPLE STOCK TRANSFER (Gudang → Toko)
-- =====================================================

INSERT INTO stock_transfer_orders (id, transfer_number, from_warehouse_id, to_outlet_id, status, requested_date) VALUES
    ('st100001-0000-0000-0000-000000000001', 'ST-2024-0001', 'w1000001-0000-0000-0000-000000000001', 'o1000001-0000-0000-0000-000000000001', 'received', CURRENT_DATE - INTERVAL '3 days')
ON CONFLICT DO NOTHING;

INSERT INTO stock_transfer_items (stock_transfer_order_id, product_id, quantity_requested, quantity_sent, quantity_received, unit_cost) VALUES
    ('st100001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000001', 25, 25, 25, 45000),
    ('st100001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000002', 15, 15, 15, 65000)
ON CONFLICT DO NOTHING;

-- =====================================================
-- SAMPLE STOCK OPNAME (Audit Stok)
-- =====================================================

INSERT INTO stock_opname (id, opname_number, outlet_id, opname_date, status) VALUES
    ('so100001-0000-0000-0000-000000000001', 'SO-2024-0001', 'o1000001-0000-0000-0000-000000000001', CURRENT_DATE - INTERVAL '30 days', 'approved')
ON CONFLICT DO NOTHING;

INSERT INTO stock_opname_items (stock_opname_id, product_id, system_quantity, physical_quantity, unit_cost) VALUES
    ('so100001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000001', 48, 50, 45000),
    ('so100001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000002', 32, 30, 65000)
ON CONFLICT DO NOTHING;

-- =====================================================
-- SAMPLE TRANSACTIONS (Multi-Payment)
-- =====================================================

-- Transaction 1: Single payment - Cash
INSERT INTO transactions (id, outlet_id, employee_id, transaction_number, transaction_date, subtotal, tax, total, status, payment_method, payment_status, is_split_payment) VALUES
    ('tx100001-0000-0000-0000-000000000001', 'o1000001-0000-0000-0000-000000000001', 'e1000001-0000-0000-0000-000000000001', 'TRX-20240115-001', NOW() - INTERVAL '2 days', 135000, 0, 135000, 'completed', 'cash', 'paid', false)
ON CONFLICT DO NOTHING;

INSERT INTO transaction_items (transaction_id, product_id, product_name, quantity, unit_price, subtotal) VALUES
    ('tx100001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000010', 'Potong Rambut Premium', 1, 85000, 85000),
    ('tx100001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000011', 'Cukur Jenggot', 1, 35000, 35000),
    ('tx100001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000001', 'Pomade Premium', 1, 85000, -70000)
ON CONFLICT DO NOTHING;

-- Transaction 2: Split payment - Transfer (DP) + Cash (Pelunasan)
INSERT INTO transactions (id, outlet_id, employee_id, transaction_number, transaction_date, subtotal, tax, total, status, payment_method, payment_status, is_split_payment, payment_details) VALUES
    ('tx100001-0000-0000-0000-000000000002', 'o1000001-0000-0000-0000-000000000001', 'e1000001-0000-0000-0000-000000000002', 'TRX-20240115-002', NOW() - INTERVAL '1 day', 350000, 0, 350000, 'completed', 'cash', 'paid', true, '[{"method": "transfer", "amount": 150000}, {"method": "cash", "amount": 200000}]')
ON CONFLICT DO NOTHING;

INSERT INTO transaction_items (transaction_id, product_id, product_name, quantity, unit_price, subtotal) VALUES
    ('tx100001-0000-0000-0000-000000000002', 'p1000001-0000-0000-0000-000000000012', 'Hair Spa', 1, 150000, 150000),
    ('tx100001-0000-0000-0000-000000000002', 'p1000001-0000-0000-0000-000000000014', 'Coloring Basic', 1, 200000, 200000)
ON CONFLICT DO NOTHING;

-- Transaction 3: QRIS payment
INSERT INTO transactions (id, outlet_id, employee_id, transaction_number, transaction_date, subtotal, tax, total, status, payment_method, payment_status, is_split_payment) VALUES
    ('tx100001-0000-0000-0000-000000000003', 'o1000001-0000-0000-0000-000000000001', 'e1000001-0000-0000-0000-000000000003', 'TRX-20240115-003', NOW(), 85000, 0, 85000, 'completed', 'qris', 'paid', false)
ON CONFLICT DO NOTHING;

INSERT INTO transaction_items (transaction_id, product_id, product_name, quantity, unit_price, subtotal) VALUES
    ('tx100001-0000-0000-0000-000000000003', 'p1000001-0000-0000-0000-000000000010', 'Potong Rambut Premium', 1, 85000, 85000)
ON CONFLICT DO NOTHING;

-- Transaction 4: Olshop payment
INSERT INTO transactions (id, outlet_id, employee_id, transaction_number, transaction_date, subtotal, tax, total, status, payment_method, payment_status, is_split_payment) VALUES
    ('tx100001-0000-0000-0000-000000000004', 'o1000001-0000-0000-0000-000000000001', 'e1000001-0000-0000-0000-000000000004', 'TRX-20240115-004', NOW(), 340000, 0, 340000, 'completed', 'olshop', 'paid', false)
ON CONFLICT DO NOTHING;

INSERT INTO transaction_items (transaction_id, product_id, product_name, quantity, unit_price, subtotal) VALUES
    ('tx100001-0000-0000-0000-000000000004', 'p1000001-0000-0000-0000-000000000001', 'Pomade Premium', 2, 85000, 170000),
    ('tx100001-0000-0000-0000-000000000004', 'p1000001-0000-0000-0000-000000000002', 'Hair Tonic Growth', 1, 125000, 125000),
    ('tx100001-0000-0000-0000-000000000004', 'p1000001-0000-0000-0000-000000000005', 'Sisir Profesional', 1, 45000, 45000)
ON CONFLICT DO NOTHING;

-- =====================================================
-- SAMPLE EXPENSES
-- =====================================================

INSERT INTO expenses (id, outlet_id, category, amount, description, expense_date, status) VALUES
    ('ex100001-0000-0000-0000-000000000001', 'o1000001-0000-0000-0000-000000000001', 'supplies', 150000, 'Pembelian handuk baru', CURRENT_DATE, 'approved'),
    ('ex100001-0000-0000-0000-000000000002', 'o1000001-0000-0000-0000-000000000001', 'operational', 85000, 'Biaya listrik harian', CURRENT_DATE, 'approved'),
    ('ex100001-0000-0000-0000-000000000003', 'o1000001-0000-0000-0000-000000000001', 'utilities', 50000, 'Air minum galon', CURRENT_DATE, 'approved')
ON CONFLICT DO NOTHING;

-- =====================================================
-- SAMPLE ATTENDANCES (Absensi)
-- =====================================================

INSERT INTO attendances (employee_id, outlet_id, attendance_date, status, check_in, check_out, hours_worked) VALUES
    ('e1000001-0000-0000-0000-000000000001', 'o1000001-0000-0000-0000-000000000001', CURRENT_DATE, 'present', NOW() - INTERVAL '8 hours', NOW(), 8),
    ('e1000001-0000-0000-0000-000000000002', 'o1000001-0000-0000-0000-000000000001', CURRENT_DATE, 'present', NOW() - INTERVAL '6 hours', NOW(), 6),
    ('e1000001-0000-0000-0000-000000000003', 'o1000001-0000-0000-0000-000000000001', CURRENT_DATE, 'late', NOW() - INTERVAL '5 hours', NULL, 5),
    ('e1000001-0000-0000-0000-000000000004', 'o1000001-0000-0000-0000-000000000001', CURRENT_DATE, 'present', NOW() - INTERVAL '8 hours', NOW(), 8)
ON CONFLICT DO NOTHING;

-- =====================================================
-- SAMPLE SALES TARGETS
-- =====================================================

INSERT INTO sales_targets (id, outlet_id, product_id, target_name, target_type, target_period, start_date, end_date, target_date, target_amount, target_quantity, incentive_type, fixed_amount, is_active) VALUES
    ('st100001-0000-0000-0000-000000000001', 'o1000001-0000-0000-0000-000000000001', 'p1000001-0000-0000-0000-000000000001', 'Target Penjualan Pomade Harian', 'product_quantity', 'daily', CURRENT_DATE, CURRENT_DATE, CURRENT_DATE, 0, 10, 'fixed', 50000, true),
    ('st100001-0000-0000-0000-000000000002', 'o1000001-0000-0000-0000-000000000001', NULL, 'Target Omset Bulanan', 'total_sales', 'monthly', DATE_TRUNC('month', CURRENT_DATE)::DATE, (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day')::DATE, CURRENT_DATE, 50000000, NULL, 'tiered', 0, true)
ON CONFLICT DO NOTHING;

-- =====================================================
-- SAMPLE EMPLOYEE BONUSES
-- =====================================================

INSERT INTO employee_bonuses (employee_id, bonus_type, amount, description, achievement_date) VALUES
    ('e1000001-0000-0000-0000-000000000001', 'performance', 500000, 'Bonus kinerja bulan Desember 2023', CURRENT_DATE - INTERVAL '30 days'),
    ('e1000001-0000-0000-0000-000000000002', 'target_achievement', 300000, 'Mencapai target penjualan pomade 100 unit', CURRENT_DATE - INTERVAL '15 days')
ON CONFLICT DO NOTHING;

-- =====================================================
-- END OF SEED DATA
-- =====================================================
