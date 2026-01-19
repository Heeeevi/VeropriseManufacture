import { useState } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { PaymentFormData, PaymentStatus } from '@/types/payment';

interface TransactionWithItems {
  outlet_id: string;
  employee_id?: string;
  total_amount: number;
  payment_status: PaymentStatus;
  items: {
    product_id: string;
    quantity: number;
    price: number;
    subtotal: number;
  }[];
}

export function useMultiPayment() {
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const createTransactionWithPayments = async (
    transaction: TransactionWithItems,
    payments: PaymentFormData[]
  ) => {
    setIsProcessing(true);
    setError(null);

    try {
      // 1. Create Transaction
      const { data: newTransaction, error: txError } = await supabase
        .from('transactions')
        .insert({
          outlet_id: transaction.outlet_id,
          employee_id: transaction.employee_id,
          total_amount: transaction.total_amount,
          payment_status: transaction.payment_status,
          transaction_date: new Date().toISOString(),
        })
        .select()
        .single();

      if (txError) throw txError;

      // 2. Create Transaction Items
      const itemsToInsert = transaction.items.map(item => ({
        transaction_id: newTransaction.id,
        product_id: item.product_id,
        quantity: item.quantity,
        price: item.price,
        subtotal: item.subtotal,
      }));

      const { error: itemsError } = await supabase
        .from('transaction_items')
        .insert(itemsToInsert);

      if (itemsError) throw itemsError;

      // 3. Create Transaction Payments
      const paymentsToInsert = payments.map(payment => ({
        transaction_id: newTransaction.id,
        payment_method: payment.payment_method,
        amount: payment.amount,
        reference_number: payment.reference_number,
        card_number_last4: payment.card_number_last4,
        bank_name: payment.bank_name,
        notes: payment.notes,
        payment_date: new Date().toISOString(),
      }));

      const { error: paymentsError } = await supabase
        .from('transaction_payments')
        .insert(paymentsToInsert);

      if (paymentsError) throw paymentsError;

      // 4. Update inventory for each product
      for (const item of transaction.items) {
        const { error: invError } = await supabase.rpc('update_inventory', {
          p_outlet_id: transaction.outlet_id,
          p_product_id: item.product_id,
          p_quantity_change: -item.quantity, // Negative for sale
        });

        if (invError) throw invError;
      }

      return newTransaction;
    } catch (err: any) {
      console.error('Transaction error:', err);
      setError(err.message || 'Terjadi kesalahan saat memproses transaksi');
      throw err;
    } finally {
      setIsProcessing(false);
    }
  };

  const addPaymentToTransaction = async (
    transactionId: string,
    payment: PaymentFormData
  ) => {
    setIsProcessing(true);
    setError(null);

    try {
      // Insert new payment
      const { error: paymentError } = await supabase
        .from('transaction_payments')
        .insert({
          transaction_id: transactionId,
          payment_method: payment.payment_method,
          amount: payment.amount,
          reference_number: payment.reference_number,
          card_number_last4: payment.card_number_last4,
          bank_name: payment.bank_name,
          notes: payment.notes,
          payment_date: new Date().toISOString(),
        });

      if (paymentError) throw paymentError;

      // Trigger will auto-update payment_status
      return true;
    } catch (err: any) {
      console.error('Payment error:', err);
      setError(err.message || 'Gagal menambahkan pembayaran');
      throw err;
    } finally {
      setIsProcessing(false);
    }
  };

  const getTransactionPayments = async (transactionId: string) => {
    const { data, error } = await supabase
      .from('transaction_payments')
      .select('*')
      .eq('transaction_id', transactionId)
      .order('payment_date', { ascending: true });

    if (error) {
      console.error('Error fetching payments:', error);
      return [];
    }

    return data || [];
  };

  const calculatePaymentSummary = (payments: PaymentFormData[]) => {
    const summary = {
      total: 0,
      byMethod: {} as Record<string, number>,
    };

    payments.forEach(payment => {
      const amount = Number(payment.amount) || 0;
      summary.total += amount;
      summary.byMethod[payment.payment_method] = 
        (summary.byMethod[payment.payment_method] || 0) + amount;
    });

    return summary;
  };

  return {
    isProcessing,
    error,
    createTransactionWithPayments,
    addPaymentToTransaction,
    getTransactionPayments,
    calculatePaymentSummary,
  };
}
