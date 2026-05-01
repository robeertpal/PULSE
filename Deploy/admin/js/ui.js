const UI = {
    renderSidebar: (activePage) => {
        const sidebarHTML = `
            <div class="sidebar">
                <div class="sidebar-header" style="display: flex; align-items: center; justify-content: center; padding: 24px;">
                    <img src="assets/logo.png" alt="PULSE Logo" style="max-height: 40px; width: auto; object-fit: contain;">
                </div>
                <ul class="nav-links">
                    <li><a href="dashboard.html" class="${activePage === 'dashboard' ? 'active' : ''}">Dashboard</a></li>
                    <li><a href="content.html" class="${activePage === 'content' ? 'active' : ''}">Toate Articolele</a></li>
                    <li><a href="events.html" class="${activePage === 'events' ? 'active' : ''}">Evenimente</a></li>
                    <li><a href="courses.html" class="${activePage === 'courses' ? 'active' : ''}">Cursuri</a></li>
                    <li><a href="publications.html" class="${activePage === 'publications' ? 'active' : ''}">Publicații</a></li>
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
    }
};
