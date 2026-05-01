document.addEventListener('DOMContentLoaded', () => {
    UI.init('content', 'Toate Articolele & Conținutul');
    loadContent();

    document.getElementById('search-input').addEventListener('input', debounce(loadContent, 500));
    document.getElementById('type-filter').addEventListener('change', loadContent);
    document.getElementById('status-filter').addEventListener('change', loadContent);
});

let allContent = [];

async function loadContent() {
    const errorMsg = document.getElementById('error-msg');
    const tbody = document.getElementById('content-table-body');
    
    try {
        if (allContent.length === 0) {
            allContent = await API.get('/admin/content-items');
        }

        const searchTerm = document.getElementById('search-input').value.toLowerCase();
        const typeFilter = document.getElementById('type-filter').value;
        const statusFilter = document.getElementById('status-filter').value;

        let filtered = allContent.filter(item => {
            const matchesSearch = item.title.toLowerCase().includes(searchTerm);
            const matchesType = typeFilter ? item.content_type === typeFilter : true;
            const matchesStatus = statusFilter ? item.status === statusFilter : true;
            return matchesSearch && matchesType && matchesStatus;
        });

        tbody.innerHTML = '';

        if (filtered.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6">Nu s-au găsit rezultate.</td></tr>';
            return;
        }

        filtered.forEach(item => {
            const tr = document.createElement('tr');
            const dateStr = item.published_at ? new Date(item.published_at).toLocaleDateString('ro-RO') : '-';
            
            tr.innerHTML = `
                <td><strong>${item.title}</strong></td>
                <td><span class="badge" style="background:#E2E8F0; color:#475569;">${item.content_type}</span></td>
                <td>${item.category_name || item.category?.name || '-'}</td>
                <td><span class="badge ${item.status}">${item.status}</span></td>
                <td>${dateStr}</td>
                <td class="table-actions">
                    <button onclick="editContent(${item.id})">Edit</button>
                    <button onclick="archiveContent(${item.id})">Arhivează</button>
                    <button class="delete" onclick="deleteContent(${item.id})">Șterge</button>
                </td>
            `;
            tbody.appendChild(tr);
        });

    } catch (err) {
        errorMsg.textContent = 'Eroare la încărcarea datelor: ' + err.message;
        errorMsg.style.display = 'block';
    }
}

function editContent(id) {
    window.location.href = `content-form.html?id=${id}`;
}

async function archiveContent(id) {
    if (!confirm('Sigur doriți să arhivați acest conținut?')) return;
    try {
        await API.patch(`/admin/content-items/${id}/archive`, {});
        allContent = []; // Force reload
        loadContent();
    } catch (err) {
        alert(err.message);
    }
}

async function deleteContent(id) {
    if (!confirm('ATENȚIE! Sigur doriți să ștergeți definitiv acest conținut?')) return;
    try {
        await API.delete(`/admin/content-items/${id}`);
        allContent = []; // Force reload
        loadContent();
    } catch (err) {
        alert(err.message);
    }
}

function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => { clearTimeout(timeout); func(...args); };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}
