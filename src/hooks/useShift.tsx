import { createContext, useContext, useState, ReactNode, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from './useAuth';
import { useOutlet } from './useOutlet';
import type { Shift } from '@/types/database';
import { useToast } from './use-toast';

interface ShiftContextType {
  currentShift: Shift | null;
  loading: boolean;
  startShift: (openingCash: number) => Promise<boolean>;
  endShift: (closingCash: number, notes?: string) => Promise<boolean>;
  refetch: () => Promise<void>;
}

const ShiftContext = createContext<ShiftContextType | undefined>(undefined);

export function ShiftProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const { selectedOutlet } = useOutlet();
  const { toast } = useToast();
  const [currentShift, setCurrentShift] = useState<Shift | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchCurrentShift = async () => {
    if (!user || !selectedOutlet) {
      setCurrentShift(null);
      setLoading(false);
      return;
    }

    try {
      const { data } = await supabase
        .from('shifts')
        .select('*')
        .eq('user_id', user.id)
        .eq('outlet_id', selectedOutlet.id)
        .is('ended_at', null)
        .order('started_at', { ascending: false })
        .limit(1)
        .single();

      setCurrentShift(data as unknown as Shift | null);
    } catch {
      setCurrentShift(null);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCurrentShift();
  }, [user, selectedOutlet]);

  const startShift = async (openingCash: number): Promise<boolean> => {
    if (!user || !selectedOutlet) {
      toast({ title: 'Error', description: 'User atau outlet tidak ditemukan', variant: 'destructive' });
      return false;
    }

    try {
      const { data, error } = await supabase
        .from('shifts')
        .insert({
          user_id: user.id,
          outlet_id: selectedOutlet.id,
          opening_cash: openingCash,
        })
        .select()
        .single();

      if (error) throw error;

      setCurrentShift(data as unknown as Shift);
      toast({ title: 'Shift dimulai', description: 'Selamat bekerja!' });
      return true;
    } catch (error) {
      console.error('Error starting shift:', error);
      toast({ title: 'Error', description: 'Gagal memulai shift', variant: 'destructive' });
      return false;
    }
  };

  const endShift = async (closingCash: number, notes?: string): Promise<boolean> => {
    if (!currentShift) {
      toast({ title: 'Error', description: 'Tidak ada shift aktif', variant: 'destructive' });
      return false;
    }

    try {
      const { error } = await supabase
        .from('shifts')
        .update({
          ended_at: new Date().toISOString(),
          closing_cash: closingCash,
          notes,
        })
        .eq('id', currentShift.id);

      if (error) throw error;

      setCurrentShift(null);
      toast({ title: 'Shift selesai', description: 'Terima kasih atas kerja kerasnya!' });
      return true;
    } catch (error) {
      console.error('Error ending shift:', error);
      toast({ title: 'Error', description: 'Gagal mengakhiri shift', variant: 'destructive' });
      return false;
    }
  };

  const value: ShiftContextType = {
    currentShift,
    loading,
    startShift,
    endShift,
    refetch: fetchCurrentShift,
  };

  return <ShiftContext.Provider value={value}>{children}</ShiftContext.Provider>;
}

export function useShift() {
  const context = useContext(ShiftContext);
  if (context === undefined) {
    throw new Error('useShift must be used within a ShiftProvider');
  }
  return context;
}
