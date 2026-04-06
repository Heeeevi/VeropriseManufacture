export function validateBookingData(data) {
    const { userId, slot } = data;
    if (!userId || typeof userId !== 'string') {
        return { valid: false, message: 'Invalid user ID' };
    }
    if (!slot || !isValidSlot(slot)) {
        return { valid: false, message: 'Invalid booking slot' };
    }
    return { valid: true };
}

export function validateUserData(data) {
    const { name, email, password } = data;
    if (!name || typeof name !== 'string') {
        return { valid: false, message: 'Invalid name' };
    }
    if (!email || !isValidEmail(email)) {
        return { valid: false, message: 'Invalid email' };
    }
    if (!password || password.length < 6) {
        return { valid: false, message: 'Password must be at least 6 characters long' };
    }
    return { valid: true };
}

function isValidSlot(slot) {
    // Implement logic to check if the slot is valid (e.g., check against booked slots)
    return true; // Placeholder for actual validation logic
}

function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}