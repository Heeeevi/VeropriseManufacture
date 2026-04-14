import { useEffect, useMemo, useState } from 'react';
import MainLayout from '@/components/layout/MainLayout';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { FileText, Plus, Search, RefreshCw } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useAuth } from '@/hooks/useAuth';
import { useOutlet } from '@/hooks/useOutlet';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';
import { formatCurrency, formatDateTime } from '@/lib/utils';
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { jsPDF } from 'jspdf';

type PaymentStatus = 'paid' | 'partial' | 'pending' | 'refunded';
type InvoiceUiStatus = 'pending' | 'approved';

const invoiceUiToDbStatus = (status: InvoiceUiStatus) => (status === 'approved' ? 'completed' : 'pending');
const getInvoiceDisplayStatus = (status: string) => (status === 'completed' ? 'APPROVED' : 'PENDING');
const getPaymentDisplayStatus = (status: PaymentStatus) => {
  switch (status) {
    case 'paid':
      return 'PAID';
    case 'partial':
      return 'PARTIAL';
    case 'refunded':
      return 'REFUNDED';
    default:
      return 'UNPAID';
  }
};

interface InvoiceRow {
  id: string;
  transaction_number: string;
  total: number;
  payment_status: PaymentStatus;
  status: string;
  created_at: string;
  notes: string | null;
  payment_method?: 'cash' | 'qris' | 'transfer' | 'card' | 'split' | null;
}

