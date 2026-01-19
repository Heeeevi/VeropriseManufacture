import { useState, useEffect } from 'react';
import { Plus, Edit, Trash2, MapPin, Package } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { supabase } from '@/integrations/supabase/client';
import { Warehouse } from '@/types/warehouse';

export function WarehouseList() {
  const [warehouses, setWarehouses] = useState<Warehouse[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchWarehouses();
  }, []);

  const fetchWarehouses = async () => {
    try {
      const { data, error } = await supabase
        .from('warehouses')
        .select('*')
        .order('name');

      if (error) throw error;
      setWarehouses(data || []);
    } catch (error) {
      console.error('Error fetching warehouses:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="p-6">Loading...</div>;
  }

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Gudang</h1>
          <p className="text-gray-600">Kelola data gudang pusat</p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          Tambah Gudang
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {warehouses.map((warehouse) => (
          <Card key={warehouse.id} className="hover:shadow-lg transition-shadow">
            <CardHeader>
              <CardTitle className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Package className="h-5 w-5 text-blue-600" />
                  {warehouse.name}
                </div>
                <Badge variant={warehouse.is_active ? 'default' : 'secondary'}>
                  {warehouse.is_active ? 'Aktif' : 'Non-Aktif'}
                </Badge>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex items-start gap-2 text-sm">
                <MapPin className="h-4 w-4 mt-0.5 text-gray-500" />
                <p className="text-gray-600 flex-1">{warehouse.address}</p>
              </div>

              {warehouse.phone && (
                <p className="text-sm text-gray-600">📞 {warehouse.phone}</p>
              )}

              {warehouse.manager_name && (
                <div className="pt-2 border-t">
                  <p className="text-xs text-gray-500">Manager</p>
                  <p className="font-medium">{warehouse.manager_name}</p>
                </div>
              )}

              <div className="flex gap-2 pt-3">
                <Button variant="outline" size="sm" className="flex-1">
                  <Edit className="h-3 w-3 mr-1" />
                  Edit
                </Button>
                <Button variant="outline" size="sm" className="flex-1">
                  <Package className="h-3 w-3 mr-1" />
                  Stok
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {warehouses.length === 0 && (
        <Card>
          <CardContent className="py-12 text-center">
            <Package className="h-12 w-12 mx-auto text-gray-400 mb-4" />
            <h3 className="text-lg font-semibold mb-2">Belum ada gudang</h3>
            <p className="text-gray-600 mb-4">Mulai dengan menambahkan gudang pusat</p>
            <Button>
              <Plus className="h-4 w-4 mr-2" />
              Tambah Gudang Pertama
            </Button>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
