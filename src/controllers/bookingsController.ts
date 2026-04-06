import { Request, Response } from 'express';
import Booking from '../models/booking';
import { PaymentService } from '../services/paymentService';
import { RefundService } from '../services/refundService';

class BookingsController {
    private paymentService: PaymentService;
    private refundService: RefundService;

    constructor() {
        this.paymentService = new PaymentService();
        this.refundService = new RefundService();
    }

    async createBooking(req: Request, res: Response) {
    const { userId, slot } = req.body;

        // Process payment
        const paymentOK = await this.paymentService.processPayment(userId, slot);
        if (!paymentOK) return res.status(400).json({ message: 'Payment failed' });

        // Create booking
    const booking = new Booking({ userId, slot, status: 'booked', paymentStatus: 'paid' });
        await booking.save();

        res.status(201).json({ message: 'Booking created', booking });
    }

    async cancelBooking(req: Request, res: Response) {
        const { bookingId } = req.params;

        const booking = await Booking.findById(bookingId);
        if (!booking || booking.status !== 'booked') {
            return res.status(404).json({ message: 'Booking not found or already canceled' });
        }

        // Process refund
    this.refundService.processRefund(booking.id);

        booking.status = 'canceled';
        await booking.save();

        res.status(200).json({ message: 'Booking canceled', booking });
    }

    async getBookings(req: Request, res: Response) {
        const bookings = await Booking.find();
        res.status(200).json(bookings);
    }
}

export default new BookingsController();