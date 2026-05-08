function adminErrorMessage(value, fallback = "Autentificare admin eșuată.") {
    if (!value) return fallback;
    if (typeof value === 'string') return value;
    if (Array.isArray(value)) {
        const messages = value
            .map((item) => adminErrorMessage(item, ''))
            .filter(Boolean);
        return messages.join(' ') || fallback;
    }
    if (typeof value === 'object') {
        if (typeof value.detail === 'string') return value.detail;
        if (value.detail) return adminErrorMessage(value.detail, fallback);
        if (typeof value.message === 'string') return value.message;
        if (typeof value.error === 'string') return value.error;
        if (Array.isArray(value.loc) && typeof value.msg === 'string') {
            return `${value.loc.join('.')}: ${value.msg}`;
        }
        if (typeof value.msg === 'string') return value.msg;
    }
    return fallback;
}

const Auth = {
    login: async (email, password) => {
        const apiBaseUrl = (typeof CONFIG !== 'undefined' && CONFIG.API_BASE_URL) || 'http://127.0.0.1:8000';
        let response;
        try {
            response = await fetch(`${apiBaseUrl}/admin/auth/login`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email, password }),
            });
        } catch (_) {
            throw new Error("Backend-ul admin nu poate fi contactat. Verifică API_BASE_URL și CORS.");
        }
        const data = await response.json().catch(async () => ({ detail: await response.text().catch(() => '') }));
        if (!response.ok) {
            throw new Error(adminErrorMessage(data));
        }
        if (!data.token) {
            throw new Error("Răspuns de autentificare neașteptat.");
        }
        localStorage.setItem('pulse_admin_token', data.token);
        localStorage.setItem('pulse_admin_user', JSON.stringify(data.user || { name: 'Admin User', email, role: 'admin' }));
        return true;
    },
    logout: () => {
        localStorage.removeItem('pulse_admin_token');
        localStorage.removeItem('pulse_admin_user');
        window.location.href = 'login.html';
    },
    isAuthenticated: () => localStorage.getItem('pulse_admin_token') !== null,
    requireAuth: () => { if (!Auth.isAuthenticated()) window.location.href = 'login.html'; },
    getUser: () => {
        const userStr = localStorage.getItem('pulse_admin_user');
        return userStr ? JSON.parse(userStr) : null;
    }
};
