# 💳 Multi-Payment System - Veroprise ERP

## 🎯 Overview

Sistem pembayaran multi-metode untuk POS Veroprise yang memungkinkan pelanggan membayar dengan **beberapa metode pembayaran** dalam satu transaksi.

## ✨ Features

### 1. Multiple Payment Methods
- 💵 **Cash** - Tunai
- 📱 **QRIS** - Scan QR (Gopay, OVO, Dana, dll)
- 🏦 **Transfer** - Transfer bank
- 🛒 **Olshop** - Marketplace (Tokopedia, Shopee, dll)
- 💳 **Debit Card** - Kartu debit
- 💳 **Credit Card** - Kartu kredit
- 📄 **Other** - Metode lainnya

### 2. Payment Scenarios Supported
- ✅ **DP + Pelunasan** - Down payment + final payment
- ✅ **Split Payment** - Bayar dengan 2+ metode sekaligus
- ✅ **Partial Payment** - Bayar sebagian dulu
- ✅ **Overpayment** - Otomatis hitung kembalian

### 3. Rich Metadata
- Reference Number (untuk QRIS/Transfer/Olshop)
- Card Last 4 Digits (untuk kartu)
- Bank Name (untuk transfer)
- Notes per payment

## 📦 Components

### 1. **MultiPaymentModal** (`src/components/payment/MultiPaymentModal.tsx`)
Modal dialog untuk input multi-payment dengan fitur:
- ➕ Add/remove payment methods dynamically
- 📊 Real-time calculation (total paid, remaining)
- ⚠️ Validation warnings
- 🎨 Color-coded payment badges
- 📝 Conditional fields (reference, card number, bank)

**Usage:**
```tsx
import { MultiPaymentModal } from '@/components/payment/MultiPaymentModal';

<MultiPaymentModal
  open={showModal}
  onClose={() => setShowModal(false)}
  totalAmount={65000}
  onConfirm={async (payments) => {
    // Handle payments
    await createTransaction(payments);
  }}
/>
```

### 2. **PaymentDetailsDisplay** (`src/components/payment/PaymentDetailsDisplay.tsx`)
Component untuk menampilkan breakdown pembayaran:
- 💰 Summary per metode pembayaran
- 📋 Detail setiap transaksi pembayaran
- ✓ Status lunas/kurang/lebih
- 🎨 Visual icons & color coding

**Usage:**
```tsx
import { PaymentDetailsDisplay } from '@/components/payment/PaymentDetailsDisplay';

<PaymentDetailsDisplay
  payments={transactionPayments}
  totalAmount={65000}
/>
```

### 3. **useMultiPayment Hook** (`src/hooks/useMultiPayment.ts`)
Custom hook untuk handle payment logic:
- `createTransactionWithPayments()` - Create transaction + items + payments
- `addPaymentToTransaction()` - Add payment to existing transaction
- `getTransactionPayments()` - Fetch all payments for transaction
- `calculatePaymentSummary()` - Calculate totals per method

**Usage:**
```tsx
const { createTransactionWithPayments, isProcessing } = useMultiPayment();

await createTransactionWithPayments(
  {
    outlet_id: 'outlet-123',
    employee_id: 'emp-456',
    total_amount: 65000,
    payment_status: 'paid',
    items: [{ product_id, quantity, price, subtotal }],
  },
  [
    { payment_method: 'transfer', amount: 30000, reference_number: 'TRF-123' },
    { payment_method: 'cash', amount: 35000 },
  ]
);
```

## 🎬 Example Scenarios

### Scenario 1: DP Transfer + Pelunasan Cash
```
Total: Rp 65.000
Payment 1: Transfer Rp 30.000 (ref: TRF-20240117-001)
Payment 2: Cash Rp 35.000
Status: LUNAS ✓
```

### Scenario 2: Split QRIS + Debit Card
```
Total: Rp 150.000
Payment 1: QRIS Rp 100.000 (ref: QRIS-456789)
Payment 2: Debit Card Rp 50.000 (card: ••••1234, Bank: BCA)
Status: LUNAS ✓
```

### Scenario 3: Olshop + Cash (Kembalian)
```
Total: Rp 85.000
Payment 1: Olshop Rp 50.000 (Tokopedia)
Payment 2: Cash Rp 50.000
Status: LUNAS ✓
Kembalian: Rp 15.000
```

### Scenario 4: Partial Payment (DP Only)
```
Total: Rp 200.000
Payment 1: Transfer Rp 80.000 (ref: TRF-123)
Status: PARTIAL 
Kekurangan: Rp 120.000
```

## 🗄️ Database Schema

### Table: `transaction_payments`
```sql
CREATE TABLE transaction_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID NOT NULL REFERENCES transactions(id),
    payment_method VARCHAR(20) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    
    -- Optional metadata
    reference_number VARCHAR(100),
    card_number_last4 VARCHAR(4),
    bank_name VARCHAR(100),
    notes TEXT,
    
    payment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Auto-Update Trigger
Ketika payment ditambahkan/diupdate, `transactions.payment_status` otomatis update:
- **paid** - Total payment >= total_amount
- **partial** - Total payment < total_amount AND > 0
- **pending** - Total payment = 0

## 🧪 Testing Checklist

- [ ] Single payment (cash only) → status: paid
- [ ] DP transfer + pelunasan cash → status: paid
- [ ] QRIS + Debit card split → status: paid
- [ ] Partial payment (DP only) → status: partial
- [ ] Overpayment (calculate kembalian correctly)
- [ ] Reference number saved for QRIS/Transfer/Olshop
- [ ] Card last 4 digits saved for cards
- [ ] Bank name saved for transfer
- [ ] Notes saved per payment
- [ ] Payment date recorded correctly
- [ ] Inventory deducted correctly after payment
- [ ] Cannot pay more than 2x with same method (UI validation)

## 🚀 Deployment Steps

1. Run migration: `20260117_multi_payment_system.sql`
2. Deploy frontend components
3. Test with sample data
4. Train staff on multi-payment flow
5. Monitor `transaction_payments` table

## 📊 Business Impact

### Before (Single Payment Only)
- Customer harus pilih 1 metode
- Jika DP, manual tracking di notes
- Laporan kurang detail per metode
- Rekonsiliasi bank susah

### After (Multi-Payment)
- Customer bebas split payment
- DP otomatis tercatat di database
- Laporan detail per metode pembayaran
- Rekonsiliasi bank mudah dengan reference number
- **Cash deposit calculation** akurat (exclude QRIS/Olshop)

## 🎯 Next Steps

1. **Bluetooth Printer Integration** - Print receipt with payment breakdown
2. **Payment Reminder** - Auto-remind for partial payments
3. **Refund System** - Handle refund per payment method
4. **Payment Analytics** - Dashboard payment method trends
5. **EDC Integration** - Direct integration with EDC machines

## 🆘 Support

Jika ada error atau pertanyaan:
1. Check browser console for errors
2. Check Supabase logs for database errors
3. Verify RLS policies are correct
4. Contact dev team

---

**Built with ❤️ for Veroprise ERP**
