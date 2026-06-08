document.addEventListener('DOMContentLoaded', () => {
    UI.init('contributor-analytics', 'Analytics contributori');
    document.getElementById('refresh-btn').addEventListener('click', loadContributorAnalytics);
    loadContributorAnalytics();
});

const statusIds = {
    total_submissions: 'stat-total',
    draft: 'stat-draft',
    submitted: 'stat-submitted',
    approved: 'stat-approved',
    needs_changes: 'stat-needs-changes',
    published: 'stat-published',
    rejected: 'stat-rejected',
};

const contentTypeLabels = {
    article: 'Articol',
    news: 'Stire',
    course: 'Curs',
    event: 'Eveniment',
    publication: 'Publicatie',
};

function escapeHtml(value) {
    return String(value ?? '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
}

function formatNumber(value) {
    return Number(value || 0).toLocaleString('ro-RO');
}

function formatDate(value) {
    if (!value) return '-';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return '-';
    return date.toLocaleString('ro-RO');
}

function setLoadingState() {
    Object.values(statusIds).forEach((id) => {
        document.getElementById(id).textContent = '-';
    });
    document.getElementById('contributors-table-body').innerHTML = '<tr><td colspan="6">Se incarca...</td></tr>';
    document.getElementById('categories-table-body').innerHTML = '<tr><td colspan="2">Se incarca...</td></tr>';
    document.getElementById('specializations-table-body').innerHTML = '<tr><td colspan="2">Se incarca...</td></tr>';
    document.getElementById('top-content-table-body').innerHTML = '<tr><td colspan="7">Se incarca...</td></tr>';
}

async function loadContributorAnalytics() {
    UI.hideAlert('error-msg');
    setLoadingState();

    try {
        const data = await API.get('/admin/contributor-analytics');
        renderTotals(data.totals || {});
        renderContributors(data.contributors || []);
        renderSimpleCountTable(
            'categories-table-body',
            data.categories || [],
            'name',
            'total_submissions',
            'Nu exista submissions cu categorie.'
        );
        renderSimpleCountTable(
            'specializations-table-body',
            data.specializations || [],
            'name',
            'total_submissions',
            'Nu exista submissions cu specializare.'
        );
        renderTopContent(data.top_content || []);
    } catch (error) {
        UI.showError('error-msg', `Nu am putut incarca analytics: ${error.message}`);
        document.getElementById('contributors-table-body').innerHTML = '<tr><td colspan="6">Nu am putut incarca datele.</td></tr>';
        document.getElementById('categories-table-body').innerHTML = '<tr><td colspan="2">-</td></tr>';
        document.getElementById('specializations-table-body').innerHTML = '<tr><td colspan="2">-</td></tr>';
        document.getElementById('top-content-table-body').innerHTML = '<tr><td colspan="7">-</td></tr>';
    }
}

function renderTotals(totals) {
    Object.entries(statusIds).forEach(([key, id]) => {
        const value = key === 'submitted'
            ? Number(totals.submitted || 0) + Number(totals.under_review || 0)
            : totals[key];
        document.getElementById(id).textContent = formatNumber(value);
    });
}

function renderContributors(items) {
    const tbody = document.getElementById('contributors-table-body');
    if (!items.length) {
        tbody.innerHTML = '<tr><td colspan="6">Nu exista contributori inca.</td></tr>';
        return;
    }

    tbody.innerHTML = items.map((item) => `
        <tr>
            <td><strong>${escapeHtml(item.name || '-')}</strong></td>
            <td>${escapeHtml(item.email || '-')}</td>
            <td>${formatNumber(item.total_submissions)}</td>
            <td>${formatNumber(item.submitted_or_reviewable)}</td>
            <td>${formatNumber(item.published)}</td>
            <td>${escapeHtml(formatDate(item.last_activity_at))}</td>
        </tr>
    `).join('');
}

function renderSimpleCountTable(tableBodyId, items, labelKey, countKey, emptyText) {
    const tbody = document.getElementById(tableBodyId);
    if (!items.length) {
        tbody.innerHTML = `<tr><td colspan="2">${escapeHtml(emptyText)}</td></tr>`;
        return;
    }

    tbody.innerHTML = items.map((item) => `
        <tr>
            <td>${escapeHtml(item[labelKey] || '-')}</td>
            <td>${formatNumber(item[countKey])}</td>
        </tr>
    `).join('');
}

function renderTopContent(items) {
    const tbody = document.getElementById('top-content-table-body');
    if (!items.length) {
        tbody.innerHTML = '<tr><td colspan="7">Nu exista inca activitate pentru content publicat din submissions.</td></tr>';
        return;
    }

    tbody.innerHTML = items.map((item) => `
        <tr>
            <td><strong>${escapeHtml(item.title || '-')}</strong></td>
            <td>${escapeHtml(contentTypeLabels[item.content_type] || item.content_type || '-')}</td>
            <td>${escapeHtml(item.submitter_name || '-')}</td>
            <td>${formatNumber(item.view_count)}</td>
            <td>${formatNumber(item.saved_count)}</td>
            <td>${formatNumber(item.activity_count)}</td>
            <td>${formatNumber(item.score)}</td>
        </tr>
    `).join('');
}
