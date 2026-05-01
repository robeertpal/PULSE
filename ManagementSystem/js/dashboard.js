document.addEventListener('DOMContentLoaded', async () => {
    UI.init('dashboard', 'Dashboard');

    const errorMsg = document.getElementById('error-msg');
    
    try {
        const data = await API.get('/admin/dashboard/stats');
        
        document.getElementById('stat-articles').textContent = data.stats.articles;
        document.getElementById('stat-news').textContent = data.stats.news;
        document.getElementById('stat-courses').textContent = data.stats.courses;
        document.getElementById('stat-events').textContent = data.stats.events;
        document.getElementById('stat-publications').textContent = data.stats.publications;
        document.getElementById('stat-users').textContent = data.stats.users;

        const tbody = document.getElementById('recent-table-body');
        tbody.innerHTML = '';
        
        if (data.recent_content.length === 0) {
            tbody.innerHTML = '<tr><td colspan="4">Nu există conținut recent.</td></tr>';
            return;
        }

        data.recent_content.forEach(item => {
            const tr = document.createElement('tr');
            const dateStr = item.published_at ? new Date(item.published_at).toLocaleDateString('ro-RO') : '-';
            
            tr.innerHTML = `
                <td><strong>${item.title}</strong></td>
                <td><span class="badge" style="background:#E2E8F0; color:#475569;">${item.content_type}</span></td>
                <td><span class="badge ${item.status}">${item.status}</span></td>
                <td>${dateStr}</td>
            `;
            tbody.appendChild(tr);
        });

    } catch (err) {
        errorMsg.textContent = 'Eroare la încărcarea datelor: ' + err.message;
        errorMsg.style.display = 'block';
    }
});
