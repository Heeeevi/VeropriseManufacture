import { Router } from 'express';
import bookingsController from '../controllers/bookingsController';

const router = Router();

export function setBookingsRoutes(app) {
    app.post('/bookings', bookingsController.createBooking.bind(bookingsController));
    app.delete('/bookings/:id', bookingsController.cancelBooking.bind(bookingsController));
    app.get('/bookings', bookingsController.getBookings.bind(bookingsController));
}