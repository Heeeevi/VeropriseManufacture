# 💳 Multi-Payment Quick Reference

## 🚀 Quick Start (3 Langkah)

### 1️⃣ Tambah Item ke Keranjang
- Pilih produk/layanan
- Atur jumlah
- Klik "Tambah"

### 2️⃣ Klik "Bayar" 
- Lihat total transaksi
- Modal pembayaran muncul

### 3️⃣ Pilih Metode Pembayaran
- Pilih 1 atau lebih metode
- Konfirmasi ✓

---

## 💰 Metode Pembayaran

| Icon | Metode | Keterangan | Field Tambahan |
|------|--------|------------|----------------|
| 💵 | **Tunai** | Cash | - |
| 📱 | **QRIS** | QR Payment (Gopay, OVO, Dana) | Nomor Referensi |
| 🏦 | **Transfer** | Transfer Bank | Nomor Ref, Nama Bank |
| 🛒 | **Olshop** | Tokopedia, Shopee, dll | Nomor Referensi |
| 💳 | **Kartu Debit** | Debit Card | 4 Digit Terakhir |
| 💳 | **Kartu Kredit** | Credit Card | 4 Digit Terakhir |

---

## 📋 Scenario Umum

### ✅ Scenario 1: BAYAR PENUH (Single Payment)
```
Total: Rp 50.000
━━━━━━━━━━━━━━━
Payment #1: Cash Rp 50.000
━━━━━━━━━━━━━━━
Total Dibayar: Rp 50.000 ✓
Status: LUNAS
```

### ✅ Scenario 2: DP + PELUNASAN (Multi Payment)
```
Total: Rp 100.000
━━━━━━━━━━━━━━━
Payment #1: Transfer Rp 40.000
  ↳ Ref: TRF-20240117-001
  ↳ Bank: BCA
━━━━━━━━━━━━━━━
[Klik: Tambah Metode Pembayaran]
━━━━━━━━━━━━━━━
Payment #2: Cash Rp 60.000
━━━━━━━━━━━━━━━
Total Dibayar: Rp 100.000 ✓
Status: LUNAS
```

### ✅ Scenario 3: SPLIT PAYMENT (QRIS + Cash)
```
Total: Rp 150.000
━━━━━━━━━━━━━━━
Payment #1: QRIS Rp 100.000
  ↳ Ref: QRIS-456789
━━━━━━━━━━━━━━━
Payment #2: Cash Rp 50.000
━━━━━━━━━━━━━━━
Total Dibayar: Rp 150.000 ✓
Status: LUNAS
```

### ⚠️ Scenario 4: PARTIAL PAYMENT (DP Saja)
```
Total: Rp 200.000
━━━━━━━━━━━━━━━
Payment #1: Transfer Rp 80.000
  ↳ Ref: TRF-123
━━━━━━━━━━━━━━━
Total Dibayar: Rp 80.000
Kekurangan: Rp 120.000 ⚠️
Status: SEBAGIAN
```
> **Note:** Sistem akan warning, tapi tetap bisa simpan untuk DP

### 💡 Scenario 5: OVERPAYMENT (Kembalian)
```
Total: Rp 75.000
━━━━━━━━━━━━━━━
Payment #1: Cash Rp 100.000
━━━━━━━━━━━━━━━
Total Dibayar: Rp 100.000 ⚠️
Kembalian: Rp 25.000 💰
Status: LUNAS
```
> **Note:** Sistem otomatis hitung kembalian

---

## 🎯 Tips & Best Practices

### ✓ DO (Yang Boleh)
- ✅ Gunakan QRIS untuk transaksi online
- ✅ Minta nomor referensi untuk Transfer/QRIS/Olshop
- ✅ Catat 4 digit terakhir kartu
- ✅ Tulis catatan jika perlu (opsional)
- ✅ Double-check total sebelum konfirmasi

### ✗ DON'T (Yang Jangan)
- ❌ Jangan lupa nomor referensi (penting untuk rekonsiliasi)
- ❌ Jangan skip nama bank untuk transfer
- ❌ Jangan konfirmasi kalau total kurang (kecuali memang DP)
- ❌ Jangan hapus semua metode (minimal 1)

---

## 🔧 Troubleshooting

### ❓ "Total pembayaran kurang dari total transaksi"
**Penyebab:** Jumlah yang diinput kurang  
**Solusi:** 
1. Tambah jumlah di metode yang ada, ATAU
2. Tambah metode pembayaran baru

### ❓ "Total pembayaran melebihi Rp..."
**Penyebab:** Customer bayar lebih (normal)  
**Solusi:** 
1. Klik "Lanjutkan"
2. Berikan kembalian sesuai yang tertera

### ❓ Tombol "Konfirmasi" disabled (abu-abu)
**Penyebab:** Total dibayar masih kurang  
**Solusi:** Tambah pembayaran sampai minimal sama dengan total

### ❓ Field "Nomor Referensi" tidak muncul
**Penyebab:** Metode yang dipilih tidak butuh referensi (Cash)  
**Solusi:** Normal, Cash tidak perlu referensi

### ❓ Tidak bisa hapus payment
**Penyebab:** Hanya ada 1 metode  
**Solusi:** Minimal harus ada 1 metode pembayaran

---

## 📱 Shortcuts

| Action | Shortcut | Keterangan |
|--------|----------|------------|
| Tambah metode | Klik tombol "+ Tambah" | Di bawah daftar payment |
| Hapus metode | Klik icon 🗑️ | Di sebelah kanan setiap payment |
| Batalkan | Klik "Batal" | Di pojok kiri bawah modal |
| Konfirmasi | Klik "Konfirmasi" atau Enter | Setelah total pas |

---

## 📞 Bantuan

**Jika Ada Masalah:**
1. Screenshot error message
2. Catat nomor transaksi (jika ada)
3. Hubungi IT Support
4. Jangan tutup aplikasi dulu

**Contact:**
- 📱 WhatsApp: 08XX-XXXX-XXXX
- 💬 Telegram: @veroprise_support
- 📧 Email: support@veroprise.com

---

## 🎓 Training Checklist

Setelah membaca guide ini, coba praktikkan:
- [ ] Single payment (Cash)
- [ ] DP Transfer + Pelunasan Cash
- [ ] Split payment QRIS + Cash
- [ ] Partial payment (DP only)
- [ ] Overpayment dengan kembalian
- [ ] Tambah catatan di payment
- [ ] Input nomor referensi
- [ ] Batalkan transaksi

---

**Printed on:** _________________  
**Staff Name:** _________________  
**Signature:** _________________

---

*Veroprise ERP v2.0 - Multi-Payment System*  
*Last Updated: January 2026*
