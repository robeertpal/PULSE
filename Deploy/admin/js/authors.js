let authors = [];

document.addEventListener('DOMContentLoaded', async () => {
    UI.init('authors', 'Autori');
    document.getElementById('author_photo_url').addEventListener('input', updatePhotoPreview);
    document.getElementById('author_search').addEventListener('input', renderAuthors);
    await loadAuthors();
});

function valueOrNull(id) {
    const value = document.getElementById(id).value.trim();
    return value === '' ? null : value;
}

function escapeHTML(value) {
    return String(value ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

function formatDateTime(value) {
    if (!value) return '-';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return value;
    return date.toLocaleString('ro-RO', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
    });
}

function authorFullName(author) {
    return `${author.first_name || ''} ${author.last_name || ''}`.trim();
}

async function loadAuthors() {
    const tbody = document.getElementById('authors-table-body');
    try {
        authors = await API.get('/authors');
        renderAuthors();
    } catch (err) {
        tbody.innerHTML = `<tr><td colspan="5">${escapeHTML(err.message)}</td></tr>`;
    }
}

function filteredAuthors() {
    const query = valueOrNull('author_search')?.toLowerCase();
    if (!query) return authors;
    return authors.filter(author => {
        const fullName = authorFullName(author).toLowerCase();
        return fullName.includes(query)
            || String(author.title || '').toLowerCase().includes(query);
    });
}

function renderAuthors() {
    const tbody = document.getElementById('authors-table-body');
    const visibleAuthors = filteredAuthors();
    tbody.innerHTML = '';

    if (!visibleAuthors.length) {
        tbody.innerHTML = '<tr><td colspan="5">Nu există autori pentru filtrul curent.</td></tr>';
        return;
    }

    visibleAuthors.forEach(author => {
        const photo = author.photo_url
            ? `<img src="${escapeHTML(author.photo_url)}" alt="${escapeHTML(authorFullName(author))}" class="avatar-preview">`
            : `<span class="avatar-fallback">${escapeHTML((author.first_name || author.last_name || 'A')[0])}</span>`;

        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td><strong>${escapeHTML(authorFullName(author))}</strong></td>
            <td>${photo}</td>
            <td>${escapeHTML(author.title || '-')}</td>
            <td>${escapeHTML(formatDateTime(author.created_at))}</td>
            <td class="table-actions">
                <button type="button" onclick="editAuthor(${author.id})">Edit</button>
                <button type="button" class="delete" onclick="deleteAuthor(${author.id})">Șterge</button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

function newAuthor() {
    document.getElementById('author-form').reset();
    document.getElementById('author_id').value = '';
    setUploadStatus('');
    updatePhotoPreview();
    document.getElementById('author-form-card').style.display = 'block';
    document.getElementById('author_first_name').focus();
}

function editAuthor(id) {
    const author = authors.find(item => item.id === id);
    if (!author) return;

    document.getElementById('author_id').value = author.id;
    document.getElementById('author_first_name').value = author.first_name || '';
    document.getElementById('author_last_name').value = author.last_name || '';
    document.getElementById('author_title').value = author.title || '';
    document.getElementById('author_bio').value = author.bio || '';
    document.getElementById('author_photo_url').value = author.photo_url || '';
    setUploadStatus('');
    updatePhotoPreview();
    document.getElementById('author-form-card').style.display = 'block';
    document.getElementById('author_first_name').focus();
}

function cancelAuthorEdit() {
    document.getElementById('author-form-card').style.display = 'none';
}

function updatePhotoPreview() {
    const url = valueOrNull('author_photo_url');
    const preview = document.getElementById('author_photo_url_preview');
    preview.innerHTML = url ? `<img src="${escapeHTML(url)}" alt="Preview fotografie">` : '';
}

function setUploadStatus(message, type = '') {
    const status = document.getElementById('author_photo_url_upload_status');
    status.textContent = message;
    status.className = `upload-status ${type}`.trim();
}

async function uploadAuthorPhoto() {
    const file = document.getElementById('author_photo_file').files[0];
    if (!file) {
        setUploadStatus('Alegeți un fișier înainte de upload.', 'error');
        return;
    }

    const formData = new FormData();
    formData.append('file', file);
    setUploadStatus('Se încarcă...');

    try {
        const headers = {};
        const token = localStorage.getItem('pulse_admin_token');
        if (token) headers.Authorization = `Bearer ${token}`;

        const response = await fetch(`${CONFIG.API_BASE_URL}/admin/uploads/image`, {
            method: 'POST',
            headers,
            body: formData,
        });
        const data = await response.json().catch(() => ({}));
        if (!response.ok) {
            throw new Error(data.detail || data.error || data.message || `Upload eșuat: ${response.status}`);
        }

        document.getElementById('author_photo_url').value = data.url;
        updatePhotoPreview();
        setUploadStatus('Upload finalizat.', 'success');
    } catch (err) {
        setUploadStatus(err.message, 'error');
        UI.showAlert('alert-msg', 'Eroare upload fotografie: ' + err.message, 'error');
    }
}

function buildAuthorPayload() {
    const firstName = valueOrNull('author_first_name');
    const lastName = valueOrNull('author_last_name');
    if (!firstName || !lastName) {
        throw new Error('Completați prenumele și numele autorului.');
    }
    return {
        first_name: firstName,
        last_name: lastName,
        title: valueOrNull('author_title'),
        bio: valueOrNull('author_bio'),
        photo_url: valueOrNull('author_photo_url'),
    };
}

async function saveAuthor() {
    const id = document.getElementById('author_id').value;
    try {
        const payload = buildAuthorPayload();
        if (id) {
            await API.put(`/authors/${id}`, payload);
            UI.showAlert('alert-msg', 'Autor actualizat cu succes.', 'success');
        } else {
            await API.post('/authors', payload);
            UI.showAlert('alert-msg', 'Autor creat cu succes.', 'success');
        }
        cancelAuthorEdit();
        await loadAuthors();
    } catch (err) {
        UI.showAlert('alert-msg', 'Eroare: ' + err.message, 'error');
    }
}

async function deleteAuthor(id) {
    if (!confirm('Ștergeți acest autor? Asocierile cu publicațiile vor fi eliminate.')) return;
    try {
        await API.delete(`/authors/${id}`);
        UI.showAlert('alert-msg', 'Autor șters cu succes.', 'success');
        await loadAuthors();
    } catch (err) {
        UI.showAlert('alert-msg', 'Eroare la ștergere: ' + err.message, 'error');
    }
}
