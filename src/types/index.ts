export interface Booking {
    id: string;
    userId: string;
    slot: Date;
    status: 'booked' | 'completed' | 'canceled';
    paymentStatus: 'paid' | 'refunded' | 'pending';
}

export interface User {
    id: string;
    name: string;
    email: string;
    password: string;
}