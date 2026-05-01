const Auth = {
    login: async (email, password) => {
        return new Promise((resolve, reject) => {
            setTimeout(() => {
                if (email === 'admin@pulse.ro' && password === 'admin') {
                    localStorage.setItem('pulse_admin_token', 'mock_jwt_token_' + Date.now());
                    localStorage.setItem('pulse_admin_user', JSON.stringify({ name: 'Admin User', email, role: 'admin' }));
                    resolve(true);
                } else {
                    reject(new Error("Email sau parolă incorecte. (Folosiți admin@pulse.ro / admin)"));
                }
            }, 500);
        });
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
