export class RefundService {
    private refundAmount: number = 5000;

    public processRefund(bookingId: string): number {
        // Logic to process the refund for the canceled booking
        // This is a placeholder for actual refund processing logic
        console.log(`Processing refund for booking ID: ${bookingId}`);
        return this.refundAmount;
    }
}