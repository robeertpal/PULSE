let partners = [];

document.addEventListener('DOMContentLoaded', async () => {
    UI.init('partners', 'Parteneri');
    document.getElementById('partner_logo_url').addEventListener('input', updateLogoPreview);
    await loadPartners();
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

async function loadPartners() {
    const tbody = document.getElementById('partners-table-body');
    try {
        partners = await API.get('/admin/event-partners');
        renderPartners();
    } catch (err) {
        tbody.innerHTML = `<tr><td colspan="4">${escapeHTML(err.message)}</td></tr>`;
    }
}

function renderPartners() {
    const tbody = document.getElementById('partners-table-body');
    tbody.innerHTML = '';

    if (!partners.length) {
        tbody.innerHTML = '<tr><td colspan="4">Nu există parteneri.</td></tr>';
        return;
    }

    partners.forEach(partner => {
        const logo = partner.logo_url
            ? `<img src="${escapeHTML(partner.logo_url)}" alt="${escapeHTML(partner.name)}" style="max-width:80px; max-height:44px; object-fit:contain;">`
            : '-';
        const website = partner.website_url
            ? `<a href="${escapeHTML(partner.website_url)}" target="_blank" rel="noopener">${escapeHTML(partner.website_url)}</a>`
            : '-';

        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td><strong>${escapeHTML(partner.name)}</strong></td>
            <td>${logo}</td>
            <td>${website}</td>
            <td class="table-actions">
                <button type="button" onclick="editPartner(${partner.id})">Edit</button>
                <button type="button" class="delete" onclick="deletePartner(${partner.id})">Șterge</button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

function newPartner() {
    document.getElementById('partner-form').reset();
    document.getElementById('partner_id').value = '';
    setUploadStatus('');
    updateLogoPreview();
    document.getElementById('partner-form-card').style.display = 'block';
    document.getElementById('partner_name').focus();
}

function editPartner(id) {
    const partner = partners.find(item => item.id === id);
    if (!partner) return;

    document.getElementById('partner_id').value = partner.id;
    document.getElementById('partner_name').value = partner.name || '';
    document.getElementById('partner_logo_url').value = partner.logo_url || '';
    document.getElementById('partner_website_url').value = partner.website_url || '';
    setUploadStatus('');
    updateLogoPreview();
    document.getElementById('partner-form-card').style.display = 'block';
    document.getElementById('partner_name').focus();
}

function cancelPartnerEdit() {
    document.getElementById('partner-form-card').style.display = 'none';
}

function updateLogoPreview() {
    const url = valueOrNull('partner_logo_url');
    const preview = document.getElementById('partner_logo_url_preview');
    preview.innerHTML = url ? `<img src="${escapeHTML(url)}" alt="Preview logo">` : '';
}

function setUploadStatus(message, type = '') {
    const status = document.getElementById('partner_logo_url_upload_status');
    status.textContent = message;
    status.className = `upload-status ${type}`.trim();
}

async function uploadPartnerLogo() {
    const file = document.getElementById('partner_logo_file').files[0];
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

        document.getElementById('partner_logo_url').value = data.url;
        updateLogoPreview();
        setUploadStatus('Upload finalizat.', 'success');
    } catch (err) {
        setUploadStatus(err.message, 'error');
        UI.showAlert('alert-msg', 'Eroare upload logo: ' + err.message, 'error');
    }
}

function buildPartnerPayload() {
    const name = valueOrNull('partner_name');
    if (!name) throw new Error('Completați numele partenerului.');
    return {
        name,
        logo_url: valueOrNull('partner_logo_url'),
        website_url: valueOrNull('partner_website_url'),
    };
}

async function savePartner() {
    const id = document.getElementById('partner_id').value;
    try {
        const payload = buildPartnerPayload();
        if (id) {
            await API.put(`/admin/event-partners/${id}`, payload);
            UI.showAlert('alert-msg', 'Partener actualizat cu succes.', 'success');
        } else {
            await API.post('/admin/event-partners', payload);
            UI.showAlert('alert-msg', 'Partener creat cu succes.', 'success');
        }
        cancelPartnerEdit();
        await loadPartners();
    } catch (err) {
        UI.showAlert('alert-msg', 'Eroare: ' + err.message, 'error');
    }
}

async function deletePartner(id) {
    if (!confirm('Ștergeți acest partener? Asocierile cu evenimentele vor fi eliminate.')) return;
    try {
        await API.delete(`/admin/event-partners/${id}`);
        UI.showAlert('alert-msg', 'Partener șters cu succes.', 'success');
        await loadPartners();
    } catch (err) {
        UI.showAlert('alert-msg', 'Eroare la ștergere: ' + err.message, 'error');
    }
}
