document.addEventListener('DOMContentLoaded', () => {
    UI.init('audit-log', 'Audit log');
    document.getElementById('refresh-btn').addEventListener('click', loadAuditLogs);
    document.getElementById('clear-filters-btn').addEventListener('click', clearFilters);
    ['filter-action', 'filter-target-type', 'filter-target-id', 'filter-limit'].forEach((id) => {
        document.getElementById(id).addEventListener('change', loadAuditLogs);
    });
    loadAuditLogs();
});

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

function detailsText(details) {
    if (!details || (typeof details === 'object' && !Object.keys(details).length)) {
        return '-';
    }
    try {
        return JSON.stringify(details, null, 2);
    } catch (_) {
        return String(details);
    }
}

function buildQueryString() {
    const params = new URLSearchParams();
    const action = document.getElementById('filter-action').value.trim();
    const targetType = document.getElementById('filter-target-type').value.trim();
    const targetId = document.getElementById('filter-target-id').value.trim();
    const limit = document.getElementById('filter-limit').value;

    if (action) params.set('action', action);
    if (targetType) params.set('target_type', targetType);
    if (targetId) params.set('target_id', targetId);
    if (limit) params.set('limit', limit);

    const query = params.toString();
    return query ? `?${query}` : '';
}

function setLoadingState() {
    document.getElementById('audit-log-table-body').innerHTML = '<tr><td colspan="5">Se incarca...</td></tr>';
}

async function loadAuditLogs() {
    UI.hideAlert('error-msg');
    setLoadingState();

    try {
        const items = await API.get(`/admin/audit-logs${buildQueryString()}`);
        renderAuditLogs(Array.isArray(items) ? items : []);
    } catch (error) {
        UI.showError('error-msg', `Nu am putut incarca audit log: ${error.message}`);
        document.getElementById('audit-log-table-body').innerHTML = '<tr><td colspan="5">Nu am putut incarca datele.</td></tr>';
    }
}

function renderAuditLogs(items) {
    const tbody = document.getElementById('audit-log-table-body');
    if (!items.length) {
        tbody.innerHTML = '<tr><td colspan="5">Nu exista actiuni in audit log pentru filtrele curente.</td></tr>';
        return;
    }

    tbody.innerHTML = items.map((item) => {
        const target = item.target_type
            ? `${escapeHtml(item.target_type)} #${escapeHtml(item.target_id ?? '-')}`
            : '-';
        return `
            <tr>
                <td>${escapeHtml(formatDate(item.created_at))}</td>
                <td><strong>${escapeHtml(item.action || '-')}</strong></td>
                <td>${target}</td>
                <td>${escapeHtml(item.admin_user_id ?? '-')}</td>
                <td><pre class="audit-details">${escapeHtml(detailsText(item.details))}</pre></td>
            </tr>
        `;
    }).join('');
}

function clearFilters() {
    document.getElementById('filter-action').value = '';
    document.getElementById('filter-target-type').value = '';
    document.getElementById('filter-target-id').value = '';
    document.getElementById('filter-limit').value = '50';
    loadAuditLogs();
}
