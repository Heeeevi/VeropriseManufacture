import { useState, useEffect } from 'react';
import { Plus, Trash2, Send, ArrowRight } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { supabase } from '@/integrations/supabase/client';

interface TransferItem {
  product_id: string;
  product_name: string;
  quantity_requested: number;
  stock_available: number;
}

export function StockTransferForm() {
  const [warehouses, setWarehouses] = useState<any[]>([]);
  const [outlets, setOutlets] = useState<any[]>([]);
  const [products, setProducts] = useState<any[]>([]);
  
  const [fromWarehouse, setFromWarehouse] = useState('');
  const [toOutlet, setToOutlet] = useState('');
  const [expectedDate, setExpectedDate] = useState('');
  const [notes, setNotes] = useState('');
  const [items, setItems] = useState<TransferItem[]>([]);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    const [warehousesData, outletsData, productsData] = await Promise.all([
      supabase.from('warehouses').select('*').eq('is_active', true),
      supabase.from('outlets').select('*').eq('is_active', true),
      supabase.from('products').select('*').eq('is_active', true),
    ]);

    setWarehouses(warehousesData.data || []);
    setOutlets(outletsData.data || []);
    setProducts(productsData.data || []);
  };

  const checkStock = async (warehouseId: string, productId: string) => {
    const { data } = await supabase
      .from('warehouse_inventory')
      .select('quantity')
      .eq('warehouse_id', warehouseId)
      .eq('product_id', productId)
      .single();

    return data?.quantity || 0;
  };

  const addItem = () => {
    setItems([...items, {
      product_id: '',
      product_name: '',
      quantity_requested: 1,
      stock_available: 0,
    }]);
  };

  const removeItem = (index: number) => {
    setItems(items.filter((_, i) => i !== index));
  };

  const updateItem = async (index: number, field: keyof TransferItem, value: any) => {
    const updated = [...items];
    updated[index] = { ...updated[index], [field]: value };
    
    // Update product name and check stock if product_id changes
    if (field === 'product_id' && fromWarehouse) {
      const product = products.find(p => p.id === value);
      updated[index].product_name = product?.name || '';
      updated[index].stock_available = await checkStock(fromWarehouse, value);
    }
    
    setItems(updated);
  };

  const handleSubmit = async () => {
    if (!fromWarehouse || !toOutlet || items.length === 0) {
      alert('Lengkapi form terlebih dahulu');
      return;
    }

    // Validate stock
    const insufficientStock = items.find(item => item.quantity_requested > item.stock_available);
    if (insufficientStock) {
      alert(`Stok ${insufficientStock.product_name} tidak cukup!`);
      return;
    }

    setSaving(true);
    try {
      // Create Transfer Order
      const { data: transfer, error: transferError } = await supabase
        .from('stock_transfer_orders')
        .insert({
          transfer_number: `TRF-${Date.now()}`,
          from_warehouse_id: fromWarehouse,
          to_outlet_id: toOutlet,
          status: 'pending',
          requested_date: new Date().toISOString(),
          expected_delivery_date: expectedDate || null,
          notes,
        })
        .select()
        .single();

      if (transferError) throw transferError;

      // Create Transfer Items
      const itemsToInsert = items.map(item => ({
        transfer_order_id: transfer.id,
        product_id: item.product_id,
        quantity_requested: item.quantity_requested,
      }));

      const { error: itemsError } = await supabase
        .from('stock_transfer_items')
        .insert(itemsToInsert);

      if (itemsError) throw itemsError;

      alert('Request transfer berhasil dibuat! Menunggu approval.');
      
      // Reset form
      setFromWarehouse('');
      setToOutlet('');
      setExpectedDate('');
      setNotes('');
      setItems([]);
    } catch (error) {
      console.error('Error creating transfer:', error);
      alert('Gagal membuat transfer request');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Stock Transfer Request</h1>
        <p className="text-gray-600">Request transfer stok dari gudang ke outlet</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Informasi Transfer</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Dari Gudang *</Label>
                  <Select value={fromWarehouse} onValueChange={setFromWarehouse}>
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
                  <Label>Ke Outlet *</Label>
                  <Select value={toOutlet} onValueChange={setToOutlet}>
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
              </div>

              <div className="flex items-center gap-4 p-4 bg-blue-50 rounded-lg">
                <div className="flex-1 text-center">
                  <p className="text-sm text-gray-600">From</p>
                  <p className="font-bold text-blue-900">
                    {warehouses.find(w => w.id === fromWarehouse)?.name || '-'}
                  </p>
                </div>
                <ArrowRight className="h-6 w-6 text-blue-600" />
                <div className="flex-1 text-center">
                  <p className="text-sm text-gray-600">To</p>
                  <p className="font-bold text-blue-900">
                    {outlets.find(o => o.id === toOutlet)?.name || '-'}
                  </p>
                </div>
              </div>

              <div>
                <Label>Tanggal Pengiriman Diharapkan</Label>
                <Input
                  type="date"
                  value={expectedDate}
                  onChange={(e) => setExpectedDate(e.target.value)}
                />
              </div>

              <div>
                <Label>Catatan</Label>
                <Textarea
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="Alasan transfer, instruksi khusus, dll..."
                  rows={3}
                />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center justify-between">
                <span>Item Transfer</span>
                <Button onClick={addItem} size="sm" disabled={!fromWarehouse}>
                  <Plus className="h-4 w-4 mr-1" />
                  Tambah Item
                </Button>
              </CardTitle>
            </CardHeader>
            <CardContent>
              {!fromWarehouse && (
                <div className="text-center py-8 text-gray-500">
                  <p>Pilih gudang asal terlebih dahulu</p>
                </div>
              )}

              {fromWarehouse && (
                <div className="space-y-4">
                  {items.map((item, index) => (
                    <div key={index} className="p-4 border rounded-lg space-y-3">
                      <div className="flex items-center justify-between">
                        <Badge>Item #{index + 1}</Badge>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => removeItem(index)}
                        >
                          <Trash2 className="h-4 w-4 text-red-500" />
                        </Button>
                      </div>

                      <div className="grid grid-cols-12 gap-3">
                        <div className="col-span-7">
                          <Label>Produk</Label>
                          <Select
                            value={item.product_id}
                            onValueChange={(value) => updateItem(index, 'product_id', value)}
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

                        <div className="col-span-3">
                          <Label>Qty Request</Label>
                          <Input
                            type="number"
                            value={item.quantity_requested}
                            onChange={(e) => updateItem(index, 'quantity_requested', Number(e.target.value))}
                            min="1"
                            max={item.stock_available}
                          />
                        </div>

                        <div className="col-span-2">
                          <Label>Stok</Label>
                          <Input
                            value={item.stock_available}
                            disabled
                            className={item.quantity_requested > item.stock_available ? 'text-red-600' : ''}
                          />
                        </div>
                      </div>

                      {item.quantity_requested > item.stock_available && item.product_id && (
                        <div className="text-xs text-red-600 bg-red-50 p-2 rounded">
                          ⚠️ Stok tidak cukup! Tersedia: {item.stock_available}
                        </div>
                      )}
                    </div>
                  ))}

                  {items.length === 0 && (
                    <div className="text-center py-8 text-gray-500">
                      <p>Belum ada item. Klik "Tambah Item" untuk mulai.</p>
                    </div>
                  )}
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        <div className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Ringkasan</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Total Item</span>
                  <span className="font-semibold">{items.length}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Total Quantity</span>
                  <span className="font-semibold">
                    {items.reduce((sum, item) => sum + item.quantity_requested, 0)}
                  </span>
                </div>
              </div>

              <Button
                className="w-full"
                onClick={handleSubmit}
                disabled={saving || items.length === 0}
              >
                <Send className="h-4 w-4 mr-2" />
                Submit Request
              </Button>
            </CardContent>
          </Card>

          <Card className="bg-yellow-50 border-yellow-200">
            <CardContent className="pt-6">
              <h4 className="font-semibold text-sm mb-2">⚠️ Alur Proses:</h4>
              <ol className="text-xs text-gray-700 space-y-1 list-decimal list-inside">
                <li>Request dibuat (PENDING)</li>
                <li>Admin warehouse approve</li>
                <li>Barang disiapkan (IN_TRANSIT)</li>
                <li>Outlet terima barang (COMPLETED)</li>
                <li>Stok otomatis update</li>
              </ol>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
