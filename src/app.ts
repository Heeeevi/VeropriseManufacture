import express from 'express';
import path from 'path';
import { json } from 'body-parser';
import { setBookingsRoutes } from './routes/bookings';
import { setAdminRoutes } from './routes/admin';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(json());

// Serve public assets for customers and admin UI
const publicDir = path.join(__dirname, '..', 'public');
app.use(express.static(publicDir));

setBookingsRoutes(app);
setAdminRoutes(app);

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});