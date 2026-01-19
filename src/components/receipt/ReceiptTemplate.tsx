import { forwardRef } from 'react';
import { formatCurrency, formatDateTime } from '@/lib/utils';

export interface ReceiptItem {
  name: string;
  quantity: number;
  unitPrice: number;
  subtotal: number;
}

export interface ReceiptPayment {
  method: string;
  amount: number;
  reference?: string;
}

export interface ReceiptData {
  transactionNumber: string;
  transactionDate: Date | string;
  outlet: {
    name: string;
    address: string;
    phone: string;
  };
  items: ReceiptItem[];
  subtotal: number;
  tax: number;
  taxRate: number;
  discount: number;
  total: number;
  payments: ReceiptPayment[];
  cashReceived?: number;
  change?: number;
  cashierName?: string;
  receiptHeader?: string;
  receiptFooter?: string;
}

interface ReceiptTemplateProps {
  data: ReceiptData;
  paperWidth?: 58 | 80;
}

// Payment method labels in Indonesian
const paymentMethodLabels: Record<string, string> = {
  cash: 'Tunai',
  qris: 'QRIS',
  transfer: 'Transfer Bank',
  olshop: 'Olshop',
  debit_card: 'Kartu Debit',
  credit_card: 'Kartu Kredit',
  other: 'Lainnya',
};

/**
 * ReceiptTemplate - A printable thermal receipt template
 * Supports 58mm (default) and 80mm paper width
 */
export const ReceiptTemplate = forwardRef<HTMLDivElement, ReceiptTemplateProps>(
  ({ data, paperWidth = 58 }, ref) => {
    const width = paperWidth === 80 ? '80mm' : '58mm';
    const charPerLine = paperWidth === 80 ? 48 : 32;

    const formatPaymentMethod = (method: string) => {
      return paymentMethodLabels[method] || method;
    };

    const renderDivider = () => (
      <div className="border-t border-dashed border-gray-400 my-2" />
    );

    return (
      <div
        ref={ref}
        className="bg-white text-black font-mono text-xs p-3"
        style={{
          width,
          minWidth: width,
          maxWidth: width,
          fontFamily: "'Courier New', Courier, monospace",
        }}
      >
        {/* Header */}
        <div className="text-center mb-3">
          <h2 className="font-bold text-sm uppercase">{data.outlet.name}</h2>
          <p className="text-[10px] leading-tight">{data.outlet.address}</p>
          <p className="text-[10px]">Telp: {data.outlet.phone}</p>
          {data.receiptHeader && (
            <p className="text-[10px] mt-1">{data.receiptHeader}</p>
          )}
        </div>

        {renderDivider()}

        {/* Transaction Info */}
        <div className="space-y-0.5 text-[10px]">
          <div className="flex justify-between">
            <span>No:</span>
            <span className="font-semibold">{data.transactionNumber}</span>
          </div>
          <div className="flex justify-between">
            <span>Tanggal:</span>
            <span>{formatDateTime(data.transactionDate)}</span>
          </div>
          {data.cashierName && (
            <div className="flex justify-between">
              <span>Kasir:</span>
              <span>{data.cashierName}</span>
            </div>
          )}
        </div>

        {renderDivider()}

        {/* Items */}
        <div className="space-y-1">
          {data.items.map((item, index) => (
            <div key={index} className="text-[10px]">
              <div className="font-medium truncate">{item.name}</div>
              <div className="flex justify-between pl-2">
                <span>
                  {item.quantity} x {formatCurrency(item.unitPrice)}
                </span>
                <span>{formatCurrency(item.subtotal)}</span>
              </div>
            </div>
          ))}
        </div>

        {renderDivider()}

        {/* Totals */}
        <div className="space-y-0.5 text-[10px]">
          <div className="flex justify-between">
            <span>Subtotal</span>
            <span>{formatCurrency(data.subtotal)}</span>
          </div>
          {data.tax > 0 && (
            <div className="flex justify-between">
              <span>Pajak ({data.taxRate}%)</span>
              <span>{formatCurrency(data.tax)}</span>
            </div>
          )}
          {data.discount > 0 && (
            <div className="flex justify-between text-red-600">
              <span>Diskon</span>
              <span>-{formatCurrency(data.discount)}</span>
            </div>
          )}
          <div className="flex justify-between font-bold text-sm pt-1 border-t border-gray-400">
            <span>TOTAL</span>
            <span>{formatCurrency(data.total)}</span>
          </div>
        </div>

        {renderDivider()}

        {/* Payment Details */}
        <div className="space-y-0.5 text-[10px]">
          <div className="font-semibold">Pembayaran:</div>
          {data.payments.map((payment, index) => (
            <div key={index} className="flex justify-between pl-2">
              <span>{formatPaymentMethod(payment.method)}</span>
              <span>{formatCurrency(payment.amount)}</span>
            </div>
          ))}
          {data.cashReceived && data.cashReceived > 0 && (
            <>
              <div className="flex justify-between pl-2">
                <span>Tunai Diterima</span>
                <span>{formatCurrency(data.cashReceived)}</span>
              </div>
              {data.change && data.change > 0 && (
                <div className="flex justify-between pl-2 font-semibold">
                  <span>Kembalian</span>
                  <span>{formatCurrency(data.change)}</span>
                </div>
              )}
            </>
          )}
        </div>

        {renderDivider()}

        {/* Footer */}
        <div className="text-center mt-3 space-y-1">
          <p className="text-[10px]">
            {data.receiptFooter || 'Terima kasih atas kunjungan Anda!'}
          </p>
          <p className="text-[9px] text-gray-500">
            Simpan struk ini sebagai bukti pembayaran
          </p>
        </div>
      </div>
    );
  }
);

ReceiptTemplate.displayName = 'ReceiptTemplate';

export default ReceiptTemplate;
