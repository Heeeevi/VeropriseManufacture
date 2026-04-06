import { Router } from 'express';
import { AdminController } from '../controllers/adminController';
import { authenticateAdmin } from '../middleware/auth';

const router = Router();
const adminController = new AdminController();

export function setAdminRoutes(app: Router) {
    app.post('/admin/login', adminController.login);

    // Protected admin actions
    app.post('/admin/confirm/:bookingId', authenticateAdmin, adminController.confirmBooking);
    app.get('/admin/completed', authenticateAdmin, adminController.getCompletedBookings);
}