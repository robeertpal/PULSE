const UI = {
    formatMessage: (message, fallback = 'A apărut o eroare.') => {
        if (!message) return fallback;
        if (typeof message === 'string') return message;
        if (Array.isArray(message)) {
            const messages = message
                .map((item) => UI.formatMessage(item, ''))
                .filter(Boolean);
            return messages.join(' ') || fallback;
        }
        if (typeof message === 'object') {
            if (typeof message.detail === 'string') return message.detail;
            if (message.detail) return UI.formatMessage(message.detail, fallback);
            if (typeof message.message === 'string') return message.message;
            if (typeof message.error === 'string') return message.error;
            if (Array.isArray(message.loc) && typeof message.msg === 'string') {
                return `${message.loc.join('.')}: ${message.msg}`;
            }
            if (typeof message.msg === 'string') return message.msg;
        }
        return fallback;
    },

    renderSidebar: (activePage) => {
        const sidebarHTML = `
            <div class="sidebar">
                <div class="sidebar-header" style="display: flex; align-items: center; justify-content: center; padding: 24px;">
                    <img src="assets/logo.png" alt="PULSE Logo" style="max-height: 40px; width: auto; object-fit: contain;">
                </div>
                <ul class="nav-links">
                    <li><a href="dashboard.html" class="${activePage === 'dashboard' ? 'active' : ''}">Dashboard</a></li>
                    <li><a href="content.html" class="${activePage === 'content' ? 'active' : ''}">Tot Conținutul</a></li>
                    <li><a href="articles.html" class="${activePage === 'articles' ? 'active' : ''}">Articole</a></li>
                    <li><a href="news.html" class="${activePage === 'news' ? 'active' : ''}">Știri</a></li>
                    <li><a href="courses.html" class="${activePage === 'courses' ? 'active' : ''}">Cursuri</a></li>
                    <li><a href="emc-approvals.html" class="${activePage === 'emc-approvals' ? 'active' : ''}">Aprobări EMC</a></li>
                    <li><a href="events.html" class="${activePage === 'events' ? 'active' : ''}">Evenimente</a></li>
                    <li><a href="partners.html" class="${activePage === 'partners' ? 'active' : ''}">Parteneri</a></li>
                    <li><a href="authors.html" class="${activePage === 'authors' ? 'active' : ''}">Autori</a></li>
                    <li><a href="publications.html" class="${activePage === 'publications' ? 'active' : ''}">Publicații</a></li>
                    <li><a href="subscriptions.html" class="${activePage === 'subscriptions' ? 'active' : ''}">Abonamente</a></li>
                    <li><a href="ads.html" class="${activePage === 'ads' ? 'active' : ''}">Reclame</a></li>
                    <li><a href="notifications.html" class="${activePage === 'notifications' ? 'active' : ''}">Notificări</a></li>
                    <li><a href="content-reports.html" class="${activePage === 'content-reports' ? 'active' : ''}">Raportări conținut</a></li>
                    <li><a href="contributor-analytics.html" class="${activePage === 'contributor-analytics' ? 'active' : ''}">Analytics contributori</a></li>
                    <li><a href="audit-log.html" class="${activePage === 'audit-log' ? 'active' : ''}">Audit log</a></li>
                    <li><a href="users.html" class="${activePage === 'users' ? 'active' : ''}">Utilizatori</a></li>
                </ul>
                <div class="sidebar-footer">
                    <button class="logout-btn" onclick="Auth.logout()">Deconectare</button>
                </div>
            </div>
        `;
        document.body.insertAdjacentHTML('afterbegin', sidebarHTML);
    },

    renderTopbar: (title) => {
        const user = Auth.getUser();
        const userName = user ? user.name : 'Admin';
        const topbarHTML = `
            <div class="topbar">
                <h1>${title}</h1>
                <div class="user-info">Salut, ${userName}</div>
            </div>
        `;
        const mainContent = document.querySelector('.main-content');
        mainContent.insertAdjacentHTML('afterbegin', topbarHTML);
    },

    init: (pageName, pageTitle) => {
        Auth.requireAuth();
        UI.renderSidebar(pageName);
        UI.renderTopbar(pageTitle);
    },

    showAlert: (target, message, type = 'error', options = {}) => {
        const alertBox = typeof target === 'string' ? document.getElementById(target) : target;
        if (!alertBox) return;

        if (alertBox._alertTimeout) {
            clearTimeout(alertBox._alertTimeout);
            alertBox._alertTimeout = null;
        }

        alertBox.textContent = '';
        alertBox.className = `alert ${type}`;
        alertBox.style.display = 'flex';

        const messageNode = document.createElement('span');
        messageNode.className = 'alert-message';
        messageNode.textContent = UI.formatMessage(message);

        const closeButton = document.createElement('button');
        closeButton.type = 'button';
        closeButton.className = 'alert-close';
        closeButton.setAttribute('aria-label', 'Închide mesajul');
        closeButton.textContent = '×';
        closeButton.addEventListener('click', () => UI.hideAlert(alertBox));

        alertBox.append(messageNode, closeButton);

        const autoDismissMs = options.autoDismissMs === undefined ? 5000 : options.autoDismissMs;
        if (type !== 'error' && autoDismissMs) {
            alertBox._alertTimeout = setTimeout(() => UI.hideAlert(alertBox), autoDismissMs);
        }
    },

    showError: (target, message) => {
        UI.showAlert(target, message, 'error');
    },

    hideAlert: (target) => {
        const alertBox = typeof target === 'string' ? document.getElementById(target) : target;
        if (!alertBox) return;

        if (alertBox._alertTimeout) {
            clearTimeout(alertBox._alertTimeout);
            alertBox._alertTimeout = null;
        }

        alertBox.style.display = 'none';
        alertBox.textContent = '';
    }
};
