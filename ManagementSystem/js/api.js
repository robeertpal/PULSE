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
            throw new Error(data.detail || data.error || data.message || `Eroare HTTP: ${response.status}`);
        }
        if (data && typeof data === 'object' && data.error) {
            throw new Error(data.error);
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
