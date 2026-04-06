import { Request, Response } from 'express';
import Booking from '../models/booking';
import { verifyAdminCredentials, ADMIN_TOKEN } from '../middleware/auth';

export class AdminController {
    login(req: Request, res: Response) {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ message: 'Email and password are required' });
        }

        if (!verifyAdminCredentials(email, password)) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        return res.status(200).json({ token: ADMIN_TOKEN, user: { email, role: 'admin' } });
    }

    async confirmBooking(req: Request, res: Response) {
        const { bookingId } = req.params;

        try {
            const booking = await Booking.findById(bookingId);
            if (!booking) {
                return res.status(404).json({ message: 'Booking not found' });
            }

            booking.status = 'completed';
            await booking.save();

            return res.status(200).json({ message: 'Booking confirmed', booking });
        } catch (error) {
            return res.status(500).json({ message: 'Error confirming booking', error });
        }
    }

    async getCompletedBookings(req: Request, res: Response) {
        try {
            const completedBookings = await Booking.find({ status: 'completed' });
            return res.status(200).json(completedBookings);
        } catch (error) {
            return res.status(500).json({ message: 'Error retrieving completed bookings', error });
        }
    }
}