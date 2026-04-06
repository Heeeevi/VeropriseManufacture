# Barbershop Booking System

This project is a booking system for a barbershop that allows users to book appointments, manage their bookings, and provides an admin dashboard for managing appointments. The system is designed to be responsive and functional across various devices.

## Features

- **User Booking**: Users can book appointments by selecting available slots. Each booking requires a payment of 10,000 rupiah.
- **Cancellation and Refund**: Users can cancel their bookings and receive a refund of 5,000 rupiah.
- **Admin Dashboard**: Admins can confirm completed bookings and view a list of completed appointments.
- **Responsive Design**: The application is designed to work seamlessly on both desktop and mobile devices.

## Project Structure

```
barbershop-booking
├── src
│   ├── app.ts
│   ├── controllers
│   │   ├── bookingsController.ts
│   │   └── adminController.ts
│   ├── routes
│   │   ├── bookings.ts
│   │   └── admin.ts
│   ├── middleware
│   │   └── auth.ts
│   ├── services
│   │   ├── paymentService.ts
│   │   └── refundService.ts
│   ├── models
│   │   ├── booking.ts
│   │   └── user.ts
│   ├── utils
│   │   └── validators.ts
│   └── types
│       └── index.ts
├── public
│   ├── index.html
│   └── styles.css
├── package.json
├── tsconfig.json
└── README.md
```

## Setup Instructions

1. **Clone the Repository**: 
   ```
   git clone <repository-url>
   cd barbershop-booking
   ```

2. **Install Dependencies**: 
   ```
   npm install
   ```

3. **Run the Application**: 
   ```
   npm start
   ```

4. **Access the Application**: Open your browser and navigate to `http://localhost:3000`.

## Usage Guidelines

- Users can create a booking by selecting an available time slot and making the required payment.
- Bookings can be canceled, and a partial refund will be processed automatically.
- Admins can log in to manage bookings and confirm completed appointments.

## Technologies Used

- Node.js
- Express.js
- TypeScript
- HTML/CSS
- Responsive Design Techniques

## License

This project is licensed under the MIT License.