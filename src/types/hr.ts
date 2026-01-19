// ============================================================================
// HR TYPES - Attendance & Incentives
// ============================================================================

export type AttendanceStatus = 'present' | 'late' | 'absent' | 'leave' | 'sick' | 'holiday' | 'off';

export interface Attendance {
  id: string;
  employee_id: string;
  outlet_id: string;
  attendance_date: string;
  shift_id?: string;
  
  // Clock times
  clock_in?: string;
  clock_out?: string;
  
  // Status
  status: AttendanceStatus;
  
  // Calculated fields
  hours_worked?: number;
  overtime_hours: number;
  late_duration_minutes: number;
  
  // Break time
  break_start?: string;
  break_end?: string;
  break_duration_minutes: number;
  
  notes?: string;
  created_at: string;
  updated_at: string;
  
  // Relations
  employee?: any;
  outlet?: any;
  shift?: any;
}

// ============================================================================
// SALES TARGET & INCENTIVE TYPES
// ============================================================================

export type TargetType = 'product_quantity' | 'product_value' | 'total_sales' | 'category_sales';
export type TargetPeriod = 'daily' | 'weekly' | 'monthly' | 'quarterly';
export type IncentiveType = 'fixed' | 'percentage' | 'tiered';

export interface SalesTarget {
  id: string;
  target_name: string;
  target_type: TargetType;
  
  // Target scope
  product_id?: string;
  category_id?: string;
  outlet_id?: string;
  
  // Target period
  target_period: TargetPeriod;
  target_value: number;
  
  // Incentive
  incentive_type: IncentiveType;
  incentive_amount: number;
  incentive_percentage?: number;
  
  // Validity
  start_date: string;
  end_date?: string;
  
  // Status
  is_active: boolean;
  
  // Tiered incentives
  tiers?: Array<{
    min: number;
    max?: number;
    amount: number;
  }>;
  
  notes?: string;
  created_by?: string;
  created_at: string;
  updated_at: string;
  
  // Relations
  product?: any;
  category?: any;
  outlet?: any;
}

export type IncentiveStatus = 'pending' | 'approved' | 'paid' | 'cancelled';

export interface EmployeeIncentive {
  id: string;
  employee_id: string;
  target_id?: string;
  outlet_id: string;
  
  // Period info
  period_type: TargetPeriod;
  period_date: string;
  period_start: string;
  period_end: string;
  
  // Achievement
  target_value: number;
  achieved_value: number;
  achievement_percentage: number;
  
  // Incentive calculation
  incentive_amount: number;
  
  // Related transactions
  transaction_ids?: string[];
  transaction_count: number;
  
  // Status
  status: IncentiveStatus;
  approved_by?: string;
  approved_at?: string;
  paid_date?: string;
  payment_reference?: string;
  
  notes?: string;
  created_at: string;
  updated_at: string;
  
  // Relations
  employee?: any;
  target?: SalesTarget;
  outlet?: any;
}

// Enhanced Payroll
export interface PayrollEnhanced {
  id: string;
  employee_id: string;
  outlet_id: string;
  period_month: number;
  period_year: number;
  
  // Base salary
  base_salary: number;
  
  // Additional fields
  total_incentives: number;
  attendance_days: number;
  late_count: number;
  absent_count: number;
  overtime_hours: number;
  overtime_pay: number;
  deductions: number;
  net_salary: number; // Auto-calculated
  
  // Status
  status: string;
  paid_date?: string;
  payment_method?: string;
  
  notes?: string;
  created_at: string;
  updated_at: string;
  
  // Relations
  employee?: any;
  outlet?: any;
  incentives?: EmployeeIncentive[];
}

// Status labels & colors
export const ATTENDANCE_STATUS_LABELS: Record<AttendanceStatus, string> = {
  present: 'Hadir',
  late: 'Terlambat',
  absent: 'Tidak Hadir',
  leave: 'Cuti',
  sick: 'Sakit',
  holiday: 'Libur',
  off: 'Off',
};

export const ATTENDANCE_STATUS_COLORS: Record<AttendanceStatus, string> = {
  present: 'bg-green-100 text-green-800',
  late: 'bg-yellow-100 text-yellow-800',
  absent: 'bg-red-100 text-red-800',
  leave: 'bg-blue-100 text-blue-800',
  sick: 'bg-orange-100 text-orange-800',
  holiday: 'bg-purple-100 text-purple-800',
  off: 'bg-gray-100 text-gray-800',
};

export const TARGET_TYPE_LABELS: Record<TargetType, string> = {
  product_quantity: 'Kuantitas Produk',
  product_value: 'Nilai Produk',
  total_sales: 'Total Penjualan',
  category_sales: 'Penjualan Kategori',
};

export const TARGET_PERIOD_LABELS: Record<TargetPeriod, string> = {
  daily: 'Harian',
  weekly: 'Mingguan',
  monthly: 'Bulanan',
  quarterly: 'Kuartalan',
};

export const INCENTIVE_TYPE_LABELS: Record<IncentiveType, string> = {
  fixed: 'Tetap',
  percentage: 'Persentase',
  tiered: 'Bertingkat',
};

export const INCENTIVE_STATUS_LABELS: Record<IncentiveStatus, string> = {
  pending: 'Pending',
  approved: 'Disetujui',
  paid: 'Dibayar',
  cancelled: 'Dibatalkan',
};

export const INCENTIVE_STATUS_COLORS: Record<IncentiveStatus, string> = {
  pending: 'bg-yellow-100 text-yellow-800',
  approved: 'bg-green-100 text-green-800',
  paid: 'bg-blue-100 text-blue-800',
  cancelled: 'bg-red-100 text-red-800',
};
