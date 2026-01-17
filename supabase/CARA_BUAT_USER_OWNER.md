# 📋 CARA MEMBUAT 2 USER OWNER UNTUK 2 OUTLET

## ⚠️ PENTING!
User **TIDAK BISA** dibuat langsung via SQL karena:
- Password harus di-hash dengan bcrypt oleh Supabase Auth
- Tabel `auth.users` adalah sistem internal Supabase
- Foreign key `profiles.user_id` dan `user_roles.user_id` merujuk ke `auth.users.id`

## ✅ CARA YANG BENAR

### STEP 1: Buat User via Supabase Dashboard

1. **Buka Supabase Dashboard**
   - URL: https://supabase.com/dashboard/project/gnqunygpkdelaadvuifn
   - Login dengan akun Supabase Anda

2. **Masuk ke Authentication**
   - Klik menu **"Authentication"** di sidebar kiri
   - Klik submenu **"Users"**

3. **Buat User Pertama (Owner Outlet Hampor)**
   - Klik tombol **"Add User"** (hijau, pojok kanan atas)
   - Pilih **"Create new user"**
   - Isi form:
     ```
     Email: barberdoc@mail.com
     Password: barberdoc123
     ✅ Auto Confirm User: CENTANG (WAJIB!)
     ```
   - Klik **"Create User"**
   - ⚠️ **PENTING**: Setelah user dibuat, **COPY UUID** dari kolom "ID"
     - Contoh UUID: `9153d76c-d15e-4e25-9c21-6e0447d4e77f`

4. **Buat User Kedua (Owner Outlet Malayu)**
   - Klik tombol **"Add User"** lagi
   - Pilih **"Create new user"**
   - Isi form:
     ```
     Email: barberdocmalayu@mail.com
     Password: malayudoc123
     ✅ Auto Confirm User: CENTANG (WAJIB!)
     ```
   - Klik **"Create User"**
   - ⚠️ **PENTING**: Setelah user dibuat, **COPY UUID** dari kolom "ID"
     - Contoh UUID: `8264e87d-e26f-5f36-a32e-7f1558e5f88e`

---

### STEP 2: Insert Profiles, Roles, dan Outlet Assignment

5. **Buka SQL Editor**
   - Klik menu **"SQL Editor"** di sidebar kiri
   - Klik **"New query"**

6. **Copy-Paste SQL Berikut (GANTI UUID DULU!)**

```sql
-- =====================================================
-- INSERT PROFILES, ROLES, DAN OUTLET ASSIGNMENT
-- =====================================================
-- ⚠️ GANTI <UUID_USER_1> dan <UUID_USER_2> dengan UUID yang Anda copy dari Dashboard!

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
-- User 1 -> BarberDoc Hampor (Outlet ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890)
INSERT INTO public.user_outlets (user_id, outlet_id)
VALUES ('<UUID_USER_1>', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890')
ON CONFLICT (user_id, outlet_id) DO NOTHING;

-- User 2 -> BarberDoc Cabang Malayu (Outlet ID: b2c3d4e5-f6a7-8901-bcde-f12345678901)
INSERT INTO public.user_outlets (user_id, outlet_id)
VALUES ('<UUID_USER_2>', 'b2c3d4e5-f6a7-8901-bcde-f12345678901')
ON CONFLICT (user_id, outlet_id) DO NOTHING;

-- ✅ SELESAI!
```

7. **Ganti UUID**
   - Replace `<UUID_USER_1>` dengan UUID user barberdoc@mail.com
   - Replace `<UUID_USER_2>` dengan UUID user barberdocmalayu@mail.com
   - Contoh:
     ```sql
     -- Sebelum:
     ('<UUID_USER_1>', 'BarberDoc Owner Hampor', '6289530078075'),
     
     -- Sesudah:
     ('9153d76c-d15e-4e25-9c21-6e0447d4e77f', 'BarberDoc Owner Hampor', '6289530078075'),
     ```

