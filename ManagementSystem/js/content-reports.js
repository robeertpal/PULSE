document.addEventListener('DOMContentLoaded', () => {
    UI.init('content-reports', 'Raportări conținut');
    document.getElementById('refresh-btn').addEventListener('click', loadContentReports);
    document.getElementById('clear-filters-btn').addEventListener('click', clearFilters);
    ['filter-status', 'filter-reason', 'filter-content-id', 'filter-limit'].forEach((id) => {
        document.getElementById(id).addEventListener('change', loadContentReports);
    });
    loadContentReports();
});

const reasonLabels = {
    medical_inaccuracy: 'Inexactitate medicală',
    outdated_information: 'Informație învechită',
    unsafe_advice: 'Recomandare nesigură',
    spam_or_irrelevant: 'Spam sau irelevant',
    other: 'Alt motiv',
};

const statusLabels = {
    open: 'Open',
    reviewed: 'Reviewed',
    dismissed: 'Dismissed',
    action_taken: 'Action taken',
};

function escapeHtml(value) {
    return String(value ?? '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
}

function formatDate(value) {
    if (!value) return '-';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return '-';
    return date.toLocaleString('ro-RO');
}

function buildQueryString() {
    const params = new URLSearchParams();
    const status = document.getElementById('filter-status').value;
    const reason = document.getElementById('filter-reason').value;
    const contentId = document.getElementById('filter-content-id').value.trim();
    const limit = document.getElementById('filter-limit').value;

    if (status) params.set('status', status);
    if (reason) params.set('reason', reason);
    if (contentId) params.set('content_id', contentId);
    if (limit) params.set('limit', limit);

    const query = params.toString();
    return query ? `?${query}` : '';
}

function setLoadingState() {
    document.getElementById('content-reports-table-body').innerHTML = '<tr><td colspan="7">Se încarcă...</td></tr>';
}

async function loadContentReports() {
    UI.hideAlert('error-msg');
    setLoadingState();

    try {
        const items = await API.get(`/admin/content-reports${buildQueryString()}`);
        renderContentReports(Array.isArray(items) ? items : []);
    } catch (error) {
        UI.showError('error-msg', `Nu am putut încărca raportările: ${error.message}`);
        document.getElementById('content-reports-table-body').innerHTML = '<tr><td colspan="7">Nu am putut încărca datele.</td></tr>';
    }
}

function statusBadge(status) {
    const normalized = status || 'open';
    return `<span class="status-pill status-${escapeHtml(normalized)}">${escapeHtml(statusLabels[normalized] || normalized)}</span>`;
}

function actionButtons(item) {
    if (!item?.id) return '-';
    return `
        <div class="table-actions">
            <button type="button" onclick="updateReportStatus(${Number(item.id)}, 'reviewed')">Reviewed</button>
            <button type="button" onclick="updateReportStatus(${Number(item.id)}, 'dismissed')">Dismiss</button>
            <button type="button" onclick="updateReportStatus(${Number(item.id)}, 'action_taken')">Action taken</button>
        </div>
    `;
}

function renderContentReports(items) {
    const tbody = document.getElementById('content-reports-table-body');
    if (!items.length) {
        tbody.innerHTML = '<tr><td colspan="7">Nu există raportări pentru filtrele curente.</td></tr>';
        return;
    }

    tbody.innerHTML = items.map((item) => `
        <tr>
            <td>${escapeHtml(formatDate(item.created_at))}</td>
            <td>
                <strong>#${escapeHtml(item.content_id ?? '-')}</strong><br>
                <span class="muted">${escapeHtml(item.content_title || '-')}</span>
            </td>
            <td>
                <strong>${escapeHtml(item.reporter_user_id ?? '-')}</strong><br>
                <span class="muted">${escapeHtml(item.reporter_email || '-')}</span>
            </td>
            <td>${escapeHtml(reasonLabels[item.reason] || item.reason || '-')}</td>
            <td><div class="report-details">${escapeHtml(item.details || '-')}</div></td>
            <td>${statusBadge(item.status)}</td>
            <td>${actionButtons(item)}</td>
        </tr>
    `).join('');
}

async function updateReportStatus(reportId, status) {
    if (!reportId || !status) return;
    const note = prompt('Notă admin opțională:', '');
    if (note === null) return;

    UI.hideAlert('error-msg');
    try {
        await API.patch(`/admin/content-reports/${reportId}`, {
            status,
            admin_note: note.trim() || null,
        });
        await loadContentReports();
    } catch (error) {
        UI.showError('error-msg', `Nu am putut actualiza raportarea: ${error.message}`);
    }
}

function clearFilters() {
    document.getElementById('filter-status').value = '';
    document.getElementById('filter-reason').value = '';
    document.getElementById('filter-content-id').value = '';
    document.getElementById('filter-limit').value = '100';
    loadContentReports();
}
