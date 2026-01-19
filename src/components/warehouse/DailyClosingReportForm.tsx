import { useState, useEffect } from 'react';
import { jsPDF } from 'jspdf';
import { Save, Send, DollarSign, TrendingDown, Banknote, Printer } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { supabase } from '@/integrations/supabase/client';

interface DailySales {
  cash: number;
  qris: number;
  transfer: number;
  olshop: number;
  cards: number;
  total: number;
}

export function DailyClosingReportForm() {
  const [outlets, setOutlets] = useState<any[]>([]);
  const [selectedOutlet, setSelectedOutlet] = useState('');
  const [reportDate, setReportDate] = useState(new Date().toISOString().split('T')[0]);
  const [sales, setSales] = useState<DailySales>({
    cash: 0,
    qris: 0,
    transfer: 0,
    olshop: 0,
    cards: 0,
    total: 0,
  });
  const [totalExpenses, setTotalExpenses] = useState(0);
  const [cashDeposit, setCashDeposit] = useState(0);
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    fetchOutlets();
  }, []);

  useEffect(() => {
    if (selectedOutlet && reportDate) {
      loadDailyData();
    }
  }, [selectedOutlet, reportDate]);

  useEffect(() => {
    // Calculate cash deposit: Cash Sales - Expenses
    const calculated = sales.cash - totalExpenses;
    setCashDeposit(calculated);
  }, [sales.cash, totalExpenses]);

  const fetchOutlets = async () => {
    const { data } = await supabase
      .from('outlets')
      .select('*')
      .eq('is_active', true);
    setOutlets(data || []);
  };

  const loadDailyData = async () => {
    setLoading(true);
    try {
      const startDate = `${reportDate}T00:00:00`;
      const endDate = `${reportDate}T23:59:59`;

      // Fetch sales by payment method
      const { data: salesData } = await supabase
        .from('transaction_payments')
        .select(`
          payment_method,
          amount,
          transactions!inner(outlet_id, transaction_date)
        `)
        .eq('transactions.outlet_id', selectedOutlet)
        .gte('transactions.transaction_date', startDate)
        .lte('transactions.transaction_date', endDate);

      // Group by payment method
      const salesByMethod: DailySales = {
        cash: 0,
        qris: 0,
        transfer: 0,
        olshop: 0,
        cards: 0,
        total: 0,
      };

      (salesData || []).forEach(payment => {
        const amount = payment.amount;
        salesByMethod.total += amount;

        switch (payment.payment_method) {
          case 'cash':
            salesByMethod.cash += amount;
            break;
          case 'qris':
            salesByMethod.qris += amount;
            break;
          case 'transfer':
            salesByMethod.transfer += amount;
            break;
          case 'olshop':
            salesByMethod.olshop += amount;
            break;
          case 'debit_card':
          case 'credit_card':
            salesByMethod.cards += amount;
            break;
        }
      });

      setSales(salesByMethod);

      // Fetch total expenses
      const { data: expensesData } = await supabase
        .from('expenses')
        .select('amount')
        .eq('outlet_id', selectedOutlet)
        .gte('expense_date', startDate)
        .lte('expense_date', endDate);

      const totalExp = (expensesData || []).reduce((sum, exp) => sum + exp.amount, 0);
      setTotalExpenses(totalExp);

    } catch (error) {
      console.error('Error loading daily data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (status: 'draft' | 'submitted') => {
    if (!selectedOutlet) {
      alert('Pilih outlet terlebih dahulu');
      return;
    }

    setSaving(true);
    try {
      const { error } = await supabase
        .from('daily_closing_reports')
        .insert({
          outlet_id: selectedOutlet,
          report_number: `DCR-${Date.now()}`,
          report_date: reportDate,
          cash_sales: sales.cash,
          qris_sales: sales.qris,
          transfer_sales: sales.transfer,
          olshop_sales: sales.olshop,
          card_sales: sales.cards,
          total_sales: sales.total,
          total_expenses: totalExpenses,
          cash_to_deposit: cashDeposit,
          status,
          notes,
        });

      if (error) throw error;

      alert(`Laporan berhasil ${status === 'draft' ? 'disimpan' : 'disubmit'}!`);

      // Reset
      setNotes('');
    } catch (error) {
      console.error('Error saving report:', error);
      alert('Gagal menyimpan laporan');
    } finally {
      setSaving(false);
    }
  };

  // Print daily closing report as PDF
  const handlePrintReport = () => {
    if (!selectedOutlet) return;

    const outlet = outlets.find(o => o.id === selectedOutlet);
    const outletName = outlet?.name || 'Outlet';

    // Create PDF document (A4 size)
    const pdf = new jsPDF({
      orientation: 'portrait',
      unit: 'mm',
      format: 'a4',
    });

    const pageWidth = pdf.internal.pageSize.getWidth();
    let y = 20;

    // Helper function to format currency
    const formatRp = (amount: number) => `Rp ${amount.toLocaleString('id-ID')}`;

    // Title
    pdf.setFontSize(18);
    pdf.setFont('helvetica', 'bold');
    pdf.text('LAPORAN PENUTUPAN HARIAN', pageWidth / 2, y, { align: 'center' });
    y += 10;

    // Outlet info
    pdf.setFontSize(12);
    pdf.setFont('helvetica', 'normal');
    pdf.text(outletName, pageWidth / 2, y, { align: 'center' });
    y += 15;

    // Report details
    pdf.setFontSize(10);
    pdf.text(`Tanggal: ${new Date(reportDate).toLocaleDateString('id-ID', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}`, 20, y);
    y += 8;
    pdf.text(`Dicetak: ${new Date().toLocaleString('id-ID')}`, 20, y);
    y += 12;

    // Divider
    pdf.setDrawColor(200);
    pdf.line(20, y, pageWidth - 20, y);
    y += 10;

    // Sales breakdown header
    pdf.setFontSize(12);
    pdf.setFont('helvetica', 'bold');
    pdf.text('PENJUALAN PER METODE PEMBAYARAN', 20, y);
    y += 10;

    // Sales breakdown table
    pdf.setFontSize(10);
    pdf.setFont('helvetica', 'normal');
    const salesItems = [
      ['Cash', formatRp(sales.cash)],
      ['QRIS', formatRp(sales.qris)],
      ['Transfer', formatRp(sales.transfer)],
      ['Olshop', formatRp(sales.olshop)],
      ['Kartu (Debit/Credit)', formatRp(sales.cards)],
    ];

    salesItems.forEach(([label, value]) => {
      pdf.text(label, 25, y);
      pdf.text(value, pageWidth - 25, y, { align: 'right' });
      y += 7;
    });

    // Total sales
    y += 3;
    pdf.setFont('helvetica', 'bold');
    pdf.text('Total Penjualan', 25, y);
    pdf.text(formatRp(sales.total), pageWidth - 25, y, { align: 'right' });
    y += 12;

    // Divider
    pdf.line(20, y, pageWidth - 20, y);
    y += 10;

    // Expenses
    pdf.setFontSize(12);
    pdf.text('PENGELUARAN', 20, y);
    y += 10;
    pdf.setFontSize(10);
    pdf.setFont('helvetica', 'normal');
    pdf.text('Total Pengeluaran', 25, y);
    pdf.text(formatRp(totalExpenses), pageWidth - 25, y, { align: 'right' });
    y += 12;

    // Divider
    pdf.line(20, y, pageWidth - 20, y);
    y += 10;

    // Cash deposit calculation
    pdf.setFontSize(12);
    pdf.setFont('helvetica', 'bold');
    pdf.text('SETORAN KAS', 20, y);
    y += 10;
    pdf.setFontSize(10);
    pdf.setFont('helvetica', 'normal');
    pdf.text('Penjualan Cash', 25, y);
    pdf.text(formatRp(sales.cash), pageWidth - 25, y, { align: 'right' });
    y += 7;
    pdf.text('Dikurangi Pengeluaran', 25, y);
    pdf.text(`- ${formatRp(totalExpenses)}`, pageWidth - 25, y, { align: 'right' });
    y += 7;
    pdf.setDrawColor(100);
    pdf.line(25, y, pageWidth - 25, y);
    y += 7;
    pdf.setFont('helvetica', 'bold');
    pdf.setFontSize(12);
    pdf.text('Kas yang Harus Disetor', 25, y);
    pdf.text(formatRp(cashDeposit), pageWidth - 25, y, { align: 'right' });
    y += 15;

    // Notes
    if (notes) {
      pdf.setFontSize(10);
      pdf.setFont('helvetica', 'bold');
      pdf.text('Catatan:', 20, y);
      y += 7;
      pdf.setFont('helvetica', 'normal');
      const splitNotes = pdf.splitTextToSize(notes, pageWidth - 45);
      pdf.text(splitNotes, 25, y);
      y += splitNotes.length * 5 + 10;
    }

    // Footer
    y = pdf.internal.pageSize.getHeight() - 30;
    pdf.setFontSize(8);
    pdf.setFont('helvetica', 'italic');
    pdf.text('Dokumen ini digenerate secara otomatis oleh Veroprise ERP', pageWidth / 2, y, { align: 'center' });

    // Open PDF in new tab
    const pdfBlob = pdf.output('blob');
    const pdfUrl = URL.createObjectURL(pdfBlob);
    window.open(pdfUrl, '_blank');
  };

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Daily Closing Report</h1>
        <p className="text-gray-600">Laporan penutupan harian & setoran kas</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Informasi Laporan</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Outlet *</Label>
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
                  <Label>Tanggal Laporan</Label>
                  <Input
                    type="date"
                    value={reportDate}
                    onChange={(e) => setReportDate(e.target.value)}
                  />
                </div>
              </div>

              {loading && (
                <div className="text-center py-4 text-gray-500">
                  Loading data...
                </div>
              )}
            </CardContent>
          </Card>

          {selectedOutlet && !loading && (
            <>
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <DollarSign className="h-5 w-5" />
                    Penjualan per Metode Pembayaran
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="grid grid-cols-2 gap-3">
                    <div className="p-3 bg-green-50 rounded-lg">
                      <Label className="text-xs text-gray-600">💵 Cash</Label>
                      <Input
                        value={`Rp ${sales.cash.toLocaleString('id-ID')}`}
                        disabled
                        className="mt-1 font-bold text-green-700 bg-white"
                      />
                    </div>

                    <div className="p-3 bg-blue-50 rounded-lg">
                      <Label className="text-xs text-gray-600">📱 QRIS</Label>
                      <Input
                        value={`Rp ${sales.qris.toLocaleString('id-ID')}`}
                        disabled
                        className="mt-1 font-bold text-blue-700 bg-white"
                      />
                    </div>

                    <div className="p-3 bg-purple-50 rounded-lg">
                      <Label className="text-xs text-gray-600">🏦 Transfer</Label>
                      <Input
                        value={`Rp ${sales.transfer.toLocaleString('id-ID')}`}
                        disabled
                        className="mt-1 font-bold text-purple-700 bg-white"
                      />
                    </div>

                    <div className="p-3 bg-orange-50 rounded-lg">
                      <Label className="text-xs text-gray-600">🛒 Olshop</Label>
                      <Input
                        value={`Rp ${sales.olshop.toLocaleString('id-ID')}`}
                        disabled
                        className="mt-1 font-bold text-orange-700 bg-white"
                      />
                    </div>

                    <div className="p-3 bg-indigo-50 rounded-lg">
                      <Label className="text-xs text-gray-600">💳 Cards</Label>
                      <Input
                        value={`Rp ${sales.cards.toLocaleString('id-ID')}`}
                        disabled
                        className="mt-1 font-bold text-indigo-700 bg-white"
                      />
                    </div>

                    <div className="p-3 bg-gray-800 rounded-lg">
                      <Label className="text-xs text-white">💰 Total Sales</Label>
                      <Input
                        value={`Rp ${sales.total.toLocaleString('id-ID')}`}
                        disabled
                        className="mt-1 font-bold text-white bg-gray-900 border-white"
                      />
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <TrendingDown className="h-5 w-5" />
                    Pengeluaran
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="p-4 bg-red-50 rounded-lg">
                    <Label className="text-sm text-gray-600">Total Pengeluaran Hari Ini</Label>
                    <Input
                      value={`Rp ${totalExpenses.toLocaleString('id-ID')}`}
                      disabled
                      className="mt-2 font-bold text-lg text-red-700 bg-white"
                    />
                  </div>
                </CardContent>
              </Card>

              <Card className="border-2 border-blue-300 bg-blue-50">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2 text-blue-900">
                    <Banknote className="h-5 w-5" />
                    Kas yang Harus Disetor
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="p-4 bg-white rounded-lg space-y-2">
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-600">Penjualan Cash</span>
                      <span className="font-semibold">
                        Rp {sales.cash.toLocaleString('id-ID')}
                      </span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-600">Dikurangi Pengeluaran</span>
                      <span className="font-semibold text-red-600">
                        - Rp {totalExpenses.toLocaleString('id-ID')}
                      </span>
                    </div>
                    <div className="border-t pt-2 flex justify-between">
                      <span className="font-bold text-lg">Setoran Kas</span>
                      <span className="text-2xl font-bold text-blue-600">
                        Rp {cashDeposit.toLocaleString('id-ID')}
                      </span>
                    </div>
                  </div>

                  <div className="text-xs text-blue-800 bg-blue-100 p-3 rounded">
                    <strong>Formula:</strong> Cash Sales - Expenses<br />
                    <span className="text-gray-700">
                      ℹ️ QRIS, Transfer, Olshop, dan Cards tidak termasuk setoran cash
                    </span>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Catatan</CardTitle>
                </CardHeader>
                <CardContent>
                  <Textarea
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    placeholder="Catatan tambahan untuk laporan ini..."
                    rows={4}
                  />
                </CardContent>
              </Card>
            </>
          )}
        </div>

        <div className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Actions</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <Button
                className="w-full"
                onClick={() => handleSave('submitted')}
                disabled={saving || !selectedOutlet}
              >
                <Send className="h-4 w-4 mr-2" />
                Submit Laporan
              </Button>

              <Button
                variant="outline"
                className="w-full"
                onClick={() => handleSave('draft')}
                disabled={saving || !selectedOutlet}
              >
                <Save className="h-4 w-4 mr-2" />
                Simpan Draft
              </Button>

              <Button
                variant="secondary"
                className="w-full"
                onClick={handlePrintReport}
                disabled={!selectedOutlet || loading}
              >
                <Printer className="h-4 w-4 mr-2" />
                Print Laporan
              </Button>
            </CardContent>
          </Card>

          <Card className="bg-yellow-50 border-yellow-200">
            <CardContent className="pt-6">
              <h4 className="font-semibold text-sm mb-2">⚠️ Penting:</h4>
              <ul className="text-xs text-gray-700 space-y-1">
                <li>• Pastikan semua transaksi sudah diinput</li>
                <li>• Hitung cash fisik sebelum submit</li>
                <li>• Setelah submit, butuh approval</li>
                <li>• Approved = finalize, tidak bisa edit</li>
              </ul>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
