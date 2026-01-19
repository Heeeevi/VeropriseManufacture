import { useState, useEffect } from 'react';
import { Save, AlertCircle } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { supabase } from '@/integrations/supabase/client';

interface OpnameItem {
  product_id: string;
  product_name: string;
  system_quantity: number;
  physical_quantity: number;
  difference: number;
  notes: string;
}

export function StockOpnameForm() {
  const [warehouses, setWarehouses] = useState<any[]>([]);
  const [selectedWarehouse, setSelectedWarehouse] = useState('');
  const [opnameDate, setOpnameDate] = useState(new Date().toISOString().split('T')[0]);
  const [notes, setNotes] = useState('');
  const [items, setItems] = useState<OpnameItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    fetchWarehouses();
  }, []);

  const fetchWarehouses = async () => {
    const { data } = await supabase
      .from('warehouses')
      .select('*')
      .eq('is_active', true);
    setWarehouses(data || []);
  };

  const loadInventory = async () => {
    if (!selectedWarehouse) return;

    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('warehouse_inventory')
        .select(`
          product_id,
          quantity,
          products (name)
        `)
        .eq('warehouse_id', selectedWarehouse);

      if (error) throw error;

      const opnameItems: OpnameItem[] = (data || []).map(item => ({
        product_id: item.product_id,
        product_name: (item.products as any)?.name || '',
        system_quantity: item.quantity,
        physical_quantity: item.quantity, // Default to system
        difference: 0,
        notes: '',
      }));

      setItems(opnameItems);
    } catch (error) {
      console.error('Error loading inventory:', error);
      alert('Gagal load data inventory');
    } finally {
      setLoading(false);
    }
  };

  const updateItem = (index: number, physical: number, itemNotes: string) => {
    const updated = [...items];
    updated[index].physical_quantity = physical;
    updated[index].difference = physical - updated[index].system_quantity;
    updated[index].notes = itemNotes;
    setItems(updated);
  };

  const handleSave = async () => {
    if (!selectedWarehouse || items.length === 0) {
      alert('Lengkapi form terlebih dahulu');
      return;
    }

    setSaving(true);
    try {
      // Create Stock Opname
      const { data: opname, error: opnameError } = await supabase
        .from('stock_opname')
        .insert({
          warehouse_id: selectedWarehouse,
          opname_number: `OPN-${Date.now()}`,
          opname_date: opnameDate,
          status: 'draft',
          notes,
        })
        .select()
        .single();

      if (opnameError) throw opnameError;

      // Create Opname Items
      const itemsToInsert = items.map(item => ({
        stock_opname_id: opname.id,
        product_id: item.product_id,
        system_quantity: item.system_quantity,
        physical_quantity: item.physical_quantity,
        difference: item.difference,
        notes: item.notes,
      }));

      const { error: itemsError } = await supabase
        .from('stock_opname_items')
        .insert(itemsToInsert);

      if (itemsError) throw itemsError;

      alert('Stock opname berhasil disimpan!');
      
      // Reset
      setSelectedWarehouse('');
      setItems([]);
      setNotes('');
    } catch (error) {
      console.error('Error saving opname:', error);
      alert('Gagal menyimpan stock opname');
    } finally {
      setSaving(false);
    }
  };

  const totalDifference = items.reduce((sum, item) => sum + Math.abs(item.difference), 0);
  const itemsWithDifference = items.filter(item => item.difference !== 0);

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Stock Opname</h1>
        <p className="text-gray-600">Pengecekan fisik stok vs sistem</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Informasi Opname</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Gudang *</Label>
                  <Select value={selectedWarehouse} onValueChange={setSelectedWarehouse}>
                    <SelectTrigger>
                      <SelectValue placeholder="Pilih gudang" />
                    </SelectTrigger>
                    <SelectContent>
                      {warehouses.map(w => (
                        <SelectItem key={w.id} value={w.id}>{w.name}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label>Tanggal Opname</Label>
                  <Input
                    type="date"
                    value={opnameDate}
                    onChange={(e) => setOpnameDate(e.target.value)}
                  />
                </div>
              </div>

              <Button
                onClick={loadInventory}
                disabled={!selectedWarehouse || loading}
                className="w-full"
              >
                {loading ? 'Loading...' : 'Load Data Inventory'}
              </Button>

              <div>
                <Label>Catatan Umum</Label>
                <Textarea
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="Catatan untuk opname ini..."
                  rows={2}
                />
              </div>
            </CardContent>
          </Card>

          {items.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Data Opname ({items.length} produk)</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3 max-h-[600px] overflow-y-auto">
                  {items.map((item, index) => (
                    <div
                      key={item.product_id}
                      className={`p-4 border rounded-lg ${
                        item.difference !== 0 ? 'border-orange-300 bg-orange-50' : ''
                      }`}
                    >
                      <div className="flex items-center justify-between mb-3">
                        <div className="flex-1">
                          <p className="font-semibold">{item.product_name}</p>
                          <p className="text-xs text-gray-500">SKU: {item.product_id.slice(0, 8)}</p>
                        </div>
                        {item.difference !== 0 && (
                          <Badge variant={item.difference > 0 ? 'default' : 'destructive'}>
                            {item.difference > 0 ? '+' : ''}{item.difference}
                          </Badge>
                        )}
                      </div>

                      <div className="grid grid-cols-12 gap-3">
                        <div className="col-span-3">
                          <Label className="text-xs">Qty Sistem</Label>
                          <Input
                            value={item.system_quantity}
                            disabled
                            className="bg-gray-100"
                          />
                        </div>

                        <div className="col-span-3">
                          <Label className="text-xs">Qty Fisik *</Label>
                          <Input
                            type="number"
                            value={item.physical_quantity}
                            onChange={(e) => updateItem(index, Number(e.target.value), item.notes)}
                            min="0"
                            className={item.difference !== 0 ? 'border-orange-400' : ''}
                          />
                        </div>

                        <div className="col-span-2">
                          <Label className="text-xs">Selisih</Label>
                          <Input
                            value={item.difference}
                            disabled
                            className={
                              item.difference > 0
                                ? 'text-green-600 font-bold'
                                : item.difference < 0
                                ? 'text-red-600 font-bold'
                                : ''
                            }
                          />
                        </div>

                        <div className="col-span-4">
                          <Label className="text-xs">Catatan</Label>
                          <Input
                            value={item.notes}
                            onChange={(e) => updateItem(index, item.physical_quantity, e.target.value)}
                            placeholder="Alasan selisih..."
                          />
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}
        </div>

        <div className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Ringkasan</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Total Produk</span>
                  <span className="font-semibold">{items.length}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Ada Selisih</span>
                  <span className={`font-semibold ${itemsWithDifference.length > 0 ? 'text-orange-600' : ''}`}>
                    {itemsWithDifference.length}
                  </span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Total Selisih</span>
                  <span className={`font-semibold ${totalDifference > 0 ? 'text-orange-600' : ''}`}>
                    {totalDifference}
                  </span>
                </div>
              </div>

              <Button
                className="w-full"
                onClick={handleSave}
                disabled={saving || items.length === 0}
              >
                <Save className="h-4 w-4 mr-2" />
                Simpan Opname
              </Button>
            </CardContent>
          </Card>

          {itemsWithDifference.length > 0 && (
            <Card className="bg-orange-50 border-orange-200">
              <CardContent className="pt-6">
                <div className="flex items-start gap-2">
                  <AlertCircle className="h-5 w-5 text-orange-600 mt-0.5" />
                  <div>
                    <h4 className="font-semibold text-sm mb-1 text-orange-900">
                      Perhatian!
                    </h4>
                    <p className="text-xs text-orange-800">
                      Ada {itemsWithDifference.length} produk dengan selisih stok. 
                      Pastikan sudah dicatat dengan benar dan tambahkan catatan untuk 
                      setiap selisih.
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          <Card className="bg-blue-50 border-blue-200">
            <CardContent className="pt-6">
              <h4 className="font-semibold text-sm mb-2">📋 Tips:</h4>
              <ul className="text-xs text-gray-700 space-y-1">
                <li>• Hitung fisik dengan teliti</li>
                <li>• Catat alasan jika ada selisih</li>
                <li>• Status draft bisa diedit lagi</li>
                <li>• Setelah finalized, stok akan disesuaikan</li>
              </ul>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
