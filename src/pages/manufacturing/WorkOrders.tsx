import React, { useEffect, useMemo, useState } from 'react';
import MainLayout from '@/components/layout/MainLayout';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { supabase } from '@/integrations/supabase/client';
import { ClipboardList, Loader2, ListChecks, Factory, CheckCircle2, Activity, AlertTriangle } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useNavigate } from 'react-router-dom';
import { useToast } from '@/hooks/use-toast';
import { format } from 'date-fns';

type WoStatus = 'planned' | 'kitting' | 'in_progress' | 'completed' | 'cancelled';

interface WoItem {
  id: string;
  status: 'pending' | 'picked';
  planned_quantity: number;
}

interface WoRow {
  id: string;
  wo_number: string;
  status: WoStatus;
  target_quantity: number;
  produced_quantity?: number;
  progress_percentage?: number;
  item_completion_percentage?: number;
  created_at: string;
  product?: { name?: string };
  warehouse?: { name?: string };
  items?: WoItem[];
}

const statusOrder: WoStatus[] = ['planned', 'kitting', 'in_progress', 'completed', 'cancelled'];

const statusLabel: Record<WoStatus, string> = {
  planned: 'Planned',
  kitting: 'Kitting',
  in_progress: 'In Progress',
  completed: 'Completed',
  cancelled: 'Cancelled',
};

const statusColor: Record<WoStatus, string> = {
  planned: 'bg-slate-500',
  kitting: 'bg-amber-500',
  in_progress: 'bg-blue-500',
  completed: 'bg-emerald-600',
  cancelled: 'bg-rose-600',
};

function calculateProgress(wo: WoRow): number {
  if (typeof wo.progress_percentage === 'number' && !Number.isNaN(wo.progress_percentage)) {
    return Math.max(0, Math.min(100, Math.round(Number(wo.progress_percentage))));
  }

  if (wo.status === 'completed') return 100;
  if (wo.status === 'cancelled') return 0;

  const totalItems = wo.items?.length || 0;
  const pickedItems = wo.items?.filter((item) => item.status === 'picked').length || 0;
  const pickedRatio = totalItems > 0 ? pickedItems / totalItems : 0;

  const baseByStatus: Record<Exclude<WoStatus, 'completed' | 'cancelled'>, number> = {
    planned: 8,
    kitting: 30,
    in_progress: 62,
  };

  const base = baseByStatus[wo.status as Exclude<WoStatus, 'completed' | 'cancelled'>] || 0;
  const baselineProgress = Math.min(95, Math.round(base + pickedRatio * 33));

  const targetQty = Number(wo.target_quantity || 0);
  const producedQty = Number(wo.produced_quantity || 0);
  const outputProgress = targetQty > 0 ? Math.min(95, Math.round((producedQty / targetQty) * 100)) : 0;

  return Math.max(baselineProgress, outputProgress);
}


