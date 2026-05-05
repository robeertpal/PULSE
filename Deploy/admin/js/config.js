const DEFAULT_API_BASE_URL = ['localhost', '127.0.0.1'].includes(window.location.hostname)
    ? 'http://127.0.0.1:8000'
    : 'https://pulse-backend-5f9b.onrender.com';

const CONFIG = {
    API_BASE_URL: (window.PULSE_API_BASE_URL || DEFAULT_API_BASE_URL).replace(/\/+$/, ''),
};
