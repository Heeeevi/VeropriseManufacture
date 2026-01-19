// ============================================================================
// PAYMENT TYPES - Multi-Payment System
// ============================================================================

export type PaymentMethod = 
  | 'cash' 
  | 'qris' 
  | 'transfer' 
  | 'olshop' 
  | 'debit_card' 
  | 'credit_card' 
  | 'other';

export type PaymentStatus = 'paid' | 'partial' | 'pending' | 'refunded';

export interface TransactionPayment {
  id: string;
  transaction_id: string;
  payment_method: PaymentMethod;
  amount: number;
  payment_date: string;
  reference_number?: string;
  card_number_last4?: string;
  bank_name?: string;
  notes?: string;
  created_by?: string;
  created_at: string;
  updated_at: string;
}

export interface Transaction {
  id: string;
  transaction_number: string;
  outlet_id: string;
  total: number;
  payment_status: PaymentStatus;
  total_paid: number;
  remaining_amount: number;
  is_multi_payment: boolean;
  payment_method?: PaymentMethod; // Legacy field
  created_by?: string;
  created_at: string;
  updated_at: string;
  
  // Relations
  payments?: TransactionPayment[];
  items?: any[];
  outlet?: any;
}

export interface PaymentSummary {
  cash_sales: number;
  qris_sales: number;
  transfer_sales: number;
  olshop_sales: number;
  card_sales: number;
  other_sales: number;
  total_sales: number;
  total_expenses: number;
  cash_to_deposit: number;
}

export interface PaymentFormData {
  payment_method: PaymentMethod;
  amount: number;
  reference_number?: string;
  card_number_last4?: string;
  bank_name?: string;
  notes?: string;
}

// Payment method labels & icons
export const PAYMENT_METHOD_LABELS: Record<PaymentMethod, string> = {
  cash: 'Tunai',
  qris: 'QRIS',
  transfer: 'Transfer Bank',
  olshop: 'Marketplace/Olshop',
  debit_card: 'Kartu Debit',
  credit_card: 'Kartu Kredit',
  other: 'Lainnya',
};

export const PAYMENT_METHOD_COLORS: Record<PaymentMethod, string> = {
  cash: 'bg-green-100 text-green-800 border-green-300',
  qris: 'bg-blue-100 text-blue-800 border-blue-300',
  transfer: 'bg-purple-100 text-purple-800 border-purple-300',
  olshop: 'bg-orange-100 text-orange-800 border-orange-300',
  debit_card: 'bg-indigo-100 text-indigo-800 border-indigo-300',
  credit_card: 'bg-pink-100 text-pink-800 border-pink-300',
  other: 'bg-gray-100 text-gray-800 border-gray-300',
};

// Payment status labels & colors
export const PAYMENT_STATUS_LABELS: Record<PaymentStatus, string> = {
  paid: 'Lunas',
  partial: 'Sebagian',
  pending: 'Belum Bayar',
  refunded: 'Refund',
};

export const PAYMENT_STATUS_COLORS: Record<PaymentStatus, string> = {
  paid: 'bg-green-100 text-green-800',
  partial: 'bg-yellow-100 text-yellow-800',
  pending: 'bg-red-100 text-red-800',
  refunded: 'bg-gray-100 text-gray-800',
};