export default function WorkOrders() {
  const { toast } = useToast();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [workOrders, setWorkOrders] = useState<WoRow[]>([]);
  const [productFilter, setProductFilter] = useState('all');
  const [startDate, setStartDate] = useState(() => {
    const d = new Date();
    d.setDate(d.getDate() - 29);
    return format(d, 'yyyy-MM-dd');
  });
  const [endDate, setEndDate] = useState(() => format(new Date(), 'yyyy-MM-dd'));
  const [attainmentThreshold, setAttainmentThreshold] = useState('90');

  const fetchWorkOrders = async () => {
    try {
      setLoading(true);
      const { data, error } = await (supabase as any)
        .from('work_orders')
        .select(`
          id,
          wo_number,
          status,
          target_quantity,
          produced_quantity,
          progress_percentage,
          item_completion_percentage,
          created_at,
          product:products!product_id(name),
          warehouse:warehouses!warehouse_id(name),
          items:work_order_items(id, status, planned_quantity)
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setWorkOrders((data || []) as WoRow[]);
    } catch (error: any) {
      toast({
        title: 'Gagal memuat Work Orders',
        description: error.message || 'Terjadi kesalahan saat mengambil data WO.',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchWorkOrders();

    const channel = supabase
      .channel('manufacturing-wo-summary-live')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'work_orders' }, fetchWorkOrders)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'work_order_items' }, fetchWorkOrders)
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const productOptions = useMemo(() => {
    const map = new Map<string, string>();
    workOrders.forEach((wo) => {
      if (wo.product?.name) {
        map.set(wo.product.name, wo.product.name);
      }
    });
    return Array.from(map.values()).sort((a, b) => a.localeCompare(b));
  }, [workOrders]);

  const filteredOrders = useMemo(() => {
    return workOrders.filter((wo) => {
      const woDate = wo.created_at?.slice(0, 10);
      if (!woDate) return false;

      if (startDate && woDate < startDate) return false;
      if (endDate && woDate > endDate) return false;
      if (productFilter !== 'all' && wo.product?.name !== productFilter) return false;

      return true;
    });
  }, [workOrders, startDate, endDate, productFilter]);

  const computedOrders = useMemo(
    () =>
      filteredOrders.map((wo) => ({
        ...wo,
        progress: calculateProgress(wo),
      })),
    [filteredOrders]
  );

  const statusStats = useMemo(() => {
    const counter = {
      planned: 0,
      kitting: 0,
      in_progress: 0,
      completed: 0,
      cancelled: 0,
    } as Record<WoStatus, number>;

    computedOrders.forEach((wo) => {
      counter[wo.status] += 1;
    });

    return counter;
  }, [computedOrders]);

  const topProgressOrders = useMemo(
    () => computedOrders.filter((wo) => wo.status !== 'cancelled').slice(0, 8),
    [computedOrders]
  );

  const total = computedOrders.length;
  const active = statusStats.kitting + statusStats.in_progress;
  const completed = statusStats.completed;
  const avgProgress = total > 0 ? Math.round(computedOrders.reduce((sum, wo) => sum + wo.progress, 0) / total) : 0;

  const completedOrders = useMemo(
    () => computedOrders.filter((wo) => wo.status === 'completed'),
    [computedOrders]
  );

  const outputStats = useMemo(() => {
    if (completedOrders.length === 0) {
      return {
        totalTarget: 0,
        totalProduced: 0,
        attainment: 0,
        avgYieldGap: 0,
      };
    }

    const totalTarget = completedOrders.reduce((sum, wo) => sum + Number(wo.target_quantity || 0), 0);
    const totalProduced = completedOrders.reduce((sum, wo) => sum + Number(wo.produced_quantity || 0), 0);
    const attainment = totalTarget > 0 ? Number(((totalProduced / totalTarget) * 100).toFixed(1)) : 0;
    const avgYieldGap = Number(
      (
        completedOrders.reduce((sum, wo) => {
          const target = Number(wo.target_quantity || 0);
          const produced = Number(wo.produced_quantity || 0);
          if (target <= 0) return sum;
          return sum + (((target - produced) / target) * 100);
        }, 0) / completedOrders.length
      ).toFixed(1)
    );

    return {
      totalTarget,
      totalProduced,
      attainment,
      avgYieldGap,
    };
  }, [completedOrders]);

  const thresholdValue = useMemo(() => {
    const v = Number(attainmentThreshold || 0);
    if (Number.isNaN(v)) return 0;
    return Math.max(0, Math.min(100, v));
  }, [attainmentThreshold]);

  const lowAttainmentOrders = useMemo(() => {
    return completedOrders
      .map((wo) => {
        const target = Number(wo.target_quantity || 0);
        const produced = Number(wo.produced_quantity || 0);
        const attainment = target > 0 ? (produced / target) * 100 : 0;
        return { ...wo, attainment };
      })
      .filter((wo) => Number(wo.target_quantity || 0) > 0 && wo.attainment < thresholdValue)
      .sort((a, b) => a.attainment - b.attainment)
      .slice(0, 6);
  }, [completedOrders, thresholdValue]);

  const yieldByProduct = useMemo(() => {
    const map = new Map<string, { target: number; produced: number; count: number }>();

    completedOrders.forEach((wo) => {
      const key = wo.product?.name || 'Unknown Product';
      const curr = map.get(key) || { target: 0, produced: 0, count: 0 };
      curr.target += Number(wo.target_quantity || 0);
      curr.produced += Number(wo.produced_quantity || 0);
      curr.count += 1;
      map.set(key, curr);
    });

    return Array.from(map.entries())
      .map(([name, data]) => {
        const attainment = data.target > 0 ? (data.produced / data.target) * 100 : 0;
        const yieldGap = 100 - attainment;
        return {
          name,
          target: data.target,
          produced: data.produced,
          attainment: Number(attainment.toFixed(1)),
          yieldGap: Number(yieldGap.toFixed(1)),
          count: data.count,
        };
      })
      .sort((a, b) => b.yieldGap - a.yieldGap)
      .slice(0, 8);
  }, [completedOrders]);

  const trendData = useMemo(() => {
    const days = 7;
    const rows: Array<{ label: string; created: number; completed: number; avgProgress: number }> = [];

    for (let i = days - 1; i >= 0; i -= 1) {
      const day = new Date();
      day.setHours(0, 0, 0, 0);
      day.setDate(day.getDate() - i);

      const dateKey = format(day, 'yyyy-MM-dd');
      const dayOrders = computedOrders.filter((wo) => wo.created_at?.startsWith(dateKey));
      const created = dayOrders.length;
      const completedCount = dayOrders.filter((wo) => wo.status === 'completed').length;
      const dayAvgProgress = created > 0
        ? Math.round(dayOrders.reduce((sum, wo) => sum + wo.progress, 0) / created)
        : 0;

      rows.push({
        label: format(day, 'dd/MM'),
        created,
        completed: completedCount,
        avgProgress: dayAvgProgress,
      });
    }

    return rows;
  }, [computedOrders]);

  const maxTrendValue = Math.max(
    1,
    ...trendData.flatMap((row) => [row.created, row.completed])
  );

  return (
    <MainLayout>
      <div className="p-6 space-y-6">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold font-display flex items-center gap-2">
              <ClipboardList className="h-6 w-6" /> Work Orders (Summary)
            </h1>
            <p className="text-muted-foreground">Ringkasan daftar Perintah Kerja yang diterbitkan</p>
          </div>
          <Button onClick={() => navigate('/manufacturing/job-cards')}>Buka Job Cards Eksekusi</Button>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Filter Analitik</CardTitle>
            <CardDescription>Atur rentang waktu, produk, dan threshold alert attainment.</CardDescription>
          </CardHeader>
          <CardContent className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className="space-y-2">
              <Label>Tanggal Mulai</Label>
              <Input type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)} />
            </div>
            <div className="space-y-2">
              <Label>Tanggal Selesai</Label>
              <Input type="date" value={endDate} onChange={(e) => setEndDate(e.target.value)} />
            </div>
            <div className="space-y-2">
              <Label>Produk</Label>
              <Select value={productFilter} onValueChange={setProductFilter}>
                <SelectTrigger>
                  <SelectValue placeholder="Semua Produk" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Semua Produk</SelectItem>
                  {productOptions.map((productName) => (
                    <SelectItem key={productName} value={productName}>{productName}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>Threshold Alert (%)</Label>
              <Input
                type="number"
                min="0"
                max="100"
                value={attainmentThreshold}
                onChange={(e) => setAttainmentThreshold(e.target.value)}
              />
            </div>
          </CardContent>
        </Card>

        {lowAttainmentOrders.length > 0 && (
          <Alert variant="destructive">
            <AlertTriangle className="h-4 w-4" />
            <AlertTitle>Warning: Output Attainment Rendah</AlertTitle>
            <AlertDescription>
              {lowAttainmentOrders.length} WO selesai berada di bawah threshold {thresholdValue}%.
            </AlertDescription>
          </Alert>
        )}

        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
          <Card>
            <CardContent className="p-5 flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Total Work Orders</p>
                <p className="text-2xl font-bold">{total}</p>
              </div>
              <ListChecks className="h-6 w-6 text-primary" />
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-5 flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Aktif (Kitting + WIP)</p>
                <p className="text-2xl font-bold">{active}</p>
              </div>
              <Factory className="h-6 w-6 text-amber-600" />
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-5 flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Selesai</p>
                <p className="text-2xl font-bold">{completed}</p>
              </div>
              <CheckCircle2 className="h-6 w-6 text-emerald-600" />
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-5 flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Output Attainment</p>
                <p className="text-2xl font-bold">{outputStats.attainment}%</p>
                <p className="text-xs text-muted-foreground mt-1">progress rata-rata {avgProgress}%</p>
              </div>
              <Activity className="h-6 w-6 text-blue-600" />
            </CardContent>
          </Card>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Analisis Output Manufaktur</CardTitle>
            <CardDescription>Ringkasan realisasi hasil produksi dari WO yang selesai.</CardDescription>
          </CardHeader>
          <CardContent className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="rounded-lg border p-4">
              <p className="text-sm text-muted-foreground">Total Target (Completed WO)</p>
              <p className="text-2xl font-bold mt-1">{outputStats.totalTarget.toFixed(2)}</p>
            </div>
            <div className="rounded-lg border p-4">
              <p className="text-sm text-muted-foreground">Total Output Aktual</p>
              <p className="text-2xl font-bold mt-1">{outputStats.totalProduced.toFixed(2)}</p>
            </div>
            <div className="rounded-lg border p-4">
              <p className="text-sm text-muted-foreground">Rata-rata Yield Gap</p>
              <p className="text-2xl font-bold mt-1">{outputStats.avgYieldGap}%</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Deviasi Yield per Produk</CardTitle>
            <CardDescription>Perbandingan target vs output aktual untuk WO completed.</CardDescription>
          </CardHeader>
          <CardContent>
            {yieldByProduct.length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-6">Belum ada data completed WO pada filter saat ini.</p>
            ) : (
              <div className="space-y-4">
                {yieldByProduct.map((row) => (
                  <div key={row.name} className="space-y-2 border rounded-lg p-3">
                    <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-1">
                      <p className="font-medium">{row.name}</p>
                      <p className="text-xs text-muted-foreground">
                        WO: {row.count} | Target: {row.target.toFixed(2)} | Output: {row.produced.toFixed(2)}
                      </p>
                    </div>
                    <div className="space-y-1">
                      <div className="flex justify-between text-xs">
                        <span>Attainment {row.attainment}%</span>
                        <span className={row.yieldGap > 0 ? 'text-red-600' : 'text-emerald-600'}>
                          Yield Gap {row.yieldGap}%
                        </span>
                      </div>
                      <Progress value={Math.max(0, Math.min(100, row.attainment))} className="h-2" />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Grafik Status Work Orders</CardTitle>
            <CardDescription>Distribusi status proses produksi saat ini (live).</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {statusOrder.map((status) => {
              const value = statusStats[status];
              const percentage = total > 0 ? Math.round((value / total) * 100) : 0;

              return (
                <div key={status} className="space-y-2">
                  <div className="flex items-center justify-between text-sm">
                    <span className="font-medium">{statusLabel[status]}</span>
                    <span className="text-muted-foreground">{value} WO ({percentage}%)</span>
                  </div>
                  <div className="h-3 rounded-full bg-muted overflow-hidden">
                    <div className={`${statusColor[status]} h-full`} style={{ width: `${percentage}%` }} />
                  </div>
                </div>
              );
            })}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Tren Produksi 7 Hari</CardTitle>
            <CardDescription>Perbandingan WO dibuat vs WO selesai per hari.</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {trendData.map((row) => (
                <div key={row.label} className="space-y-2">
                  <div className="flex items-center justify-between text-sm">
                    <span className="font-medium">{row.label}</span>
                    <span className="text-muted-foreground">
                      dibuat {row.created} | selesai {row.completed} | avg {row.avgProgress}%
                    </span>
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <div className="h-2.5 rounded-full bg-blue-100 overflow-hidden">
                      <div
                        className="h-full bg-blue-500"
                        style={{ width: `${Math.round((row.created / maxTrendValue) * 100)}%` }}
                      />
                    </div>
                    <div className="h-2.5 rounded-full bg-emerald-100 overflow-hidden">
                      <div
                        className="h-full bg-emerald-600"
                        style={{ width: `${Math.round((row.completed / maxTrendValue) * 100)}%` }}
                      />
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Progress per Work Order</CardTitle>
            <CardDescription>
              Persentase dihitung dari status proses + ketersediaan item kitting yang sudah ditandai siap.
            </CardDescription>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="py-10 flex justify-center">
                <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
              </div>
            ) : topProgressOrders.length === 0 ? (
              <p className="text-sm text-muted-foreground py-8 text-center">Belum ada Work Order yang bisa ditampilkan.</p>
            ) : (
              <div className="space-y-4">
                {topProgressOrders.map((wo) => (
                  <div key={wo.id} className="border rounded-lg p-4 space-y-3">
                    <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-2">
                      <div>
                        <p className="font-semibold">{wo.wo_number}</p>
                        <p className="text-sm text-muted-foreground">
                          {wo.product?.name || '-'} | {wo.warehouse?.name || '-'} | {format(new Date(wo.created_at), 'dd MMM yyyy')}
                        </p>
                      </div>
                      <div className="flex items-center gap-2">
                        <Badge variant="outline">Target: {Number(wo.target_quantity || 0)}</Badge>
                        <Badge className="bg-primary/10 text-primary hover:bg-primary/20">{statusLabel[wo.status]}</Badge>
                      </div>
                    </div>
                    <div className="space-y-1">
                      <div className="flex justify-between text-sm">
                        <span className="text-muted-foreground">Progress</span>
                        <span className="font-medium">{wo.progress}%</span>
                      </div>
                      <Progress value={wo.progress} className="h-2.5" />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </MainLayout>
  );
}
