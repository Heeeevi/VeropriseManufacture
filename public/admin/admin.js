const loginForm = document.getElementById('login-form');
const statusEl = document.getElementById('login-status');
const dashboard = document.getElementById('dashboard');
const bookingsList = document.getElementById('bookings-list');
const refreshBtn = document.getElementById('refresh');

const TOKEN_KEY = 'admin_token';

async function login(event) {
  event.preventDefault();
  statusEl.textContent = 'Memeriksa...';

  const payload = {
    email: document.getElementById('admin-email').value,
    password: document.getElementById('admin-password').value,
  };

  try {
    const res = await fetch('/admin/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.message || 'Login gagal');

    localStorage.setItem(TOKEN_KEY, data.token);
    statusEl.textContent = 'Login berhasil';
    showDashboard();
    loadCompleted();
  } catch (err) {
    statusEl.textContent = err.message;
    statusEl.style.color = '#f87171';
  }
}

async function loadCompleted() {
  const token = localStorage.getItem(TOKEN_KEY);
  if (!token) return;

  bookingsList.textContent = 'Memuat...';
  try {
    const res = await fetch('/admin/completed', {
      headers: { Authorization: `Bearer ${token}` },
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.message || 'Gagal memuat data');

    if (!data.length) {
      bookingsList.textContent = 'Belum ada booking selesai.';
      return;
    }

    const list = document.createElement('ul');
    list.style.listStyle = 'none';
    list.style.padding = '0';
    data.forEach((b) => {
      const li = document.createElement('li');
      li.style.padding = '12px';
      li.style.border = '1px solid #1e293b';
      li.style.borderRadius = '12px';
      li.style.marginBottom = '10px';
      li.innerHTML = `<strong>${b.userId}</strong> · ${new Date(b.slot).toLocaleString()} · <span style="color:#22c55e">${b.status}</span>`;
      list.appendChild(li);
    });
    bookingsList.innerHTML = '';
    bookingsList.appendChild(list);
  } catch (err) {
    bookingsList.textContent = err.message;
  }
}

function showDashboard() {
  loginForm.style.display = 'none';
  dashboard.style.display = 'block';
}

if (loginForm) loginForm.addEventListener('submit', login);
if (refreshBtn) refreshBtn.addEventListener('click', loadCompleted);

// Auto-login if token exists
if (localStorage.getItem(TOKEN_KEY)) {
  showDashboard();
  loadCompleted();
}
