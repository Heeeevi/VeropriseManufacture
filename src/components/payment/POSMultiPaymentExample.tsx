import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { MultiPaymentModal } from './MultiPaymentModal';
import { useMultiPayment } from '@/hooks/useMultiPayment';
import { PaymentFormData } from '@/types/payment';

interface POSMultiPaymentExampleProps {
  outletId: string;
  employeeId?: string;
}

export function POSMultiPaymentExample({ outletId, employeeId }: POSMultiPaymentExampleProps) {
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const { createTransactionWithPayments, isProcessing } = useMultiPayment();

  // Example cart items
  const cartItems = [
    { product_id: 'prod-1', name: 'Haircut', quantity: 1, price: 50000, subtotal: 50000 },
    { product_id: 'prod-2', name: 'Shampoo', quantity: 1, price: 15000, subtotal: 15000 },
  ];

  const totalAmount = cartItems.reduce((sum, item) => sum + item.subtotal, 0);

  const handlePayment = async (payments: PaymentFormData[]) => {
    try {
      const totalPaid = payments.reduce((sum, p) => sum + (Number(p.amount) || 0), 0);
      
      // Determine payment status
      let payment_status: 'paid' | 'partial' | 'pending' = 'paid';
      if (totalPaid < totalAmount) {
        payment_status = 'partial';
      } else if (totalPaid === 0) {
        payment_status = 'pending';
      }

      await createTransactionWithPayments(
        {
          outlet_id: outletId,
          employee_id: employeeId,
          total_amount: totalAmount,
          payment_status,
          items: cartItems,
        },
        payments
      );

      alert('Transaksi berhasil! 🎉');
      setShowPaymentModal(false);
    } catch (error) {
      console.error('Payment failed:', error);
    }
  };

  return (
    <div className="p-6 space-y-4">
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-bold mb-4">Keranjang Belanja</h2>
        
        <div className="space-y-2 mb-4">
          {cartItems.map((item, idx) => (
            <div key={idx} className="flex justify-between text-sm">
              <span>{item.name} x{item.quantity}</span>
              <span className="font-semibold">
                Rp {item.subtotal.toLocaleString('id-ID')}
              </span>
            </div>
          ))}
        </div>

        <div className="border-t pt-3 flex justify-between text-lg font-bold">
          <span>Total</span>
          <span>Rp {totalAmount.toLocaleString('id-ID')}</span>
        </div>

        <Button
          className="w-full mt-4"
          onClick={() => setShowPaymentModal(true)}
          disabled={isProcessing}
        >
          Bayar Sekarang
        </Button>
      </div>

      <MultiPaymentModal
        open={showPaymentModal}
        onClose={() => setShowPaymentModal(false)}
        totalAmount={totalAmount}
        onConfirm={handlePayment}
      />

      {/* Example Scenarios */}
      <div className="bg-blue-50 rounded-lg p-4 space-y-2">
        <h3 className="font-semibold text-blue-900">📋 Contoh Scenario:</h3>
        <div className="text-sm text-blue-800 space-y-1">
          <p><strong>1. DP + Pelunasan:</strong></p>
          <ul className="list-disc list-inside pl-4">
            <li>DP 30rb via Transfer (ref: TRF-123)</li>
            <li>Pelunasan 35rb Cash</li>
          </ul>
          
          <p className="mt-2"><strong>2. Split Payment:</strong></p>
          <ul className="list-disc list-inside pl-4">
            <li>50rb via QRIS (ref: QRIS-456)</li>
            <li>15rb via Debit Card (last4: 1234)</li>
          </ul>

          <p className="mt-2"><strong>3. Olshop + Cash:</strong></p>
          <ul className="list-disc list-inside pl-4">
            <li>40rb via Olshop (Tokopedia)</li>
            <li>25rb Cash</li>
          </ul>
        </div>
      </div>
    </div>
  );
}
