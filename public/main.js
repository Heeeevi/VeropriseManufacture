// Minimal front-end helper for booking form
const slots = [
  '09:00', '10:00', '11:00', '13:00', '14:00', '15:00', '16:00'
];

const slotSelect = document.getElementById('slot');
const bookingForm = document.getElementById('booking-form');
const messageEl = document.getElementById('booking-message');

function renderSlots() {
  slots.forEach((s) => {
    const opt = document.createElement('option');
    opt.value = s;
    opt.textContent = s;
    slotSelect.appendChild(opt);
  });
}

async function submitBooking(event) {
  event.preventDefault();
  messageEl.textContent = 'Memproses pembayaran...';

  const payload = {
    userId: document.getElementById('email').value,
    slot: document.getElementById('slot').value,
    name: document.getElementById('name').value
  };

  try {
    const res = await fetch('/bookings', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    const data = await res.json();
    if (!res.ok) throw new Error(data.message || 'Gagal memesan');

    messageEl.textContent = 'Berhasil! Cek email untuk bukti booking.';
    bookingForm.reset();
  } catch (err) {
    messageEl.textContent = err.message;
    messageEl.style.color = '#f87171';
  }
}

if (slotSelect) renderSlots();
if (bookingForm) bookingForm.addEventListener('submit', submitBooking);
