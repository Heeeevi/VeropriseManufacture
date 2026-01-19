import { useState, useEffect } from 'react';
import { Plus, Edit, Trash2, Target, TrendingUp } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { supabase } from '@/integrations/supabase/client';
import { TARGET_TYPE_LABELS, TARGET_PERIOD_LABELS, INCENTIVE_TYPE_LABELS } from '@/types/hr';

export function SalesTargetManagement() {
  const [targets, setTargets] = useState<any[]>([]);
  const [outlets, setOutlets] = useState<any[]>([]);
  const [products, setProducts] = useState<any[]>([]);
  const [categories, setCategories] = useState<any[]>([]);
  const [showModal, setShowModal] = useState(false);
  const [loading, setLoading] = useState(false);

  // Form state
  const [formData, setFormData] = useState({
    outlet_id: '',
    target_type: 'product' as 'product' | 'category' | 'total_sales',
    target_period: 'daily' as 'daily' | 'weekly' | 'monthly',
    product_id: '',
    category_id: '',
    target_amount: 0,
    incentive_type: 'fixed' as 'fixed' | 'percentage' | 'tiered',
    incentive_value: 0,
    start_date: new Date().toISOString().split('T')[0],
    end_date: '',
  });

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    const [targetsData, outletsData, productsData, categoriesData] = await Promise.all([
      supabase.from('sales_targets').select(`
        *,
        outlet:outlets(name),
        product:products(name),
        category:categories(name)
      `).order('start_date', { ascending: false }),
      supabase.from('outlets').select('*').eq('is_active', true),
      supabase.from('products').select('*').eq('is_active', true),
      supabase.from('categories').select('*'),
    ]);

    setTargets(targetsData.data || []);
    setOutlets(outletsData.data || []);
    setProducts(productsData.data || []);
    setCategories(categoriesData.data || []);
    setLoading(false);
  };

  const handleSubmit = async () => {
    try {
      const { error } = await supabase
        .from('sales_targets')
        .insert({
          ...formData,
          product_id: formData.target_type === 'product' ? formData.product_id : null,
          category_id: formData.target_type === 'category' ? formData.category_id : null,
        });

      if (error) throw error;

      alert('Target berhasil dibuat!');
      setShowModal(false);
      fetchData();
      resetForm();
    } catch (error) {
      console.error('Error creating target:', error);
      alert('Gagal membuat target');
    }
  };

  const resetForm = () => {
    setFormData({
      outlet_id: '',
      target_type: 'product',
      target_period: 'daily',
      product_id: '',
      category_id: '',
      target_amount: 0,
      incentive_type: 'fixed',
      incentive_value: 0,
      start_date: new Date().toISOString().split('T')[0],
      end_date: '',
    });
  };

  const deleteTarget = async (id: string) => {
    if (!confirm('Hapus target ini?')) return;

    try {
      const { error } = await supabase
        .from('sales_targets')
        .delete()
        .eq('id', id);

      if (error) throw error;
      alert('Target berhasil dihapus');
      fetchData();
    } catch (error) {
      console.error('Error deleting target:', error);
      alert('Gagal menghapus target');
    }
  };

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Sales Target & Incentive</h1>
          <p className="text-gray-600">Kelola target penjualan & bonus karyawan</p>
        </div>
        <Button onClick={() => setShowModal(true)}>
          <Plus className="h-4 w-4 mr-2" />
          Tambah Target
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Total Target</p>
                <p className="text-2xl font-bold">{targets.length}</p>
              </div>
              <Target className="h-8 w-8 text-blue-600" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Aktif</p>
                <p className="text-2xl font-bold text-green-600">
                  {targets.filter(t => t.is_active).length}
                </p>
              </div>
              <TrendingUp className="h-8 w-8 text-green-600" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Targets List */}
      <Card>
        <CardHeader>
          <CardTitle>Daftar Target</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="text-center py-8">Loading...</div>
          ) : targets.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              <Target className="h-12 w-12 mx-auto mb-4 text-gray-400" />
              <p>Belum ada target</p>
            </div>
          ) : (
            <div className="space-y-3">
              {targets.map((target) => (
                <div key={target.id} className="p-4 border rounded-lg">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        <Badge>{TARGET_TYPE_LABELS[target.target_type as keyof typeof TARGET_TYPE_LABELS]}</Badge>
                        <Badge variant="outline">{TARGET_PERIOD_LABELS[target.target_period as keyof typeof TARGET_PERIOD_LABELS]}</Badge>
                        <Badge variant={target.is_active ? 'default' : 'secondary'}>
                          {target.is_active ? 'Aktif' : 'Non-Aktif'}
                        </Badge>
                      </div>

                      <p className="font-semibold text-lg">{target.outlet?.name}</p>
                      
                      {target.target_type === 'product' && (
                        <p className="text-sm text-gray-600">Produk: {target.product?.name}</p>
                      )}
                      {target.target_type === 'category' && (
                        <p className="text-sm text-gray-600">Kategori: {target.category?.name}</p>
                      )}
                      
                      <div className="mt-2 grid grid-cols-3 gap-4 text-sm">
                        <div>
                          <span className="text-gray-600">Target:</span>
                          <p className="font-bold text-blue-600">
                            Rp {target.target_amount.toLocaleString('id-ID')}
                          </p>
                        </div>
                        <div>
                          <span className="text-gray-600">Incentive:</span>
                          <p className="font-bold text-green-600">
                            {target.incentive_type === 'percentage' 
                              ? `${target.incentive_value}%` 
                              : `Rp ${target.incentive_value.toLocaleString('id-ID')}`}
                          </p>
                        </div>
                        <div>
                          <span className="text-gray-600">Periode:</span>
                          <p className="font-medium">
                            {new Date(target.start_date).toLocaleDateString('id-ID')} - 
                            {target.end_date ? new Date(target.end_date).toLocaleDateString('id-ID') : 'Ongoing'}
                          </p>
                        </div>
                      </div>
                    </div>

                    <div className="flex gap-2">
                      <Button variant="outline" size="sm">
                        <Edit className="h-3 w-3" />
                      </Button>
                      <Button variant="outline" size="sm" onClick={() => deleteTarget(target.id)}>
                        <Trash2 className="h-3 w-3 text-red-500" />
                      </Button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Create Target Modal */}
      <Dialog open={showModal} onOpenChange={setShowModal}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Buat Target Baru</DialogTitle>
          </DialogHeader>

          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Outlet *</Label>
                <Select
                  value={formData.outlet_id}
                  onValueChange={(value) => setFormData({ ...formData, outlet_id: value })}
                >
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
                <Label>Periode *</Label>
                <Select
                  value={formData.target_period}
                  onValueChange={(value: any) => setFormData({ ...formData, target_period: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="daily">Harian</SelectItem>
                    <SelectItem value="weekly">Mingguan</SelectItem>
                    <SelectItem value="monthly">Bulanan</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div>
              <Label>Tipe Target *</Label>
              <Select
                value={formData.target_type}
                onValueChange={(value: any) => setFormData({ ...formData, target_type: value })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="product">Per Produk</SelectItem>
                  <SelectItem value="category">Per Kategori</SelectItem>
                  <SelectItem value="total_sales">Total Penjualan</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {formData.target_type === 'product' && (
              <div>
                <Label>Produk *</Label>
                <Select
                  value={formData.product_id}
                  onValueChange={(value) => setFormData({ ...formData, product_id: value })}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Pilih produk" />
                  </SelectTrigger>
                  <SelectContent>
                    {products.map(p => (
                      <SelectItem key={p.id} value={p.id}>{p.name}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            )}

            {formData.target_type === 'category' && (
              <div>
                <Label>Kategori *</Label>
                <Select
                  value={formData.category_id}
                  onValueChange={(value) => setFormData({ ...formData, category_id: value })}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Pilih kategori" />
                  </SelectTrigger>
                  <SelectContent>
                    {categories.map(c => (
                      <SelectItem key={c.id} value={c.id}>{c.name}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            )}

            <div>
              <Label>Target Amount (Rp) *</Label>
              <Input
                type="number"
                value={formData.target_amount}
                onChange={(e) => setFormData({ ...formData, target_amount: Number(e.target.value) })}
                min="0"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Tipe Incentive *</Label>
                <Select
                  value={formData.incentive_type}
                  onValueChange={(value: any) => setFormData({ ...formData, incentive_type: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="fixed">Fixed Amount</SelectItem>
                    <SelectItem value="percentage">Percentage</SelectItem>
                    <SelectItem value="tiered">Tiered</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div>
                <Label>Incentive Value *</Label>
                <Input
                  type="number"
                  value={formData.incentive_value}
                  onChange={(e) => setFormData({ ...formData, incentive_value: Number(e.target.value) })}
                  placeholder={formData.incentive_type === 'percentage' ? '5 (%)' : '50000 (Rp)'}
                  min="0"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Start Date *</Label>
                <Input
                  type="date"
                  value={formData.start_date}
                  onChange={(e) => setFormData({ ...formData, start_date: e.target.value })}
                />
              </div>

              <div>
                <Label>End Date (Optional)</Label>
                <Input
                  type="date"
                  value={formData.end_date}
                  onChange={(e) => setFormData({ ...formData, end_date: e.target.value })}
                />
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowModal(false)}>
              Batal
            </Button>
            <Button onClick={handleSubmit}>
              Buat Target
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
