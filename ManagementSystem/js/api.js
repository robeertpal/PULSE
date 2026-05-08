function apiErrorMessage(value, fallback = "Cererea nu a putut fi procesată.") {
    if (!value) return fallback;
    if (typeof value === 'string') return value;
    if (Array.isArray(value)) {
        const messages = value
            .map((item) => apiErrorMessage(item, ''))
            .filter(Boolean);
        return messages.join(' ') || fallback;
    }
    if (typeof value === 'object') {
        if (typeof value.detail === 'string') return value.detail;
        if (value.detail) return apiErrorMessage(value.detail, fallback);
        if (typeof value.error === 'string') return value.error;
        if (value.error) return apiErrorMessage(value.error, fallback);
        if (typeof value.message === 'string') return value.message;
        if (Array.isArray(value.loc) && typeof value.msg === 'string') {
            return `${value.loc.join('.')}: ${value.msg}`;
        }
        if (typeof value.msg === 'string') return value.msg;
    }
    return fallback;
}

async function apiRequest(endpoint, options = {}) {
    const url = `${CONFIG.API_BASE_URL}${endpoint}`;
    const headers = { 'Content-Type': 'application/json', ...options.headers };
    const token = localStorage.getItem('pulse_admin_token');
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const config = { ...options, headers };

    try {
        const response = await fetch(url, config);
        let data;
        const contentType = response.headers.get("content-type");
        if (contentType && contentType.includes("application/json")) {
            data = await response.json();
        } else {
            data = await response.text();
        }

        if (!response.ok) {
            if (response.status === 401 || response.status === 403) {
                localStorage.removeItem('pulse_admin_token');
                localStorage.removeItem('pulse_admin_user');
                if (!window.location.pathname.endsWith('/login.html')) {
                    window.location.href = 'login.html';
                }
            }
            throw new Error(apiErrorMessage(data, `Eroare HTTP: ${response.status}`));
        }
        if (data && typeof data === 'object' && data.error) {
            throw new Error(apiErrorMessage(data.error));
        }
        return data;
    } catch (error) {
        console.error(`Eroare API [${endpoint}]:`, error);
        throw error;
    }
}

const API = {
    get: (endpoint) => apiRequest(endpoint, { method: 'GET' }),
    post: (endpoint, body) => apiRequest(endpoint, { method: 'POST', body: JSON.stringify(body) }),
    put: (endpoint, body) => apiRequest(endpoint, { method: 'PUT', body: JSON.stringify(body) }),
    patch: (endpoint, body) => apiRequest(endpoint, { method: 'PATCH', body: JSON.stringify(body) }),
    delete: (endpoint) => apiRequest(endpoint, { method: 'DELETE' })
};