export default function Invoices() {
  const { user } = useAuth();
  const { selectedOutlet } = useOutlet();
  const { toast } = useToast();
  const [invoices, setInvoices] = useState<InvoiceRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [showDialog, setShowDialog] = useState(false);
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [processing, setProcessing] = useState(false);
  const [editingInvoice, setEditingInvoice] = useState<InvoiceRow | null>(null);
  const [formData, setFormData] = useState({
    customerName: '',
    transactionDate: new Date().toISOString().slice(0, 16),
    amount: '',
    notes: '',
    status: 'pending' as InvoiceUiStatus,
    paymentMethod: 'transfer' as 'cash' | 'qris' | 'transfer' | 'card',
  });

  useEffect(() => {
    if (selectedOutlet) {
      void fetchInvoices();
    }
  }, [selectedOutlet]);

  const fetchInvoices = async () => {
    if (!selectedOutlet) return;

    setLoading(true);
    try {
      const { data, error } = await (supabase as any)
        .from('transactions')
        .select('id, transaction_number, total, payment_status, status, created_at, notes')
        .eq('outlet_id', selectedOutlet.id)
        .ilike('transaction_number', 'INV-%')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setInvoices((data || []) as InvoiceRow[]);
    } catch (error: any) {
      console.error('Failed to load invoices:', error);
      toast({ title: 'Error', description: error.message || 'Gagal memuat invoice', variant: 'destructive' });
    } finally {
      setLoading(false);
    }
  };

  const createInvoice = async () => {
    if (!selectedOutlet || !user) return;

    const amount = Number(formData.amount);
    if (!formData.customerName.trim()) {
      toast({ title: 'Error', description: 'Nama klien wajib diisi', variant: 'destructive' });
      return;
    }
    if (!amount || amount <= 0) {
      toast({ title: 'Error', description: 'Nominal invoice harus lebih dari 0', variant: 'destructive' });
      return;
    }

    setProcessing(true);
    try {
      const now = new Date();
      const dateStr = now.toISOString().slice(0, 10).replace(/-/g, '');
      const timeStr = now.toTimeString().slice(0, 8).replace(/:/g, '');
      const randomStr = Math.random().toString(36).substring(2, 6).toUpperCase();
      const invoiceNumber = `INV-${dateStr}-${timeStr}-${randomStr}`;

      const payload = {
        outlet_id: selectedOutlet.id,
        transaction_number: invoiceNumber,
        transaction_date: new Date(formData.transactionDate).toISOString(),
        subtotal: amount,
        tax: 0,
        discount: 0,
        total: amount,
        status: invoiceUiToDbStatus(formData.status),
        payment_method: formData.paymentMethod,
        payment_status: 'pending',
        payment_details: null,
        notes: `Klipen: ${formData.customerName}${formData.notes ? ` | ${formData.notes}` : ''}`,
        created_by: user.id,
      };

      const { error } = await (supabase as any).from('transactions').insert(payload);
      if (error) throw error;

      toast({ title: 'Berhasil', description: `Invoice ${invoiceNumber} berhasil dibuat` });
      setShowDialog(false);
      setFormData({
        customerName: '',
        transactionDate: new Date().toISOString().slice(0, 16),
        amount: '',
        notes: '',
        status: 'pending',
        paymentMethod: 'transfer',
      });
      await fetchInvoices();
    } catch (error: any) {
      console.error('Failed to create invoice:', error);
      toast({ title: 'Error', description: error.message || 'Gagal membuat invoice', variant: 'destructive' });
    } finally {
      setProcessing(false);
    }
  };

  const openEditDialog = (invoice: InvoiceRow) => {
    setEditingInvoice(invoice);
    setFormData({
      customerName: invoice.notes?.replace(/^Klipen:\s*/i, '').split(' | ')[0] || '',
      transactionDate: invoice.created_at.slice(0, 16),
      amount: String(invoice.total || 0),
      notes: invoice.notes?.includes('|') ? invoice.notes.split(' | ').slice(1).join(' | ') : '',
      status: invoice.status === 'completed' ? 'approved' : 'pending',
      paymentMethod: invoice.payment_method || 'transfer',
    });
    setShowEditDialog(true);
  };

  const updateInvoice = async () => {
    if (!selectedOutlet || !user || !editingInvoice) return;

    const amount = Number(formData.amount);
    if (!formData.customerName.trim()) {
      toast({ title: 'Error', description: 'Nama klien wajib diisi', variant: 'destructive' });
      return;
    }
    if (!amount || amount <= 0) {
      toast({ title: 'Error', description: 'Nominal invoice harus lebih dari 0', variant: 'destructive' });
      return;
    }

    setProcessing(true);
    try {
      const { error } = await (supabase as any)
        .from('transactions')
        .update({
          transaction_date: new Date(formData.transactionDate).toISOString(),
          subtotal: amount,
          tax: 0,
          discount: 0,
          total: amount,
          status: invoiceUiToDbStatus(formData.status),
          payment_method: formData.paymentMethod,
          notes: `Klipen: ${formData.customerName}${formData.notes ? ` | ${formData.notes}` : ''}`,
        })
        .eq('id', editingInvoice.id);

      if (error) throw error;

      toast({ title: 'Berhasil', description: 'Invoice berhasil diperbarui' });
      setShowEditDialog(false);
      setEditingInvoice(null);
      await fetchInvoices();
    } catch (error: any) {
      console.error('Failed to update invoice:', error);
      toast({ title: 'Error', description: error.message || 'Gagal memperbarui invoice', variant: 'destructive' });
    } finally {
      setProcessing(false);
    }
  };

  const approveInvoice = async (invoice: InvoiceRow) => {
    setProcessing(true);
    try {
      const { error } = await (supabase as any)
        .from('transactions')
        .update({ status: 'completed' })
        .eq('id', invoice.id);

      if (error) throw error;

      toast({ title: 'Berhasil', description: `Invoice ${invoice.transaction_number} di-approve` });
      await fetchInvoices();
    } catch (error: any) {
      console.error('Failed to approve invoice:', error);
      toast({ title: 'Error', description: error.message || 'Gagal approve invoice', variant: 'destructive' });
    } finally {
      setProcessing(false);
    }
  };

  const openInvoicePDF = (invoice: InvoiceRow) => {
    const pdf = new jsPDF('p', 'mm', 'a4');
    const pageWidth = pdf.internal.pageSize.getWidth();
    const margin = 15;
    let y = 20;

    pdf.setFont('helvetica', 'bold');
    pdf.setFontSize(18);
    pdf.text('VEROPRISE ERP', margin, y);
    y += 8;
    pdf.setFontSize(12);
    pdf.setFont('helvetica', 'normal');
    pdf.text('Invoice (Outbound)', margin, y);
    y += 10;

    pdf.setFontSize(10);
    pdf.text(`No. Invoice: ${invoice.transaction_number}`, margin, y);
    y += 6;
    pdf.text(`Tanggal: ${formatDateTime(invoice.created_at)}`, margin, y);
    y += 6;
    pdf.text(`Status: ${getInvoiceDisplayStatus(invoice.status)}`, margin, y);
    y += 6;
    pdf.text(`Payment Status: ${getPaymentDisplayStatus(invoice.payment_status)}`, margin, y);
    y += 10;

    pdf.setLineWidth(0.3);
    pdf.line(margin, y, pageWidth - margin, y);
    y += 8;

    pdf.text('Rincian', margin, y);
    y += 8;
    pdf.setFont('helvetica', 'normal');
    pdf.text(`Catatan: ${invoice.notes || '-'}`, margin, y, { maxWidth: pageWidth - margin * 2 });
    y += 12;
    pdf.setFont('helvetica', 'bold');
    pdf.text(`Total: ${formatCurrency(Number(invoice.total))}`, margin, y);
    y += 12;

    pdf.setFont('helvetica', 'normal');
    pdf.text('Invoice ini dibuat dari modul outbound billing Veroprise ERP.', margin, y, { maxWidth: pageWidth - margin * 2 });

    const blob = pdf.output('blob');
    const url = URL.createObjectURL(blob);
    window.open(url, '_blank');
  };

  const filteredInvoices = useMemo(() => {
    const query = searchQuery.toLowerCase();
    return invoices.filter((invoice) => (
      invoice.transaction_number.toLowerCase().includes(query) ||
      invoice.notes?.toLowerCase().includes(query)
    ));
  }, [invoices, searchQuery]);

  const getStatusBadge = (status: PaymentStatus) => {
    const classes: Record<PaymentStatus, string> = {
      paid: 'bg-emerald-100 text-emerald-800 border-emerald-300',
      partial: 'bg-amber-100 text-amber-800 border-amber-300',
      pending: 'bg-slate-100 text-slate-700 border-slate-300',
      refunded: 'bg-rose-100 text-rose-800 border-rose-300',
    };
    return <Badge variant="outline" className={classes[status]}>{status.toUpperCase()}</Badge>;
  };

  const getInvoiceStatusBadge = (status: string) => {
    const normalized = status === 'completed' ? 'approved' : 'pending';
    return normalized === 'approved'
      ? <Badge className="bg-emerald-100 text-emerald-800 border-emerald-300">APPROVED</Badge>
      : <Badge variant="outline" className="bg-slate-100 text-slate-700 border-slate-300">PENDING</Badge>;
  };

  const getPaymentStatusBadge = (status: PaymentStatus) => {
    switch (status) {
      case 'paid':
        return <Badge className="bg-emerald-100 text-emerald-800 border-emerald-300">PAID</Badge>;
      case 'partial':
        return <Badge className="bg-amber-100 text-amber-800 border-amber-300">PARTIAL</Badge>;
      case 'refunded':
        return <Badge className="bg-rose-100 text-rose-800 border-rose-300">REFUNDED</Badge>;
      default:
        return <Badge variant="outline" className="bg-slate-100 text-slate-700 border-slate-300">UNPAID</Badge>;
    }
  };

  if (!selectedOutlet) {
    return (
      <MainLayout>
        <div className="p-6 text-center text-muted-foreground">Pilih outlet terlebih dahulu.</div>
      </MainLayout>
    );
  }

  return (
    <MainLayout>
      <div className="p-6 space-y-6">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold font-display flex items-center gap-2">
              <FileText className="h-6 w-6" /> Invoice (Outbound)
            </h1>
            <p className="text-muted-foreground">Kelola penagihan pembayaran ke klien catering</p>
          </div>
          <Button onClick={() => setShowDialog(true)}>
            <Plus className="h-4 w-4 mr-2" />
            Buat Invoice Baru
          </Button>
        </div>

        <Card>
          <CardHeader>
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
              <div>
                <CardTitle>Daftar Invoice Aktif</CardTitle>
                <CardDescription>Modul penagihan masih dalam tahap dihubungkan dengan Sales Orders.</CardDescription>
              </div>
              <div className="flex items-center gap-3">
                <div className="relative w-full md:w-72">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input
                    placeholder="Cari invoice..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="pl-10"
                  />
                </div>
                <Button variant="outline" onClick={fetchInvoices} disabled={loading}>
                  <RefreshCw className="h-4 w-4 mr-2" />
                  Refresh
                </Button>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>No. Invoice</TableHead>
                  <TableHead>Tanggal</TableHead>
                  <TableHead>Catatan</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Payment</TableHead>
                  <TableHead className="text-right">Total</TableHead>
                  <TableHead className="text-right">Aksi</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredInvoices.map((invoice) => (
                  <TableRow key={invoice.id}>
                    <TableCell className="font-mono text-sm">{invoice.transaction_number}</TableCell>
                    <TableCell>{formatDateTime(invoice.created_at)}</TableCell>
                    <TableCell>{invoice.notes || '-'}</TableCell>
                    <TableCell>{getInvoiceStatusBadge(invoice.status)}</TableCell>
                    <TableCell>{getPaymentStatusBadge(invoice.payment_status)}</TableCell>
                    <TableCell className="text-right font-semibold">{formatCurrency(Number(invoice.total))}</TableCell>
                    <TableCell className="text-right space-x-2">
                      <Button variant="outline" size="sm" onClick={() => openEditDialog(invoice)}>Edit</Button>
                      {invoice.status !== 'completed' && (
                        <Button size="sm" onClick={() => approveInvoice(invoice)} disabled={processing}>Approve</Button>
                      )}
                      <Button variant="secondary" size="sm" onClick={() => openInvoicePDF(invoice)}>PDF</Button>
                    </TableCell>
                  </TableRow>
                ))}
                {filteredInvoices.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={6} className="py-12 text-center text-muted-foreground">
                      Belum ada data Invoice terhutang.
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>

      <Dialog open={showDialog} onOpenChange={setShowDialog}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>Buat Invoice Baru</DialogTitle>
          </DialogHeader>

          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Nama Klien</Label>
              <Input value={formData.customerName} onChange={(e) => setFormData((prev) => ({ ...prev, customerName: e.target.value }))} placeholder="Nama klien / perusahaan" />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Tanggal Invoice</Label>
                <Input type="datetime-local" value={formData.transactionDate} onChange={(e) => setFormData((prev) => ({ ...prev, transactionDate: e.target.value }))} />
              </div>
              <div className="space-y-2">
                <Label>Nominal</Label>
                <Input type="number" min="0" step="0.01" value={formData.amount} onChange={(e) => setFormData((prev) => ({ ...prev, amount: e.target.value }))} placeholder="0" />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Status invoice</Label>
                <Select value={formData.status} onValueChange={(value) => setFormData((prev) => ({ ...prev, status: value as InvoiceUiStatus }))}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="pending">Pending</SelectItem>
                    <SelectItem value="approved">Approved</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Metode rujukan pembayaran</Label>
                <Select value={formData.paymentMethod} onValueChange={(value) => setFormData((prev) => ({ ...prev, paymentMethod: value as 'cash' | 'qris' | 'transfer' | 'card' }))}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="transfer">Transfer</SelectItem>
                    <SelectItem value="cash">Cash</SelectItem>
                    <SelectItem value="qris">QRIS</SelectItem>
                    <SelectItem value="card">Card</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="space-y-2">
              <Label>Catatan</Label>
              <Input value={formData.notes} onChange={(e) => setFormData((prev) => ({ ...prev, notes: e.target.value }))} placeholder="Termin, DP, proyek, dll" />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowDialog(false)}>Batal</Button>
            <Button onClick={createInvoice} disabled={processing}>{processing ? 'Menyimpan...' : 'Simpan Invoice'}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={showEditDialog} onOpenChange={setShowEditDialog}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>Edit Invoice</DialogTitle>
          </DialogHeader>

          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Nama Klien</Label>
              <Input value={formData.customerName} onChange={(e) => setFormData((prev) => ({ ...prev, customerName: e.target.value }))} />
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Tanggal Invoice</Label>
                <Input type="datetime-local" value={formData.transactionDate} onChange={(e) => setFormData((prev) => ({ ...prev, transactionDate: e.target.value }))} />
              </div>
              <div className="space-y-2">
                <Label>Nominal</Label>
                <Input type="number" min="0" step="0.01" value={formData.amount} onChange={(e) => setFormData((prev) => ({ ...prev, amount: e.target.value }))} />
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Status invoice</Label>
                <Select value={formData.status} onValueChange={(value) => setFormData((prev) => ({ ...prev, status: value as InvoiceUiStatus }))}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="pending">Pending</SelectItem>
                    <SelectItem value="approved">Approved</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Metode rujukan pembayaran</Label>
                <Select value={formData.paymentMethod} onValueChange={(value) => setFormData((prev) => ({ ...prev, paymentMethod: value as 'cash' | 'qris' | 'transfer' | 'card' }))}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="transfer">Transfer</SelectItem>
                    <SelectItem value="cash">Cash</SelectItem>
                    <SelectItem value="qris">QRIS</SelectItem>
                    <SelectItem value="card">Card</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
            <div className="space-y-2">
              <Label>Catatan</Label>
              <Input value={formData.notes} onChange={(e) => setFormData((prev) => ({ ...prev, notes: e.target.value }))} />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowEditDialog(false)}>Batal</Button>
            <Button onClick={updateInvoice} disabled={processing}>{processing ? 'Menyimpan...' : 'Simpan Perubahan'}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </MainLayout>
  );
}
