import { useState, useEffect } from 'react';
import { Plus, Trash2, Save, Send } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { supabase } from '@/integrations/supabase/client';

interface POItem {
  product_id: string;
  product_name: string;
  quantity: number;
  unit_price: number;
  subtotal: number;
}

export function PurchaseOrderForm() {
  const [warehouses, setWarehouses] = useState<any[]>([]);
  const [suppliers, setSuppliers] = useState<any[]>([]);
  const [products, setProducts] = useState<any[]>([]);
  
  const [selectedWarehouse, setSelectedWarehouse] = useState('');
  const [selectedSupplier, setSelectedSupplier] = useState('');
  const [expectedDate, setExpectedDate] = useState('');
  const [notes, setNotes] = useState('');
  const [items, setItems] = useState<POItem[]>([]);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    const [warehousesData, suppliersData, productsData] = await Promise.all([
      supabase.from('warehouses').select('*').eq('is_active', true),
      supabase.from('suppliers').select('*').eq('is_active', true),
      supabase.from('products').select('*').eq('is_active', true),
    ]);

    setWarehouses(warehousesData.data || []);
    setSuppliers(suppliersData.data || []);
    setProducts(productsData.data || []);
  };

  const addItem = () => {
    setItems([...items, {
      product_id: '',
      product_name: '',
      quantity: 1,
      unit_price: 0,
      subtotal: 0,
    }]);
  };

  const removeItem = (index: number) => {
    setItems(items.filter((_, i) => i !== index));
  };

  const updateItem = (index: number, field: keyof POItem, value: any) => {
    const updated = [...items];
    updated[index] = { ...updated[index], [field]: value };
    
    // Update product name if product_id changes
    if (field === 'product_id') {
      const product = products.find(p => p.id === value);
      updated[index].product_name = product?.name || '';
      updated[index].unit_price = product?.purchase_price || 0;
    }
    
    // Recalculate subtotal
    updated[index].subtotal = updated[index].quantity * updated[index].unit_price;
    
    setItems(updated);
  };

  const totalAmount = items.reduce((sum, item) => sum + item.subtotal, 0);

  const handleSave = async (status: 'draft' | 'submitted') => {
    if (!selectedWarehouse || !selectedSupplier || items.length === 0) {
      alert('Lengkapi form terlebih dahulu');
      return;
    }

    setSaving(true);
    try {
      // Create PO
      const { data: po, error: poError } = await supabase
        .from('purchase_orders')
        .insert({
          warehouse_id: selectedWarehouse,
          supplier_id: selectedSupplier,
          po_number: `PO-${Date.now()}`, // Generate unique number
          total_amount: totalAmount,
          status,
          expected_delivery_date: expectedDate || null,
          notes,
        })
        .select()
        .single();

      if (poError) throw poError;

      // Create PO Items
      const itemsToInsert = items.map(item => ({
        purchase_order_id: po.id,
        product_id: item.product_id,
        quantity_ordered: item.quantity,
        unit_price: item.unit_price,
        subtotal: item.subtotal,
      }));

      const { error: itemsError } = await supabase
        .from('purchase_order_items')
        .insert(itemsToInsert);

      if (itemsError) throw itemsError;

      alert(`PO berhasil ${status === 'draft' ? 'disimpan sebagai draft' : 'disubmit'}!`);
      
      // Reset form
      setSelectedWarehouse('');
      setSelectedSupplier('');
      setExpectedDate('');
      setNotes('');
      setItems([]);
    } catch (error) {
      console.error('Error saving PO:', error);
      alert('Gagal menyimpan PO');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Purchase Order Baru</h1>
        <p className="text-gray-600">Buat pesanan pembelian ke supplier</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Form Section */}
        <div className="lg:col-span-2 space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Informasi PO</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Gudang Tujuan *</Label>
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
                  <Label>Supplier *</Label>
                  <Select value={selectedSupplier} onValueChange={setSelectedSupplier}>
                    <SelectTrigger>
                      <SelectValue placeholder="Pilih supplier" />
                    </SelectTrigger>
                    <SelectContent>
                      {suppliers.map(s => (
                        <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
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
                  placeholder="Catatan tambahan untuk PO ini..."
                  rows={3}
                />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center justify-between">
                <span>Item Pesanan</span>
                <Button onClick={addItem} size="sm">
                  <Plus className="h-4 w-4 mr-1" />
                  Tambah Item
                </Button>
              </CardTitle>
            </CardHeader>
            <CardContent>
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
                      <div className="col-span-5">
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

                      <div className="col-span-2">
                        <Label>Qty</Label>
                        <Input
                          type="number"
                          value={item.quantity}
                          onChange={(e) => updateItem(index, 'quantity', Number(e.target.value))}
                          min="1"
                        />
                      </div>

                      <div className="col-span-2">
                        <Label>Harga</Label>
                        <Input
                          type="number"
                          value={item.unit_price}
                          onChange={(e) => updateItem(index, 'unit_price', Number(e.target.value))}
                          min="0"
                        />
                      </div>

                      <div className="col-span-3">
                        <Label>Subtotal</Label>
                        <Input
                          value={`Rp ${item.subtotal.toLocaleString('id-ID')}`}
                          disabled
                          className="font-bold"
                        />
                      </div>
                    </div>
                  </div>
                ))}

                {items.length === 0 && (
                  <div className="text-center py-8 text-gray-500">
                    <p>Belum ada item. Klik "Tambah Item" untuk mulai.</p>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Summary Section */}
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
                    {items.reduce((sum, item) => sum + item.quantity, 0)}
                  </span>
                </div>
                <div className="border-t pt-2 flex justify-between">
                  <span className="font-semibold">Total Amount</span>
                  <span className="text-lg font-bold text-blue-600">
                    Rp {totalAmount.toLocaleString('id-ID')}
                  </span>
                </div>
              </div>

              <div className="space-y-2">
                <Button
                  className="w-full"
                  onClick={() => handleSave('submitted')}
                  disabled={saving || items.length === 0}
                >
                  <Send className="h-4 w-4 mr-2" />
                  Submit PO
                </Button>
                <Button
                  variant="outline"
                  className="w-full"
                  onClick={() => handleSave('draft')}
                  disabled={saving || items.length === 0}
                >
                  <Save className="h-4 w-4 mr-2" />
                  Simpan Draft
                </Button>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-blue-50 border-blue-200">
            <CardContent className="pt-6">
              <h4 className="font-semibold text-sm mb-2">💡 Catatan:</h4>
              <ul className="text-xs text-gray-700 space-y-1">
                <li>• Draft bisa diedit lagi nanti</li>
                <li>• Submit PO butuh approval</li>
                <li>• Setelah approved, barang bisa diterima</li>
                <li>• Stok otomatis update saat receive</li>
              </ul>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