8. **Jalankan SQL**
   - Klik tombol **"Run"** atau tekan **Ctrl+Enter**
   - Tunggu sampai muncul **"Success. No rows returned"** atau **"Success. Rows affected: X"**

---

## ✅ VERIFIKASI

### Cek User Sudah Dibuat
```sql
-- Cek di tabel auth.users (via dashboard atau query)
SELECT id, email, created_at 
FROM auth.users 
WHERE email IN ('barberdoc@mail.com', 'barberdocmalayu@mail.com');
```

### Cek Profiles Sudah Ada
```sql
SELECT p.user_id, p.full_name, p.phone, u.email
FROM profiles p
JOIN auth.users u ON p.user_id = u.id
WHERE u.email IN ('barberdoc@mail.com', 'barberdocmalayu@mail.com');
```

### Cek Roles Sudah Assigned
```sql
SELECT ur.user_id, ur.role, u.email
FROM user_roles ur
JOIN auth.users u ON ur.user_id = u.id
WHERE u.email IN ('barberdoc@mail.com', 'barberdocmalayu@mail.com');
```

### Cek Outlet Assignment
```sql
SELECT uo.user_id, u.email, o.name AS outlet_name
FROM user_outlets uo
JOIN auth.users u ON uo.user_id = u.id
JOIN outlets o ON uo.outlet_id = o.id
WHERE u.email IN ('barberdoc@mail.com', 'barberdocmalayu@mail.com');
```

---

## 🔐 TEST LOGIN

1. **Buka aplikasi**: http://localhost:8080/auth
2. **Login dengan:**
   - **User 1**: barberdoc@mail.com / barberdoc123
   - **User 2**: barberdocmalayu@mail.com / malayudoc123

3. **Cek:**
   - ✅ Bisa login
   - ✅ Redirect ke dashboard
   - ✅ Outlet sesuai (Hampor atau Malayu)
   - ✅ Role = Owner
   - ✅ Semua menu owner bisa diakses

---

## 🎯 HASIL AKHIR

Setelah semua langkah selesai, Anda akan punya:

| Email | Password | Role | Outlet | Phone |
|-------|----------|------|--------|-------|
| barberdoc@mail.com | barberdoc123 | owner | BarberDoc Hampor | 6289530078075 |
| barberdocmalayu@mail.com | malayudoc123 | owner | BarberDoc Cabang Malayu | 6289530078076 |

---

## ❌ TROUBLESHOOTING

### Error: "Key (user_id)=(...) is not present in table users"
- **Penyebab**: User belum dibuat di Supabase Dashboard
- **Solusi**: Ikuti STEP 1 dulu, buat user via Dashboard

### Error: "User already exists"
- **Penyebab**: Email sudah terdaftar
- **Solusi**: 
  1. Cek di Authentication > Users
  2. Hapus user lama jika perlu
  3. Atau gunakan email berbeda

### User tidak bisa login
- **Penyebab**: Auto Confirm User tidak dicentang
- **Solusi**: 
  1. Buka Authentication > Users
  2. Cari user yang bermasalah
  3. Klik user → lihat detailnya
  4. Pastikan "Email Confirmed" = true
  5. Jika false, klik "Confirm email"

### User bisa login tapi tidak ada role/outlet
- **Penyebab**: STEP 2 belum dijalankan
- **Solusi**: Jalankan SQL di STEP 2 dengan UUID yang benar

---

## 📝 CATATAN

- Password akan di-hash otomatis oleh Supabase Auth
- UUID user adalah primary key di tabel `auth.users`
- UUID outlet harus sesuai dengan yang ada di tabel `outlets`
- Jika wipe database, user akan ikut terhapus (harus dibuat ulang)
- Gunakan `ON CONFLICT DO NOTHING` agar SQL bisa dijalankan berulang kali tanpa error

---

## 🚀 SELESAI!

Setelah setup, Anda bisa:
1. Test login kedua user
2. Test ganti password di menu Settings
3. Mulai input data (produk, inventory, transaksi, dll)
4. Buat user tambahan untuk staff/manager jika perlu

**Happy Coding! ☕️💈**
