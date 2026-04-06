type BookingStatus = 'pending' | 'completed' | 'canceled' | 'booked';
type PaymentStatus = 'paid' | 'refunded' | 'not_paid';

export interface BookingProps {
    id?: string;
    userId: string;
    slot: Date | string;
    status?: BookingStatus;
    paymentStatus?: PaymentStatus;
}

export default class Booking {
    private static store: Booking[] = [];
    public id: string;
    public userId: string;
    public slot: Date;
    public status: BookingStatus;
    public paymentStatus: PaymentStatus;

    constructor({ id, userId, slot, status = 'pending', paymentStatus = 'not_paid' }: BookingProps) {
        this.id = id || Math.random().toString(36).slice(2);
        this.userId = userId;
        this.slot = new Date(slot);
        this.status = status;
        this.paymentStatus = paymentStatus;
    }

    static async find(filter: Partial<BookingProps> = {}) {
        const keys = Object.keys(filter) as (keyof BookingProps)[];
        return Booking.store.filter((b) => {
            return keys.every((k) => (filter as any)[k] === (b as any)[k]);
        });
    }

    static async findById(id: string) {
        return Booking.store.find((b) => b.id === id) || null;
    }

    async save() {
        const existingIndex = Booking.store.findIndex((b) => b.id === this.id);
        if (existingIndex >= 0) {
            Booking.store[existingIndex] = this;
        } else {
            Booking.store.push(this);
        }
        return this;
    }
}