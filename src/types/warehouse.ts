// ============================================================================
// WAREHOUSE TYPES
// ============================================================================

export type WarehouseType = 'central' | 'regional';

export interface Warehouse {
  id: string;
  code: string;
  name: string;
  address?: string;
  phone?: string;
  warehouse_type: WarehouseType;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface WarehouseInventory {
  id: string;
  warehouse_id: string;
  product_id: string;
  quantity: number;
  min_stock: number;
  max_stock?: number;
  last_restock_date?: string;
  cost_per_unit: number;
  created_at: string;
  updated_at: string;
  
  // Relations
  warehouse?: Warehouse;
  product?: any;
}

// ============================================================================
// PURCHASE ORDER TYPES
// ============================================================================

export type POStatus = 'draft' | 'submitted' | 'approved' | 'received' | 'cancelled';

export interface PurchaseOrder {
  id: string;
  po_number: string;
  warehouse_id: string;
  supplier_id?: string;
  supplier_name?: string;
  status: POStatus;
  total_amount: number;
  ordered_by?: string;
  approved_by?: string;
  received_by?: string;
  order_date: string;
  expected_delivery_date?: string;
  actual_delivery_date?: string;
  notes?: string;
  created_at: string;
  updated_at: string;
  
  // Relations
  warehouse?: Warehouse;
  supplier?: any;
  items?: PurchaseOrderItem[];
}

export interface PurchaseOrderItem {
  id: string;
  po_id: string;
  product_id: string;
  product_name?: string;
  quantity_ordered: number;
  quantity_received: number;
  unit_price: number;
  subtotal: number;
  notes?: string;
  created_at: string;
  
  // Relations
  product?: any;
}

// ============================================================================
// STOCK TRANSFER TYPES
// ============================================================================

export type StockTransferStatus = 'pending' | 'approved' | 'in_transit' | 'received' | 'cancelled';

export interface StockTransferOrder {
  id: string;
  transfer_number: string;
  from_warehouse_id?: string;
  to_outlet_id?: string;
  status: StockTransferStatus;
  requested_by?: string;
  approved_by?: string;
  received_by?: string;
  request_date: string;
  approved_date?: string;
  shipped_date?: string;
  received_date?: string;
  notes?: string;
  created_at: string;
  updated_at: string;
  
  // Relations
  warehouse?: Warehouse;
  outlet?: any;
  items?: StockTransferItem[];
}

export interface StockTransferItem {
  id: string;
  transfer_id: string;
  product_id: string;
  product_name?: string;
  quantity_requested: number;
  quantity_approved?: number;
  quantity_received?: number;
  unit_cost?: number;
  notes?: string;
  created_at: string;
  
  // Relations
  product?: any;
}

// ============================================================================
// STOCK OPNAME TYPES
// ============================================================================

export type StockOpnameStatus = 'draft' | 'in_progress' | 'completed' | 'approved';
export type LocationType = 'warehouse' | 'outlet';

export interface StockOpname {
  id: string;
  opname_number: string;
  location_type: LocationType;
  warehouse_id?: string;
  outlet_id?: string;
  opname_date: string;
  period_month: number;
  period_year: number;
  status: StockOpnameStatus;
  conducted_by?: string;
  approved_by?: string;
  completed_date?: string;
  approved_date?: string;
  notes?: string;
  created_at: string;
  updated_at: string;
  
  // Relations
  warehouse?: Warehouse;
  outlet?: any;
  items?: StockOpnameItem[];
}

export interface StockOpnameItem {
  id: string;
  opname_id: string;
  product_id: string;
  product_name?: string;
  system_quantity: number;
  physical_quantity?: number;
  difference: number;
  difference_value?: number;
  notes?: string;
  counted_by?: string;
  counted_at?: string;
  created_at: string;
  
  // Relations
  product?: any;
}

// ============================================================================
// DAILY CLOSING TYPES
// ============================================================================

export type DailyClosingStatus = 'open' | 'closed' | 'approved';

export interface DailyClosingReport {
  id: string;
  outlet_id: string;
  closing_date: string;
  shift_id?: string;
  closed_by?: string;
  
  // Stock values
  opening_stock_value: number;
  closing_stock_value: number;
  
  // Sales breakdown
  total_sales: number;
  total_transactions: number;
  
  // Payment method breakdown
  cash_sales: number;
  qris_sales: number;
  transfer_sales: number;
  debit_card_sales: number;
  credit_card_sales: number;
  olshop_sales: number;
  other_sales: number;
  
  // Expenses
  total_expenses: number;
  
  // Cash deposit (auto-calculated)
  gross_sales: number;
  cash_to_deposit: number;
  
  // Status
  status: DailyClosingStatus;
  closed_at?: string;
  approved_by?: string;
  approved_at?: string;
  
  notes?: string;
  created_at: string;
  updated_at: string;
  
  // Relations
  outlet?: any;
  shift?: any;
}

// Status labels & colors
export const PO_STATUS_LABELS: Record<POStatus, string> = {
  draft: 'Draft',
  submitted: 'Diajukan',
  approved: 'Disetujui',
  received: 'Diterima',
  cancelled: 'Dibatalkan',
};

export const PO_STATUS_COLORS: Record<POStatus, string> = {
  draft: 'bg-gray-100 text-gray-800',
  submitted: 'bg-blue-100 text-blue-800',
  approved: 'bg-green-100 text-green-800',
  received: 'bg-purple-100 text-purple-800',
  cancelled: 'bg-red-100 text-red-800',
};

export const TRANSFER_STATUS_LABELS: Record<StockTransferStatus, string> = {
  pending: 'Pending',
  approved: 'Disetujui',
  in_transit: 'Dalam Perjalanan',
  received: 'Diterima',
  cancelled: 'Dibatalkan',
};

export const TRANSFER_STATUS_COLORS: Record<StockTransferStatus, string> = {
  pending: 'bg-yellow-100 text-yellow-800',
  approved: 'bg-green-100 text-green-800',
  in_transit: 'bg-blue-100 text-blue-800',
  received: 'bg-purple-100 text-purple-800',
  cancelled: 'bg-red-100 text-red-800',
};

export const OPNAME_STATUS_LABELS: Record<StockOpnameStatus, string> = {
  draft: 'Draft',
  in_progress: 'Dalam Proses',
  completed: 'Selesai',
  approved: 'Disetujui',
};

export const OPNAME_STATUS_COLORS: Record<StockOpnameStatus, string> = {
  draft: 'bg-gray-100 text-gray-800',
  in_progress: 'bg-blue-100 text-blue-800',
  completed: 'bg-green-100 text-green-800',
  approved: 'bg-purple-100 text-purple-800',
};

export const CLOSING_STATUS_LABELS: Record<DailyClosingStatus, string> = {
  open: 'Terbuka',
  closed: 'Ditutup',
  approved: 'Disetujui',
};

export const CLOSING_STATUS_COLORS: Record<DailyClosingStatus, string> = {
  open: 'bg-yellow-100 text-yellow-800',
  closed: 'bg-blue-100 text-blue-800',
  approved: 'bg-green-100 text-green-800',
};
