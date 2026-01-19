import { useState, useRef, useCallback } from 'react';
import { jsPDF } from 'jspdf';
import html2canvas from 'html2canvas';
import { Printer, Download, X, Eye } from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogFooter,
} from '@/components/ui/dialog';
import { ReceiptTemplate, type ReceiptData } from './ReceiptTemplate';

interface ReceiptPrinterProps {
    data: ReceiptData;
    open: boolean;
    onClose: () => void;
    paperWidth?: 58 | 80;
    autoPrint?: boolean;
}

/**
 * ReceiptPrinter - A component to preview and print/save receipts as PDF
 * Uses jsPDF and html2canvas to generate PDF from the receipt template
 */
export function ReceiptPrinter({
    data,
    open,
    onClose,
    paperWidth = 58,
    autoPrint = false,
}: ReceiptPrinterProps) {
    const receiptRef = useRef<HTMLDivElement>(null);
    const [generating, setGenerating] = useState(false);

    // Generate PDF from receipt template
    const generatePDF = useCallback(async (): Promise<jsPDF | null> => {
        if (!receiptRef.current) return null;

        try {
            // Capture receipt as canvas
            const canvas = await html2canvas(receiptRef.current, {
                scale: 2, // Higher resolution
                backgroundColor: '#ffffff',
                useCORS: true,
                logging: false,
            });

            // Calculate PDF dimensions based on paper width
            // 58mm = 2.28 inches, 80mm = 3.15 inches
            const pdfWidth = paperWidth;
            const pdfHeight = (canvas.height * pdfWidth) / canvas.width;

            // Create PDF with custom page size (in mm)
            const pdf = new jsPDF({
                orientation: 'portrait',
                unit: 'mm',
                format: [pdfWidth, pdfHeight + 10], // Add some margin
            });

            // Add canvas image to PDF
            const imgData = canvas.toDataURL('image/png');
            pdf.addImage(imgData, 'PNG', 0, 5, pdfWidth, pdfHeight);

            return pdf;
        } catch (error) {
            console.error('Error generating PDF:', error);
            return null;
        }
    }, [paperWidth]);

    // Print receipt (opens browser print dialog)
    const handlePrint = useCallback(async () => {
        setGenerating(true);
        try {
            const pdf = await generatePDF();
            if (pdf) {
                // Open PDF in new window for printing
                const pdfBlob = pdf.output('blob');
                const pdfUrl = URL.createObjectURL(pdfBlob);
                const printWindow = window.open(pdfUrl, '_blank');
                if (printWindow) {
                    printWindow.onload = () => {
                        printWindow.print();
                    };
                }
            }
        } finally {
            setGenerating(false);
        }
    }, [generatePDF]);

    // Download receipt as PDF
    const handleDownload = useCallback(async () => {
        setGenerating(true);
        try {
            const pdf = await generatePDF();
            if (pdf) {
                const filename = `Receipt-${data.transactionNumber}.pdf`;
                pdf.save(filename);
            }
        } finally {
            setGenerating(false);
        }
    }, [generatePDF, data.transactionNumber]);

    // Print directly using browser's native print
    const handleBrowserPrint = useCallback(() => {
        if (!receiptRef.current) return;

        const printContent = receiptRef.current.innerHTML;
        const printWindow = window.open('', '_blank');
        if (printWindow) {
            printWindow.document.write(`
        <!DOCTYPE html>
        <html>
          <head>
            <title>Receipt - ${data.transactionNumber}</title>
            <style>
              @page {
                size: ${paperWidth}mm auto;
                margin: 0;
              }
              body {
                margin: 0;
                padding: 0;
                font-family: 'Courier New', Courier, monospace;
              }
              .receipt-content {
                width: ${paperWidth}mm;
                padding: 3mm;
                box-sizing: border-box;
              }
            </style>
          </head>
          <body>
            <div class="receipt-content">
              ${printContent}
            </div>
            <script>
              window.onload = function() {
                window.print();
                window.onafterprint = function() {
                  window.close();
                };
              };
            </script>
          </body>
        </html>
      `);
            printWindow.document.close();
        }
    }, [data.transactionNumber, paperWidth]);

    return (
        <Dialog open={open} onOpenChange={onClose}>
            <DialogContent className="max-w-md">
                <DialogHeader>
                    <DialogTitle className="flex items-center gap-2">
                        <Eye className="h-5 w-5" />
                        Preview Struk
                    </DialogTitle>
                </DialogHeader>

                {/* Receipt Preview */}
                <div className="flex justify-center py-4 bg-gray-100 rounded-lg max-h-[60vh] overflow-auto">
                    <div className="shadow-lg">
                        <ReceiptTemplate ref={receiptRef} data={data} paperWidth={paperWidth} />
                    </div>
                </div>

                <DialogFooter className="flex-col sm:flex-row gap-2">
                    <Button variant="outline" onClick={onClose} className="w-full sm:w-auto">
                        <X className="h-4 w-4 mr-2" />
                        Tutup
                    </Button>
                    <Button
                        variant="outline"
                        onClick={handleDownload}
                        disabled={generating}
                        className="w-full sm:w-auto"
                    >
                        <Download className="h-4 w-4 mr-2" />
                        {generating ? 'Menyimpan...' : 'Simpan PDF'}
                    </Button>
                    <Button
                        onClick={handleBrowserPrint}
                        disabled={generating}
                        className="w-full sm:w-auto"
                    >
                        <Printer className="h-4 w-4 mr-2" />
                        {generating ? 'Memproses...' : 'Print'}
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}

export default ReceiptPrinter;
