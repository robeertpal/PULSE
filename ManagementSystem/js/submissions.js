document.addEventListener('DOMContentLoaded', () => {
    UI.init('submissions', 'Submissions editoriale');
    loadSubmissions();

    document.getElementById('search-input').addEventListener('input', debounce(renderSubmissions, 300));
    document.getElementById('status-filter').addEventListener('change', loadSubmissions);
    document.getElementById('refresh-btn').addEventListener('click', loadSubmissions);
});

let submissions = [];
let selectedSubmission = null;

const statusLabels = {
    draft: 'Draft',
    submitted: 'Trimis',
    under_review: 'In review',
    needs_changes: 'Necesita modificari',
    approved: 'Aprobat',
    published: 'Publicat',
    rejected: 'Respins',
    archived: 'Arhivat',
};

const typeLabels = {
    article: 'Articol',
    news: 'Stire',
    course: 'Curs',
    event: 'Eveniment',
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

function statusBadge(status) {
    return `<span class="badge ${escapeHtml(status)}">${escapeHtml(statusLabels[status] || status)}</span>`;
}

async function loadSubmissions() {
    const tbody = document.getElementById('submissions-table-body');
    const status = document.getElementById('status-filter').value;
    tbody.innerHTML = '<tr><td colspan="6">Se incarca...</td></tr>';
    UI.hideAlert('error-msg');
    UI.hideAlert('success-msg');

    try {
        const endpoint = status ? `/admin/content-submissions?status=${encodeURIComponent(status)}` : '/admin/content-submissions';
        submissions = await API.get(endpoint);
        renderSubmissions();
        if (selectedSubmission) {
            const refreshed = submissions.find(item => item.id === selectedSubmission.id);
            if (refreshed) {
                selectedSubmission = refreshed;
                renderDetail(refreshed);
            }
        }
    } catch (error) {
        UI.showError('error-msg', `Eroare la incarcarea contributiilor: ${error.message}`);
        tbody.innerHTML = '<tr><td colspan="6">Nu am putut incarca datele.</td></tr>';
    }
}

function renderSubmissions() {
    const tbody = document.getElementById('submissions-table-body');
    const search = document.getElementById('search-input').value.trim().toLowerCase();
    const filtered = submissions.filter(item => {
        const haystack = `${item.title || ''} ${item.submitter_name || ''}`.toLowerCase();
        return !search || haystack.includes(search);
    });

    if (filtered.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6">Nu exista contributii pentru filtrul curent.</td></tr>';
        return;
    }

    tbody.innerHTML = '';
    filtered.forEach(item => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td><strong>${escapeHtml(item.title)}</strong></td>
            <td>${escapeHtml(item.submitter_name || '-')}</td>
            <td>${escapeHtml(typeLabels[item.content_type] || item.content_type || '-')}</td>
            <td>${statusBadge(item.status)}</td>
            <td>${formatDate(item.submitted_at || item.updated_at || item.created_at)}</td>
            <td class="table-actions">
                <button type="button" onclick="selectSubmission(${item.id})">Detalii</button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

async function selectSubmission(id) {
    try {
        selectedSubmission = await API.get(`/admin/content-submissions/${id}`);
        renderDetail(selectedSubmission);
    } catch (error) {
        UI.showError('error-msg', `Nu am putut incarca detaliile: ${error.message}`);
    }
}

function detailRow(label, value) {
    return `
        <div class="detail-row">
            <div class="detail-label">${escapeHtml(label)}</div>
            <div class="detail-value">${escapeHtml(value || '-')}</div>
        </div>
    `;
}

function renderDetail(item) {
    const detail = document.getElementById('submission-detail');
    const canReview = ['submitted', 'under_review', 'approved'].includes(item.status);
    const canPublish = item.status === 'approved';
    detail.innerHTML = `
        <h2 style="margin-top:0;">${escapeHtml(item.title)}</h2>
        ${detailRow('Autor', item.submitter_name)}
        ${detailRow('Tip', typeLabels[item.content_type] || item.content_type)}
        ${detailRow('Status', statusLabels[item.status] || item.status)}
        ${detailRow('Categorie', item.category_name)}
        ${detailRow('Specializare', item.specialization_name)}
        ${detailRow('Rezumat', item.summary)}
        ${detailRow('Continut', item.body)}
        ${detailRow('Imagine', item.image_url)}
        ${detailRow('Sursa', item.source_url)}
        ${detailRow('Note review', item.review_notes)}
        ${item.published_content_item_id ? detailRow('Content item publicat', item.published_content_item_id) : ''}
        <div class="submission-actions">
            <button class="btn btn-success" ${canReview ? '' : 'disabled'} onclick="approveSubmission(${item.id})">Aproba</button>
            <button class="btn btn-warning" ${canReview ? '' : 'disabled'} onclick="needsChangesSubmission(${item.id})">Cere modificari</button>
            <button class="btn btn-danger" ${canReview ? '' : 'disabled'} onclick="rejectSubmission(${item.id})">Respinge</button>
            <button class="btn btn-primary" ${canPublish ? '' : 'disabled'} onclick="publishSubmission(${item.id})">Publica</button>
        </div>
    `;
}

async function postReviewAction(id, action, reviewNotes = null) {
    try {
        const body = reviewNotes === null ? {} : { review_notes: reviewNotes };
        const updated = await API.post(`/admin/content-submissions/${id}/${action}`, body);
        selectedSubmission = updated;
        UI.showAlert('success-msg', 'Actiunea a fost salvata.', 'success');
        await loadSubmissions();
        renderDetail(updated);
    } catch (error) {
        UI.showError('error-msg', error.message);
    }
}

function approveSubmission(id) {
    const notes = prompt('Note review optionale:', selectedSubmission?.review_notes || '');
    if (notes === null) return;
    postReviewAction(id, 'approve', notes);
}

function rejectSubmission(id) {
    const notes = prompt('Motiv respingere / note pentru autor:', selectedSubmission?.review_notes || '');
    if (notes === null) return;
    postReviewAction(id, 'reject', notes);
}

function needsChangesSubmission(id) {
    const notes = prompt('Ce modificari sunt necesare?', selectedSubmission?.review_notes || '');
    if (notes === null) return;
    postReviewAction(id, 'needs-changes', notes);
}

function publishSubmission(id) {
    if (!confirm('Publici aceasta contributie in feed-ul public?')) return;
    postReviewAction(id, 'publish');
}

function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}
