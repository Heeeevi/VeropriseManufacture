import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Banknote, Smartphone, CreditCard, ShoppingCart, TrendingUp } from 'lucide-react';

interface PaymentMethodSummary {
  method: string;
  label: string;
  count: number;
  total: number;
  percentage: number;
}

interface PaymentSummaryCardProps {
  summary: PaymentMethodSummary[];
  totalTransactions: number;
  totalAmount: number;
  period?: string;
}

const PAYMENT_ICONS: Record<string, any> = {
  cash: Banknote,
  qris: Smartphone,
  transfer: CreditCard,
  olshop: ShoppingCart,
  debit_card: CreditCard,
  credit_card: CreditCard,
};

const PAYMENT_COLORS: Record<string, string> = {
  cash: 'text-green-600 bg-green-50',
  qris: 'text-blue-600 bg-blue-50',
  transfer: 'text-purple-600 bg-purple-50',
  olshop: 'text-orange-600 bg-orange-50',
  debit_card: 'text-indigo-600 bg-indigo-50',
  credit_card: 'text-pink-600 bg-pink-50',
};

export function PaymentSummaryCard({ 
  summary, 
  totalTransactions, 
  totalAmount,
  period = 'Hari Ini'
}: PaymentSummaryCardProps) {
  const topMethod = summary.length > 0 ? summary[0] : null;

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-lg flex items-center justify-between">
          <span>Ringkasan Pembayaran</span>
          <Badge variant="outline">{period}</Badge>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Total Stats */}
        <div className="grid grid-cols-2 gap-4">
          <div className="p-4 bg-gradient-to-br from-blue-50 to-blue-100 rounded-lg">
            <p className="text-sm text-blue-700 mb-1">Total Transaksi</p>
            <p className="text-2xl font-bold text-blue-900">
              {totalTransactions}
            </p>
          </div>
          <div className="p-4 bg-gradient-to-br from-green-50 to-green-100 rounded-lg">
            <p className="text-sm text-green-700 mb-1">Total Pendapatan</p>
            <p className="text-2xl font-bold text-green-900">
              Rp {(totalAmount / 1000).toFixed(0)}K
            </p>
          </div>
        </div>

        {/* Top Method */}
        {topMethod && (
          <div className="p-4 bg-gradient-to-r from-indigo-50 to-purple-50 rounded-lg border border-indigo-200">
            <div className="flex items-center gap-3">
              <div className="p-3 bg-indigo-500 rounded-full">
                <TrendingUp className="h-6 w-6 text-white" />
              </div>
              <div className="flex-1">
                <p className="text-sm text-gray-600">Metode Terpopuler</p>
                <p className="text-xl font-bold text-indigo-900">{topMethod.label}</p>
                <p className="text-sm text-indigo-600">
                  {topMethod.count} transaksi · {topMethod.percentage.toFixed(1)}%
                </p>
              </div>
              <div className="text-right">
                <p className="text-lg font-bold text-indigo-900">
                  Rp {(topMethod.total / 1000).toFixed(0)}K
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Method Breakdown */}
        <div className="space-y-2">
          <p className="text-sm font-semibold text-gray-700">Rincian Per Metode</p>
          {summary.map((item) => {
            const Icon = PAYMENT_ICONS[item.method] || Banknote;
            const colorClass = PAYMENT_COLORS[item.method] || 'text-gray-600 bg-gray-50';

            return (
              <div key={item.method} className="flex items-center gap-3 p-3 hover:bg-gray-50 rounded-lg transition-colors">
                <div className={`p-2 rounded-lg ${colorClass}`}>
                  <Icon className="h-5 w-5" />
                </div>
                
                <div className="flex-1">
                  <p className="font-medium text-sm">{item.label}</p>
                  <p className="text-xs text-gray-500">{item.count} transaksi</p>
                </div>

                {/* Progress Bar */}
                <div className="flex-1 max-w-[100px]">
                  <div className="h-2 bg-gray-200 rounded-full overflow-hidden">
                    <div
                      className={`h-full ${colorClass.split(' ')[1]} opacity-60`}
                      style={{ width: `${Math.min(item.percentage, 100)}%` }}
                    />
                  </div>
                  <p className="text-xs text-gray-500 text-center mt-1">
                    {item.percentage.toFixed(0)}%
                  </p>
                </div>

                <div className="text-right">
                  <p className="font-bold text-sm">
                    Rp {(item.total / 1000).toFixed(0)}K
                  </p>
                </div>
              </div>
            );
          })}
        </div>

        {summary.length === 0 && (
          <div className="text-center py-8 text-gray-500">
            <p className="text-sm">Belum ada transaksi {period.toLowerCase()}</p>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
