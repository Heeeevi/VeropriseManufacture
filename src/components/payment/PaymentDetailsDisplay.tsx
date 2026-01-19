import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { TransactionPayment, PAYMENT_METHOD_LABELS, PAYMENT_METHOD_COLORS } from '@/types/payment';
import { Banknote, Smartphone, CreditCard, ShoppingCart, Receipt } from 'lucide-react';

interface PaymentDetailsDisplayProps {
  payments: TransactionPayment[];
  totalAmount: number;
}

const PAYMENT_METHOD_ICONS: Record<string, any> = {
  cash: Banknote,
  qris: Smartphone,
  transfer: CreditCard,
  olshop: ShoppingCart,
  debit_card: CreditCard,
  credit_card: CreditCard,
  other: Receipt,
};

export function PaymentDetailsDisplay({ payments, totalAmount }: PaymentDetailsDisplayProps) {
  const totalPaid = payments.reduce((sum, p) => sum + p.amount, 0);
  const remaining = totalAmount - totalPaid;

  const paymentSummary = payments.reduce((acc, payment) => {
    const method = payment.payment_method;
    if (!acc[method]) {
      acc[method] = {
        count: 0,
        total: 0,
        payments: [],
      };
    }
    acc[method].count += 1;
    acc[method].total += payment.amount;
    acc[method].payments.push(payment);
    return acc;
  }, {} as Record<string, { count: number; total: number; payments: TransactionPayment[] }>);

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-lg flex items-center justify-between">
          <span>Detail Pembayaran</span>
          <Badge variant={remaining === 0 ? 'default' : remaining < 0 ? 'destructive' : 'secondary'}>
            {payments.length} Metode
          </Badge>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Summary by Method */}
        <div className="space-y-2">
          {Object.entries(paymentSummary).map(([method, data]) => {
            const Icon = PAYMENT_METHOD_ICONS[method] || Receipt;
            const label = PAYMENT_METHOD_LABELS[method as keyof typeof PAYMENT_METHOD_LABELS] || method;
            const colorClass = PAYMENT_METHOD_COLORS[method as keyof typeof PAYMENT_METHOD_COLORS] || 'bg-gray-500';

            return (
              <div key={method} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center gap-3">
                  <div className={`p-2 rounded-lg ${colorClass} bg-opacity-10`}>
                    <Icon className={`h-5 w-5 ${colorClass.replace('bg-', 'text-')}`} />
                  </div>
                  <div>
                    <p className="font-medium">{label}</p>
                    <p className="text-xs text-gray-500">
                      {data.count} transaksi
                    </p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="font-bold">
                    Rp {data.total.toLocaleString('id-ID')}
                  </p>
                </div>
              </div>
            );
          })}
        </div>

        {/* Individual Payments */}
        <div className="border-t pt-4">
          <p className="text-sm font-semibold text-gray-700 mb-2">Rincian Pembayaran</p>
          <div className="space-y-2">
            {payments.map((payment, index) => {
              const Icon = PAYMENT_METHOD_ICONS[payment.payment_method] || Receipt;
              const label = PAYMENT_METHOD_LABELS[payment.payment_method as keyof typeof PAYMENT_METHOD_LABELS] || payment.payment_method;

              return (
                <div key={payment.id || index} className="flex items-start gap-3 p-2 hover:bg-gray-50 rounded">
                  <Icon className="h-4 w-4 mt-1 text-gray-500" />
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-medium">{label}</span>
                      {payment.reference_number && (
                        <Badge variant="outline" className="text-xs">
                          {payment.reference_number}
                        </Badge>
                      )}
                    </div>
                    
                    {payment.card_number_last4 && (
                      <p className="text-xs text-gray-500">
                        •••• {payment.card_number_last4}
                      </p>
                    )}
                    
                    {payment.bank_name && (
                      <p className="text-xs text-gray-500">
                        Bank: {payment.bank_name}
                      </p>
                    )}
                    
                    {payment.notes && (
                      <p className="text-xs text-gray-500 italic">
                        {payment.notes}
                      </p>
                    )}
                    
                    <p className="text-xs text-gray-400 mt-1">
                      {new Date(payment.payment_date).toLocaleString('id-ID')}
                    </p>
                  </div>
                  
                  <div className="text-right">
                    <p className="font-semibold">
                      Rp {payment.amount.toLocaleString('id-ID')}
                    </p>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Total Summary */}
        <div className="border-t pt-4 space-y-2">
          <div className="flex justify-between text-sm">
            <span className="text-gray-600">Total Transaksi</span>
            <span className="font-medium">
              Rp {totalAmount.toLocaleString('id-ID')}
            </span>
          </div>
          
          <div className="flex justify-between text-sm">
            <span className="text-gray-600">Total Dibayar</span>
            <span className={`font-medium ${totalPaid >= totalAmount ? 'text-green-600' : 'text-orange-600'}`}>
              Rp {totalPaid.toLocaleString('id-ID')}
            </span>
          </div>
          
          {remaining !== 0 && (
            <div className="flex justify-between text-base font-bold pt-2 border-t">
              <span className={remaining > 0 ? 'text-red-600' : 'text-green-600'}>
                {remaining > 0 ? 'Kekurangan' : 'Kembalian'}
              </span>
              <span className={remaining > 0 ? 'text-red-600' : 'text-green-600'}>
                Rp {Math.abs(remaining).toLocaleString('id-ID')}
              </span>
            </div>
          )}
          
          {remaining === 0 && (
            <div className="flex items-center justify-center gap-2 p-3 bg-green-50 rounded-lg text-green-700">
              <span className="text-2xl">✓</span>
              <span className="font-semibold">Lunas</span>
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
