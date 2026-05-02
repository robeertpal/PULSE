const AD_PLACEMENTS = [
    'home_top',
    'home_between_sections',
    'home_after_news',
    'home_after_publications',
    'home_after_events',
    'home_after_courses',
    'news_feed',
    'publications_feed',
    'events_feed',
    'courses_feed',
    'article_detail',
    'publication_detail',
    'event_detail',
    'course_detail',
];

let allAds = [];

document.addEventListener('DOMContentLoaded', () => {
    UI.init('ads', 'Reclame');
    fillPlacementFilter();
    loadAds();

    document.getElementById('search-input').addEventListener('input', debounce(renderAds, 300));
    document.getElementById('status-filter').addEventListener('change', renderAds);
    document.getElementById('type-filter').addEventListener('change', renderAds);
    document.getElementById('placement-filter').addEventListener('change', renderAds);
});

function fillPlacementFilter() {
    const select = document.getElementById('placement-filter');
    AD_PLACEMENTS.forEach(placement => {
        const option = document.createElement('option');
        option.value = placement;
        option.textContent = placement;
        select.appendChild(option);
    });
}

async function loadAds() {
    const errorMsg = document.getElementById('error-msg');
    const tbody = document.getElementById('ads-table-body');

    try {
        errorMsg.style.display = 'none';
        tbody.innerHTML = '<tr><td colspan="11">Se încarcă...</td></tr>';
        allAds = await API.get('/admin/ads');
        renderAds();
    } catch (err) {
        errorMsg.textContent = 'Eroare la încărcarea reclamelor: ' + err.message;
        errorMsg.style.display = 'block';
        tbody.innerHTML = '<tr><td colspan="11">Nu s-au putut încărca reclamele.</td></tr>';
    }
}

function renderAds() {
    const tbody = document.getElementById('ads-table-body');
    const searchTerm = document.getElementById('search-input').value.trim().toLowerCase();
    const statusFilter = document.getElementById('status-filter').value;
    const typeFilter = document.getElementById('type-filter').value;
    const placementFilter = document.getElementById('placement-filter').value;

    const filtered = allAds.filter(ad => {
        const matchesSearch = !searchTerm || (ad.title || '').toLowerCase().includes(searchTerm);
        const matchesStatus = !statusFilter || ad.status === statusFilter;
        const matchesType = !typeFilter || ad.ad_type === typeFilter;
        const matchesPlacement = !placementFilter || ad.placement === placementFilter;
        return matchesSearch && matchesStatus && matchesType && matchesPlacement;
    });

    tbody.innerHTML = '';

    if (filtered.length === 0) {
        tbody.innerHTML = '<tr><td colspan="11">Nu s-au găsit reclame.</td></tr>';
        return;
    }

    filtered.forEach(ad => {
        const tr = document.createElement('tr');
        const templateLabel = ad.template_name || ad.template_code || '-';
        const relatedLabel = ad.related_content_title
            ? `${escapeHtml(ad.related_content_title)} <span class="muted">(${escapeHtml(ad.related_content_type || '')})</span>`
            : '-';

        tr.innerHTML = `
            <td><strong>${escapeHtml(ad.title || '-')}</strong></td>
            <td><span class="badge" style="background:#E2E8F0; color:#475569;">${escapeHtml(ad.ad_type || '-')}</span></td>
            <td><span class="badge ${escapeHtml(ad.status || '')}">${escapeHtml(ad.status || '-')}</span></td>
            <td>${escapeHtml(ad.placement || '-')}</td>
            <td>${escapeHtml(templateLabel)}</td>
            <td>${Number.isFinite(Number(ad.priority)) ? ad.priority : 0}</td>
            <td>${formatDate(ad.starts_at)}</td>
            <td>${formatDate(ad.ends_at)}</td>
            <td>${ad.is_active ? 'Da' : 'Nu'}</td>
            <td>${relatedLabel}</td>
            <td class="table-actions">
                <button onclick="editAd(${ad.id})">Edit</button>
                <button onclick="archiveAd(${ad.id})">Arhivează</button>
                <button class="delete" onclick="deleteAd(${ad.id})">Șterge</button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

function formatDate(value) {
    if (!value) return '-';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return '-';
    return date.toLocaleString('ro-RO', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
    });
}

function editAd(id) {
    window.location.href = `ad-form.html?id=${id}`;
}

async function archiveAd(id) {
    if (!confirm('Sigur doriți să arhivați această reclamă?')) return;
    try {
        await API.patch(`/admin/ads/${id}/archive`, {});
        await loadAds();
    } catch (err) {
        alert(err.message);
    }
}

async function deleteAd(id) {
    if (!confirm('Sigur doriți să ștergeți această reclamă? Va fi făcut soft delete.')) return;
    try {
        await API.delete(`/admin/ads/${id}`);
        await loadAds();
    } catch (err) {
        alert(err.message);
    }
}

function escapeHtml(value) {
    return String(value ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        clearTimeout(timeout);
        timeout = setTimeout(() => func(...args), wait);
    };
}
