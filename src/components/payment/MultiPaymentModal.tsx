import { useState } from 'react';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { Plus, Trash2, CreditCard, Banknote, Smartphone, ShoppingCart, Receipt } from 'lucide-react';
import { PaymentFormData, PaymentMethod, PAYMENT_METHOD_LABELS, PAYMENT_METHOD_COLORS } from '@/types/payment';

interface MultiPaymentModalProps {
  open: boolean;
  onClose: () => void;
  totalAmount: number;
  onConfirm: (payments: PaymentFormData[]) => Promise<void>;
}

const PAYMENT_METHOD_ICONS: Record<PaymentMethod, any> = {
  cash: Banknote,
  qris: Smartphone,
  transfer: CreditCard,
  olshop: ShoppingCart,
  debit_card: CreditCard,
  credit_card: CreditCard,
  other: Receipt,
};

export function MultiPaymentModal({ open, onClose, totalAmount, onConfirm }: MultiPaymentModalProps) {
  const [payments, setPayments] = useState<PaymentFormData[]>([
    { payment_method: 'cash', amount: totalAmount }
  ]);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const totalPaid = payments.reduce((sum, p) => sum + (Number(p.amount) || 0), 0);
  const remaining = totalAmount - totalPaid;

  const addPayment = () => {
    setPayments([...payments, {
      payment_method: 'cash',
      amount: Math.max(0, remaining),
    }]);
  };

  const removePayment = (index: number) => {
    if (payments.length > 1) {
      setPayments(payments.filter((_, i) => i !== index));
    }
  };

  const updatePayment = (index: number, field: keyof PaymentFormData, value: any) => {
    const updated = [...payments];
    updated[index] = { ...updated[index], [field]: value };
    setPayments(updated);
  };

  const handleConfirm = async () => {
    if (remaining > 0) {
      alert('Total pembayaran kurang dari total transaksi!');
      return;
    }

    if (remaining < 0) {
      const confirm = window.confirm(
        `Total pembayaran melebihi Rp ${Math.abs(remaining).toLocaleString('id-ID')}. Lanjutkan?`
      );
      if (!confirm) return;
    }

    setIsSubmitting(true);
    try {
      await onConfirm(payments);
      onClose();
    } catch (error) {
      console.error('Payment error:', error);
      alert('Gagal menyimpan pembayaran');
    } finally {
      setIsSubmitting(false);
    }
  };

  const renderPaymentFields = (payment: PaymentFormData, index: number) => {
    const needsReference = ['qris', 'transfer', 'olshop'].includes(payment.payment_method);
    const needsCard = ['debit_card', 'credit_card'].includes(payment.payment_method);
    const needsBank = payment.payment_method === 'transfer';

    return (
      <div key={index} className="space-y-3">
        <div className="grid grid-cols-12 gap-3 items-start">
          {/* Payment Method */}
          <div className="col-span-5">
            <Label>Metode Pembayaran</Label>
            <Select
              value={payment.payment_method}
              onValueChange={(value) => updatePayment(index, 'payment_method', value as PaymentMethod)}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {Object.entries(PAYMENT_METHOD_LABELS).map(([value, label]) => {
                  const Icon = PAYMENT_METHOD_ICONS[value as PaymentMethod];
                  return (
                    <SelectItem key={value} value={value}>
                      <div className="flex items-center gap-2">
                        <Icon className="h-4 w-4" />
                        {label}
                      </div>
                    </SelectItem>
                  );
                })}
              </SelectContent>
            </Select>
          </div>

          {/* Amount */}
          <div className="col-span-5">
            <Label>Jumlah</Label>
            <Input
              type="number"
              value={payment.amount || ''}
              onChange={(e) => updatePayment(index, 'amount', Number(e.target.value))}
              placeholder="0"
              className="text-right"
            />
          </div>

          {/* Delete Button */}
          <div className="col-span-2 flex items-end">
            <Button
              type="button"
              variant="ghost"
              size="icon"
              onClick={() => removePayment(index)}
              disabled={payments.length === 1}
              className="h-10 w-10"
            >
              <Trash2 className="h-4 w-4" />
            </Button>
          </div>
        </div>

        {/* Additional Fields */}
        {(needsReference || needsCard || needsBank) && (
          <div className="grid grid-cols-2 gap-3 pl-4 border-l-2 border-gray-200">
            {needsReference && (
              <div>
                <Label className="text-xs">Nomor Referensi</Label>
                <Input
                  value={payment.reference_number || ''}
                  onChange={(e) => updatePayment(index, 'reference_number', e.target.value)}
                  placeholder="TRF-123456"
                  className="h-9"
                />
              </div>
            )}

            {needsCard && (
              <div>
                <Label className="text-xs">4 Digit Terakhir Kartu</Label>
                <Input
                  value={payment.card_number_last4 || ''}
                  onChange={(e) => updatePayment(index, 'card_number_last4', e.target.value.slice(0, 4))}
                  placeholder="1234"
                  maxLength={4}
                  className="h-9"
                />
              </div>
            )}

            {needsBank && (
              <div>
                <Label className="text-xs">Nama Bank</Label>
                <Input
                  value={payment.bank_name || ''}
                  onChange={(e) => updatePayment(index, 'bank_name', e.target.value)}
                  placeholder="BCA, Mandiri, BRI"
                  className="h-9"
                />
              </div>
            )}

            <div className="col-span-2">
              <Label className="text-xs">Catatan (Opsional)</Label>
              <Textarea
                value={payment.notes || ''}
                onChange={(e) => updatePayment(index, 'notes', e.target.value)}
                placeholder="Catatan pembayaran..."
                rows={2}
                className="resize-none"
              />
            </div>
          </div>
        )}
      </div>
    );
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="text-xl">Multi-Payment</DialogTitle>
          <DialogDescription>
            Tambahkan beberapa metode pembayaran untuk transaksi ini
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-4">
          {/* Summary */}
          <div className="grid grid-cols-3 gap-4 p-4 bg-gray-50 rounded-lg">
            <div>
              <p className="text-sm text-gray-600">Total Transaksi</p>
              <p className="text-lg font-bold">
                Rp {totalAmount.toLocaleString('id-ID')}
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Total Dibayar</p>
              <p className={`text-lg font-bold ${totalPaid >= totalAmount ? 'text-green-600' : 'text-orange-600'}`}>
                Rp {totalPaid.toLocaleString('id-ID')}
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Sisa</p>
              <p className={`text-lg font-bold ${remaining <= 0 ? 'text-green-600' : 'text-red-600'}`}>
                Rp {remaining.toLocaleString('id-ID')}
              </p>
            </div>
          </div>

          {/* Payment List */}
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <Label className="text-base font-semibold">Metode Pembayaran</Label>
              <Badge variant="outline">
                {payments.length} Metode
              </Badge>
            </div>

            {payments.map((payment, index) => (
              <div key={index} className="p-4 border rounded-lg bg-white">
                <div className="flex items-center gap-2 mb-3">
                  <Badge className={PAYMENT_METHOD_COLORS[payment.payment_method]}>
                    Payment #{index + 1}
                  </Badge>
                </div>
                {renderPaymentFields(payment, index)}
              </div>
            ))}

            {/* Add Payment Button */}
            <Button
              type="button"
              variant="outline"
              onClick={addPayment}
              className="w-full"
              disabled={remaining <= 0}
            >
              <Plus className="h-4 w-4 mr-2" />
              Tambah Metode Pembayaran
            </Button>
          </div>

          {/* Warning */}
          {remaining > 0 && (
            <div className="p-3 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-sm text-red-800">
                ⚠️ Total pembayaran masih kurang <strong>Rp {remaining.toLocaleString('id-ID')}</strong>
              </p>
            </div>
          )}

          {remaining < 0 && (
            <div className="p-3 bg-yellow-50 border border-yellow-200 rounded-lg">
              <p className="text-sm text-yellow-800">
                ⚠️ Total pembayaran melebihi <strong>Rp {Math.abs(remaining).toLocaleString('id-ID')}</strong>. Kembalian akan diberikan.
              </p>
            </div>
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose} disabled={isSubmitting}>
            Batal
          </Button>
          <Button onClick={handleConfirm} disabled={isSubmitting || remaining > 0}>
            {isSubmitting ? 'Memproses...' : 'Konfirmasi Pembayaran'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
