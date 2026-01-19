# 🚀 Implementation Guide - Multi-Payment System

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Database Setup](#database-setup)
3. [Frontend Integration](#frontend-integration)
4. [Testing](#testing)
5. [Deployment](#deployment)
6. [Troubleshooting](#troubleshooting)

---

## 1. Prerequisites

### Required
- ✅ Supabase project (new/clean)
- ✅ Node.js 18+ & npm/bun
- ✅ VS Code + TypeScript
- ✅ React 18
- ✅ Shadcn/UI components

### Optional
- 📱 Bluetooth printer (for receipts)
- 🖥️ POS terminal/tablet

---

## 2. Database Setup

### Step 1: Run Base Migrations (If New Project)
```bash
# Connect to Supabase
supabase link --project-ref YOUR_PROJECT_REF

# Run old migrations first
supabase db push migrations/20251221_*.sql
supabase db push migrations/20260104_*.sql
supabase db push migrations/20260112_*.sql
```

### Step 2: Run Multi-Payment Migration
```bash
# This creates transaction_payments table and triggers
supabase db push supabase/migrations/20260117_multi_payment_system.sql
```

### Step 3: Verify Tables
```sql
-- Check if table exists
SELECT * FROM information_schema.tables 
WHERE table_name = 'transaction_payments';

-- Check if trigger exists
SELECT * FROM information_schema.triggers
WHERE trigger_name = 'update_transaction_payment_status';

-- Test trigger manually
INSERT INTO transactions (outlet_id, user_id, total_amount, payment_status)
VALUES ('outlet-id', 'user-id', 100000, 'pending')
RETURNING id;

INSERT INTO transaction_payments (transaction_id, payment_method, amount)
VALUES ('transaction-id-from-above', 'cash', 50000);

-- Should auto-update to 'partial'
SELECT payment_status FROM transactions WHERE id = 'transaction-id-from-above';
```

---

## 3. Frontend Integration

### Step 1: Install Dependencies (if needed)
```bash
cd barberdoc_erp
bun install lucide-react
```

### Step 2: Copy Type Definitions
Already created:
- ✅ `src/types/payment.ts` - Payment interfaces
- ✅ `src/types/warehouse.ts` - Warehouse interfaces
- ✅ `src/types/hr.ts` - HR interfaces

### Step 3: Copy Components
Already created:
- ✅ `src/components/payment/MultiPaymentModal.tsx` - Main modal
- ✅ `src/components/payment/PaymentDetailsDisplay.tsx` - Display component
- ✅ `src/components/payment/PaymentSummaryCard.tsx` - Dashboard card
- ✅ `src/components/payment/POSMultiPaymentExample.tsx` - Example usage

### Step 4: Copy Hooks
Already created:
- ✅ `src/hooks/useMultiPayment.ts` - Payment logic

### Step 5: Integrate into POS Page

**Option A: Update existing POS page** (`src/pages/POS.tsx` or similar)

```tsx
import { useState } from 'react';
import { MultiPaymentModal } from '@/components/payment/MultiPaymentModal';
import { useMultiPayment } from '@/hooks/useMultiPayment';
import { PaymentFormData } from '@/types/payment';

export function POSPage() {
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const { createTransactionWithPayments, isProcessing } = useMultiPayment();
  
  // Your existing cart state
  const [cartItems, setCartItems] = useState([]);
  const totalAmount = cartItems.reduce((sum, item) => sum + item.subtotal, 0);

  const handleCheckout = async (payments: PaymentFormData[]) => {
    try {
      const totalPaid = payments.reduce((sum, p) => sum + p.amount, 0);
      
      await createTransactionWithPayments(
        {
          outlet_id: currentOutlet.id,
          employee_id: currentUser.id,
          total_amount: totalAmount,
          payment_status: totalPaid >= totalAmount ? 'paid' : 'partial',
          items: cartItems.map(item => ({
            product_id: item.product_id,
            quantity: item.quantity,
            price: item.price,
            subtotal: item.subtotal,
          })),
        },
        payments
      );

      alert('Transaksi berhasil!');
      setCartItems([]); // Clear cart
      setShowPaymentModal(false);
    } catch (error) {
      console.error('Checkout failed:', error);
      alert('Gagal memproses transaksi');
    }
  };

  return (
    <div>
      {/* Your existing POS UI */}
      
      <Button onClick={() => setShowPaymentModal(true)}>
        Bayar Rp {totalAmount.toLocaleString('id-ID')}
      </Button>

      <MultiPaymentModal
        open={showPaymentModal}
        onClose={() => setShowPaymentModal(false)}
        totalAmount={totalAmount}
        onConfirm={handleCheckout}
      />
    </div>
  );
}
```

**Option B: Use example component**
```tsx
import { POSMultiPaymentExample } from '@/components/payment/POSMultiPaymentExample';

// In your page
<POSMultiPaymentExample 
  outletId="your-outlet-id" 
  employeeId="your-employee-id"
/>
```

### Step 6: Add to Dashboard

```tsx
import { PaymentSummaryCard } from '@/components/payment/PaymentSummaryCard';
import { useEffect, useState } from 'react';
import { supabase } from '@/integrations/supabase/client';

export function Dashboard() {
  const [paymentSummary, setPaymentSummary] = useState([]);
  
  useEffect(() => {
    fetchPaymentSummary();
  }, []);

  const fetchPaymentSummary = async () => {
    // Fetch today's payments
    const { data } = await supabase
      .from('transaction_payments')
      .select(`
        payment_method,
        amount,
        transaction:transactions(total_amount)
      `)
      .gte('payment_date', new Date().toISOString().split('T')[0]);

    // Group by method
    const summary = data?.reduce((acc, payment) => {
      const method = payment.payment_method;
      if (!acc[method]) {
        acc[method] = { method, count: 0, total: 0 };
      }
      acc[method].count++;
      acc[method].total += payment.amount;
      return acc;
    }, {});

    setPaymentSummary(Object.values(summary || {}));
  };

  return (
    <div className="grid gap-4">
      <PaymentSummaryCard
        summary={paymentSummary}
        totalTransactions={paymentSummary.reduce((sum, p) => sum + p.count, 0)}
        totalAmount={paymentSummary.reduce((sum, p) => sum + p.total, 0)}
        period="Hari Ini"
      />
    </div>
  );
}
```

---

## 4. Testing

### Manual Testing Checklist

#### Test 1: Single Payment (Cash)
```
1. Add items to cart (Total: Rp 50.000)
2. Click "Bayar"
3. Keep default: Cash Rp 50.000
4. Click "Konfirmasi"
5. ✅ Check: Transaction created with payment_status = 'paid'
6. ✅ Check: 1 record in transaction_payments
7. ✅ Check: Inventory deducted
```

#### Test 2: DP Transfer + Pelunasan Cash
```
1. Add items (Total: Rp 100.000)
2. Click "Bayar"
3. Payment #1: Transfer Rp 40.000 (ref: TRF-123, bank: BCA)
4. Click "Tambah Metode"
5. Payment #2: Cash Rp 60.000
6. Click "Konfirmasi"
7. ✅ Check: payment_status = 'paid'
8. ✅ Check: 2 records in transaction_payments
9. ✅ Check: Reference & bank saved correctly
```

#### Test 3: Partial Payment
```
1. Add items (Total: Rp 150.000)
2. Click "Bayar"
3. Payment #1: QRIS Rp 50.000 (ref: QRIS-456)
4. Click "Konfirmasi"
5. ⚠️ Warning appears: "Kekurangan Rp 100.000"
6. Force confirm (for testing)
7. ✅ Check: payment_status = 'partial'
8. ✅ Check: total_paid = 50.000
9. ✅ Check: remaining_amount = 100.000
```

#### Test 4: Overpayment (Kembalian)
```
1. Add items (Total: Rp 75.000)
2. Click "Bayar"
3. Payment #1: Cash Rp 100.000
4. ⚠️ Warning appears: "Kembalian Rp 25.000"
5. Confirm
6. ✅ Check: payment_status = 'paid'
7. ✅ Check: total_paid = 100.000
8. UI shows kembalian correctly
```

#### Test 5: Split 3 Methods
```
1. Add items (Total: Rp 200.000)
2. Payment #1: QRIS Rp 80.000
3. Payment #2: Transfer Rp 70.000
4. Payment #3: Cash Rp 50.000
5. ✅ Check: All 3 methods saved
6. ✅ Check: payment_status = 'paid'
```

### Automated Testing (Optional)
```typescript
// Example with Jest/Vitest
describe('MultiPayment', () => {
  it('should calculate total correctly', () => {
    const payments = [
      { payment_method: 'cash', amount: 50000 },
      { payment_method: 'qris', amount: 30000 },
    ];
    
    const { calculatePaymentSummary } = useMultiPayment();
    const summary = calculatePaymentSummary(payments);
    
    expect(summary.total).toBe(80000);
    expect(summary.byMethod.cash).toBe(50000);
    expect(summary.byMethod.qris).toBe(30000);
  });
});
```

---

## 5. Deployment

### Step 1: Environment Variables
```env
# .env.local
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

### Step 2: Build Frontend
```bash
cd barberdoc_erp
bun run build
```

### Step 3: Deploy to Netlify/Vercel
```bash
# Netlify
netlify deploy --prod

# Vercel
vercel --prod
```

### Step 4: Verify RLS Policies
```sql
-- Check if users can insert payments
SELECT * FROM transaction_payments; -- Should return data

-- Test as non-owner user
SET request.jwt.claims ->> 'sub' = 'other-user-id';
SELECT * FROM transaction_payments; -- Should only see their outlet's data
```

### Step 5: Train Staff
1. Demo multi-payment flow
2. Show common scenarios (DP + pelunasan)
3. Explain reference numbers for QRIS/Transfer
4. Practice partial payments
5. Print training cheat sheet

---

## 6. Troubleshooting

### Issue 1: "transaction_payments table not found"
**Solution:**
```bash
# Re-run migration
supabase db reset
supabase db push
```

### Issue 2: TypeScript errors in `useMultiPayment.ts`
**Cause:** Supabase types not generated yet

**Solution:**
```bash
# Generate types
supabase gen types typescript --local > src/integrations/supabase/types.ts

# Or manually add table to types
```

### Issue 3: Payment status not auto-updating
**Cause:** Trigger not working

**Solution:**
```sql
-- Check if trigger exists
SELECT * FROM pg_trigger WHERE tgname = 'update_transaction_payment_status';

-- Manually test function
SELECT update_transaction_payment_status();

-- Re-create trigger if needed
DROP TRIGGER IF EXISTS update_transaction_payment_status ON transaction_payments;
-- Copy trigger code from migration
```

### Issue 4: "Cannot read property 'amount' of undefined"
**Cause:** Empty payments array

**Solution:**
```typescript
// Add validation in modal
if (payments.length === 0) {
  alert('Tambahkan minimal 1 metode pembayaran');
  return;
}
```

### Issue 5: Inventory not deducting
**Cause:** `update_inventory` function not found

**Solution:**
```sql
-- Check if function exists
SELECT * FROM pg_proc WHERE proname = 'update_inventory';

-- Create if missing (check old migrations)
CREATE OR REPLACE FUNCTION update_inventory(
  p_outlet_id UUID,
  p_product_id UUID,
  p_quantity_change INTEGER
) RETURNS VOID AS $$
BEGIN
  UPDATE outlet_inventory
  SET quantity = quantity + p_quantity_change
  WHERE outlet_id = p_outlet_id AND product_id = p_product_id;
END;
$$ LANGUAGE plpgsql;
```

### Issue 6: Modal not opening
**Cause:** Dialog component not installed

**Solution:**
```bash
bunx shadcn@latest add dialog
bunx shadcn@latest add button
bunx shadcn@latest add input
bunx shadcn@latest add select
```

---

## 📚 Additional Resources

- [Supabase RLS Docs](https://supabase.com/docs/guides/auth/row-level-security)
- [Shadcn/UI Components](https://ui.shadcn.com/)
- [Multi-Payment System README](./README.md)
- [Technical Specs](../../supabase/TECHNICAL_SPECS.md)

---

## 🆘 Support

Jika masih ada masalah:
1. Check browser console untuk error detail
2. Check Supabase logs di dashboard
3. Verify data di Supabase Table Editor
4. Test RLS policies dengan SQL Editor
5. Contact developer team

---

**Built with ❤️ for Veroprise ERP**
*Last updated: January 2026*
