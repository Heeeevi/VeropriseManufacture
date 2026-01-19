import { useState, useEffect } from 'react';
import { TrendingUp, DollarSign, CheckCircle, Clock } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { supabase } from '@/integrations/supabase/client';
import { INCENTIVE_STATUS_LABELS, INCENTIVE_STATUS_COLORS } from '@/types/hr';

export function IncentiveDashboard() {
  const [outlets, setOutlets] = useState<any[]>([]);
  const [selectedOutlet, setSelectedOutlet] = useState('');
  const [selectedMonth, setSelectedMonth] = useState(new Date().toISOString().slice(0, 7));
  const [incentives, setIncentives] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchOutlets();
  }, []);

  useEffect(() => {
    if (selectedOutlet) {
      fetchIncentives();
    }
  }, [selectedOutlet, selectedMonth]);

  const fetchOutlets = async () => {
    const { data } = await supabase
      .from('outlets')
      .select('*')
      .eq('is_active', true);
    setOutlets(data || []);
  };

  const fetchIncentives = async () => {
    setLoading(true);
    try {
      const startDate = `${selectedMonth}-01`;
      const endDate = `${selectedMonth}-31`;

      const { data, error } = await supabase
        .from('employee_incentives')
        .select(`
          *,
          employee:employees(name, phone),
          sales_target:sales_targets(
            target_type,
            target_amount,
            incentive_type,
            incentive_value
          )
        `)
        .eq('outlet_id', selectedOutlet)
        .gte('period_start', startDate)
        .lte('period_end', endDate)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setIncentives(data || []);
    } catch (error) {
      console.error('Error fetching incentives:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async (incentiveId: string) => {
    try {
      const { error } = await supabase
        .from('employee_incentives')
        .update({
          status: 'approved',
          approved_at: new Date().toISOString(),
        })
        .eq('id', incentiveId);

      if (error) throw error;
      alert('Incentive approved!');
      fetchIncentives();
    } catch (error) {
      console.error('Approval error:', error);
      alert('Gagal approve incentive');
    }
  };

  const handleReject = async (incentiveId: string) => {
    const reason = prompt('Alasan reject:');
    if (!reason) return;

    try {
      const { error } = await supabase
        .from('employee_incentives')
        .update({
          status: 'rejected',
        })
        .eq('id', incentiveId);

      if (error) throw error;
      alert('Incentive rejected');
      fetchIncentives();
    } catch (error) {
      console.error('Reject error:', error);
      alert('Gagal reject incentive');
    }
  };

  const stats = {
    total: incentives.reduce((sum, i) => sum + i.incentive_amount, 0),
    pending: incentives.filter(i => i.status === 'pending').length,
    approved: incentives.filter(i => i.status === 'approved').length,
    paid: incentives.filter(i => i.status === 'paid').length,
  };

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Incentive Dashboard</h1>
        <p className="text-gray-600">Monitor & approve bonus karyawan</p>
      </div>

      {/* Filters */}
      <Card>
        <CardContent className="pt-6">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Select value={selectedOutlet} onValueChange={setSelectedOutlet}>
                <SelectTrigger>
                  <SelectValue placeholder="Pilih outlet" />
                </SelectTrigger>
                <SelectContent>
                  {outlets.map(o => (
                    <SelectItem key={o.id} value={o.id}>{o.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <input
                type="month"
                value={selectedMonth}
                onChange={(e) => setSelectedMonth(e.target.value)}
                className="w-full px-3 py-2 border rounded-md"
              />
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Stats */}
      {selectedOutlet && (
        <div className="grid grid-cols-4 gap-4">
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Total Incentive</p>
                  <p className="text-2xl font-bold text-blue-600">
                    Rp {(stats.total / 1000).toFixed(0)}K
                  </p>
                </div>
                <DollarSign className="h-8 w-8 text-blue-600" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Pending</p>
                  <p className="text-2xl font-bold text-orange-600">{stats.pending}</p>
                </div>
                <Clock className="h-8 w-8 text-orange-600" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Approved</p>
                  <p className="text-2xl font-bold text-green-600">{stats.approved}</p>
                </div>
                <CheckCircle className="h-8 w-8 text-green-600" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Paid</p>
                  <p className="text-2xl font-bold text-blue-600">{stats.paid}</p>
                </div>
                <TrendingUp className="h-8 w-8 text-blue-600" />
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Incentives List */}
      {selectedOutlet && (
        <Card>
          <CardHeader>
            <CardTitle>Daftar Incentive ({incentives.length})</CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="text-center py-8">Loading...</div>
            ) : incentives.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                <DollarSign className="h-12 w-12 mx-auto mb-4 text-gray-400" />
                <p>Belum ada incentive untuk periode ini</p>
              </div>
            ) : (
              <div className="space-y-3">
                {incentives.map((incentive) => (
                  <div key={incentive.id} className="p-4 border rounded-lg">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <p className="font-semibold text-lg">{incentive.employee?.name}</p>
                          <Badge className={INCENTIVE_STATUS_COLORS[incentive.status as keyof typeof INCENTIVE_STATUS_COLORS]}>
                            {INCENTIVE_STATUS_LABELS[incentive.status as keyof typeof INCENTIVE_STATUS_LABELS]}
                          </Badge>
                        </div>

                        <div className="grid grid-cols-4 gap-4 text-sm mt-3">
                          <div>
                            <p className="text-gray-600">Target</p>
                            <p className="font-bold">
                              Rp {incentive.sales_target?.target_amount.toLocaleString('id-ID')}
                            </p>
                          </div>
                          <div>
                            <p className="text-gray-600">Actual Sales</p>
                            <p className="font-bold text-blue-600">
                              Rp {incentive.actual_sales.toLocaleString('id-ID')}
                            </p>
                          </div>
                          <div>
                            <p className="text-gray-600">Achievement</p>
                            <p className={`font-bold ${incentive.achievement_percentage >= 100 ? 'text-green-600' : 'text-orange-600'}`}>
                              {incentive.achievement_percentage.toFixed(1)}%
                            </p>
                          </div>
                          <div>
                            <p className="text-gray-600">Incentive Amount</p>
                            <p className="font-bold text-green-600 text-lg">
                              Rp {incentive.incentive_amount.toLocaleString('id-ID')}
                            </p>
                          </div>
                        </div>

                        <div className="mt-3 text-xs text-gray-600">
                          <p>Periode: {new Date(incentive.period_start).toLocaleDateString('id-ID')} - {new Date(incentive.period_end).toLocaleDateString('id-ID')}</p>
                          {incentive.notes && <p className="italic">Catatan: {incentive.notes}</p>}
                        </div>
                      </div>

                      {incentive.status === 'pending' && (
                        <div className="flex gap-2">
                          <Button
                            size="sm"
                            onClick={() => handleApprove(incentive.id)}
                            className="bg-green-600 hover:bg-green-700"
                          >
                            Approve
                          </Button>
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => handleReject(incentive.id)}
                            className="text-red-600"
                          >
                            Reject
                          </Button>
                        </div>
                      )}

                      {incentive.status === 'approved' && (
                        <Badge variant="outline" className="text-green-600">
                          ✓ Approved
                        </Badge>
                      )}

                      {incentive.status === 'paid' && (
                        <Badge variant="outline" className="text-blue-600">
                          ✓ Paid
                        </Badge>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {selectedOutlet && (
        <Card className="bg-green-50 border-green-200">
          <CardContent className="pt-6">
            <h4 className="font-semibold text-sm mb-2">✅ Approval Flow:</h4>
            <ol className="text-xs text-gray-700 space-y-1 list-decimal list-inside">
              <li>Sistem otomatis calculate incentive saat target tercapai</li>
              <li>Status: PENDING (butuh approval manager/owner)</li>
              <li>Manager review & approve/reject</li>
              <li>Status: APPROVED (siap masuk payroll)</li>
              <li>Finance process payment</li>
              <li>Status: PAID (selesai)</li>
            </ol>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
