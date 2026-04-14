import { useEffect, useMemo, useState } from 'react';
import MainLayout from '@/components/layout/MainLayout';
import { useAuth } from '@/hooks/useAuth';
import { useOutlet } from '@/hooks/useOutlet';
import { supabase } from '@/integrations/supabase/client';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { CreditCard, Plus, Search, RefreshCw } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useToast } from '@/hooks/use-toast';
import { formatCurrency, formatDateTime } from '@/lib/utils';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import type { PaymentMethod } from '@/types/database';

type PaymentStatus = 'paid' | 'partial' | 'pending' | 'refunded';

interface PaymentRow {
  id: string;
  transaction_id: string;
  payment_method: PaymentMethod;
  amount: number;
  payment_date: string;
  reference_number: string | null;
  bank_name: string | null;
  notes: string | null;
  transaction?: {
    transaction_number: string;
    total: number;
    total_paid: number | null;
    remaining_amount: number | null;
    payment_status: PaymentStatus | null;
  };
}

interface InvoiceRow {
  id: string;
  transaction_number: string;
  total: number;
  payment_status: PaymentStatus;
  status: string;
  created_at: string;
  notes: string | null;
}

export default function Payments() {
  const { user } = useAuth();
  const { selectedOutlet } = useOutlet();
  const { toast } = useToast();
  const [payments, setPayments] = useState<PaymentRow[]>([]);
  const [invoices, setInvoices] = useState<InvoiceRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [showDialog, setShowDialog] = useState(false);
  const [processing, setProcessing] = useState(false);
  const [selectedTransactionId, setSelectedTransactionId] = useState('');
  const [paymentForm, setPaymentForm] = useState({
    paymentMethod: 'cash' as PaymentMethod,
    amount: '',
    referenceNumber: '',
    bankName: '',
    cardNumberLast4: '',
    notes: '',
  });

  useEffect(() => {
    if (selectedOutlet) {
      void fetchData();
    }
  }, [selectedOutlet]);

  const fetchData = async () => {
    if (!selectedOutlet) return;

    setLoading(true);
    try {
      const [paymentRes, invoiceRes] = await Promise.all([
        (supabase as any)
          .from('transaction_payments')
          .select('id, transaction_id, payment_method, amount, payment_date, reference_number, bank_name, notes, transaction:transactions(transaction_number, total, total_paid, remaining_amount, payment_status)')
          .order('payment_date', { ascending: false })
          .limit(50),
        (supabase as any)
          .from('transactions')
          .select('id, transaction_number, total, payment_status, status, created_at, notes')
          .eq('outlet_id', selectedOutlet.id)
          .ilike('transaction_number', 'INV-%')
          .order('created_at', { ascending: false })
          .limit(25),
      ]);

      if (paymentRes.error) throw paymentRes.error;
      if (invoiceRes.error) throw invoiceRes.error;

      setPayments((paymentRes.data || []) as PaymentRow[]);
      setInvoices((invoiceRes.data || []) as InvoiceRow[]);
    } catch (error: any) {
      console.error('Failed to load payment data:', error);
      toast({ title: 'Error', description: error.message || 'Gagal memuat data pembayaran', variant: 'destructive' });
    } finally {
      setLoading(false);
    }
  };

  const openPaymentDialog = () => {
    setPaymentForm({
      paymentMethod: 'cash',
      amount: '',
      referenceNumber: '',
      bankName: '',
      cardNumberLast4: '',
      notes: '',
    });
    setSelectedTransactionId('');
    setShowDialog(true);
  };

  const availableTransactions = useMemo(() => {
    return invoices.filter((invoice) => Number(invoice.total) > 0 && invoice.payment_status !== 'paid');
  }, [invoices]);

  const selectedTransaction = useMemo(() => {
    return availableTransactions.find((invoice) => invoice.id === selectedTransactionId) || null;
  }, [availableTransactions, selectedTransactionId]);

  const getPaymentBadge = (status: PaymentStatus | null | undefined) => {
    const classes: Record<PaymentStatus, string> = {
      paid: 'bg-emerald-100 text-emerald-800 border-emerald-300',
      partial: 'bg-amber-100 text-amber-800 border-amber-300',
      pending: 'bg-slate-100 text-slate-700 border-slate-300',
      refunded: 'bg-rose-100 text-rose-800 border-rose-300',
    };
    const value = status || 'pending';
    return <Badge variant="outline" className={classes[value]}>{value.toUpperCase()}</Badge>;
  };

  const handleSubmitPayment = async () => {
    if (!selectedOutlet || !user) return;
    if (!selectedTransactionId) {
      toast({ title: 'Error', description: 'Pilih invoice / transaksi dulu', variant: 'destructive' });
      return;
    }

    const amount = Number(paymentForm.amount);
    if (!amount || amount <= 0) {
      toast({ title: 'Error', description: 'Nominal pembayaran harus lebih dari 0', variant: 'destructive' });
      return;
    }

    setProcessing(true);
    try {
      const payload: Record<string, unknown> = {
        transaction_id: selectedTransactionId,
        payment_method: paymentForm.paymentMethod,
        amount,
        reference_number: paymentForm.referenceNumber || null,
        bank_name: paymentForm.bankName || null,
        card_number_last4: paymentForm.cardNumberLast4 || null,
        notes: paymentForm.notes || null,
        created_by: user.id,
      };

      const { error } = await (supabase as any).from('transaction_payments').insert(payload);
      if (error) throw error;

      toast({ title: 'Berhasil', description: 'Pembayaran berhasil dicatat' });
      setShowDialog(false);
      await fetchData();
    } catch (error: any) {
      console.error('Failed to save payment:', error);
      toast({ title: 'Error', description: error.message || 'Gagal menyimpan pembayaran', variant: 'destructive' });
    } finally {
      setProcessing(false);
    }
  };

  const filteredPayments = payments.filter((payment) => {
    const query = searchQuery.toLowerCase();
    return (
      payment.transaction?.transaction_number?.toLowerCase().includes(query) ||
      payment.reference_number?.toLowerCase().includes(query) ||
      payment.bank_name?.toLowerCase().includes(query)
    );
  });

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
              <CreditCard className="h-6 w-6" /> Payment Entry
            </h1>
            <p className="text-muted-foreground">Catat penerimaan pembayaran dari Klien</p>
          </div>
          <Button onClick={openPaymentDialog}>
            <Plus className="h-4 w-4 mr-2" />
            Terima Pembayaran
          </Button>
        </div>

        <Card>
          <CardHeader>
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
              <div>
                <CardTitle>Riwayat Pembayaran</CardTitle>
                <CardDescription>Penerimaan DP, Termin, dan Pelunasan Catering.</CardDescription>
              </div>
              <div className="flex items-center gap-3">
                <div className="relative w-full md:w-72">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder="Cari invoice / referensi..."
                    className="pl-10"
                  />
                </div>
                <Button variant="outline" onClick={fetchData} disabled={loading}>
                  <RefreshCw className="h-4 w-4 mr-2" />
                  Refresh
                </Button>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Waktu</TableHead>
                    <TableHead>Invoice / Transaksi</TableHead>
                    <TableHead>Metode</TableHead>
                    <TableHead>Referensi</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead className="text-right">Nominal</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredPayments.map((payment) => (
                    <TableRow key={payment.id}>
                      <TableCell>{formatDateTime(payment.payment_date)}</TableCell>
                      <TableCell className="font-mono text-xs">{payment.transaction?.transaction_number || payment.transaction_id}</TableCell>
                      <TableCell>{payment.payment_method.toUpperCase()}</TableCell>
                      <TableCell>{payment.reference_number || payment.bank_name || '-'}</TableCell>
                      <TableCell>{getPaymentBadge(payment.transaction?.payment_status)}</TableCell>
                      <TableCell className="text-right font-semibold">{formatCurrency(Number(payment.amount))}</TableCell>
                    </TableRow>
                  ))}
                  {filteredPayments.length === 0 && (
                    <TableRow>
                      <TableCell colSpan={6} className="py-12 text-center text-muted-foreground">
                        Belum ada riwayat pembayaran yang di-entry.
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            </div>
          </CardContent>
        </Card>
      </div>

      <Dialog open={showDialog} onOpenChange={setShowDialog}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>Terima Pembayaran</DialogTitle>
          </DialogHeader>

          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Invoice / Transaksi</Label>
              <Select value={selectedTransactionId} onValueChange={setSelectedTransactionId}>
                <SelectTrigger>
                  <SelectValue placeholder="Pilih invoice yang belum lunas" />
                </SelectTrigger>
                <SelectContent>
                  {availableTransactions.map((invoice) => (
                    <SelectItem key={invoice.id} value={invoice.id}>
                      {invoice.transaction_number} - sisa {formatCurrency(Number(invoice.remaining_amount ?? invoice.total))}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Metode</Label>
                <Select value={paymentForm.paymentMethod} onValueChange={(value) => setPaymentForm((prev) => ({ ...prev, paymentMethod: value as PaymentMethod }))}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="cash">Cash</SelectItem>
                    <SelectItem value="qris">QRIS</SelectItem>
                    <SelectItem value="transfer">Transfer</SelectItem>
                    <SelectItem value="card">Card</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Nominal</Label>
                <Input value={paymentForm.amount} onChange={(e) => setPaymentForm((prev) => ({ ...prev, amount: e.target.value }))} placeholder="0" type="number" min="0" step="0.01" />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Referensi</Label>
                <Input value={paymentForm.referenceNumber} onChange={(e) => setPaymentForm((prev) => ({ ...prev, referenceNumber: e.target.value }))} placeholder="No. transfer / bukti" />
              </div>
              <div className="space-y-2">
                <Label>Bank</Label>
                <Input value={paymentForm.bankName} onChange={(e) => setPaymentForm((prev) => ({ ...prev, bankName: e.target.value }))} placeholder="BCA / Mandiri / dll" />
              </div>
            </div>

            <div className="space-y-2">
              <Label>No. Kartu terakhir (opsional)</Label>
              <Input value={paymentForm.cardNumberLast4} onChange={(e) => setPaymentForm((prev) => ({ ...prev, cardNumberLast4: e.target.value }))} placeholder="1234" maxLength={4} />
            </div>

            <div className="space-y-2">
              <Label>Catatan</Label>
              <Input value={paymentForm.notes} onChange={(e) => setPaymentForm((prev) => ({ ...prev, notes: e.target.value }))} placeholder="Termin 1 / DP / pelunasan" />
            </div>

            {selectedTransaction && (
              <div className="rounded-lg border bg-muted/40 p-3 text-sm space-y-1">
                <div className="flex justify-between"><span>Invoice</span><span className="font-medium">{selectedTransaction.transaction_number}</span></div>
                <div className="flex justify-between"><span>Total</span><span className="font-medium">{formatCurrency(Number(selectedTransaction.total))}</span></div>
                <div className="flex justify-between"><span>Sisa</span><span className="font-medium">{formatCurrency(Number(selectedTransaction.remaining_amount ?? selectedTransaction.total))}</span></div>
              </div>
            )}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowDialog(false)}>Batal</Button>
            <Button onClick={handleSubmitPayment} disabled={processing}>
              {processing ? 'Menyimpan...' : 'Simpan Pembayaran'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </MainLayout>
  );
}
