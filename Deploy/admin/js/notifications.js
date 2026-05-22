const state = {
    notifications: [],
    options: {
        contentItems: [],
        interests: [],
        users: [],
        categories: {
            content: [],
            account: [],
            system: [],
        },
    },
    wizardStep: 1,
    selectedType: 'content',
    creating: false,
    editing: false,
    deleting: false,
    editItem: null,
    deleteItem: null,
    draft: {},
};

const $ = (id) => document.getElementById(id);
const TYPES = {
    content: { label: 'Notificare de conținut', tone: 'content' },
    account: { label: 'Notificare de cont', tone: 'account' },
    system: { label: 'Notificare de sistem', tone: 'system' },
};

document.addEventListener('DOMContentLoaded', () => {
    UI.init('notifications', 'Notificări');
    bindEvents();
    loadNotifications();
});

function bindEvents() {
    $('create-notification-btn').addEventListener('click', openWizard);
    $('refresh-btn').addEventListener('click', loadNotifications);
    $('search-input').addEventListener('input', debounce(loadNotifications, 300));
    $('type-filter').addEventListener('change', loadNotifications);
    $('status-filter').addEventListener('change', loadNotifications);
    $('close-drawer').addEventListener('click', closeDrawer);
    $('close-wizard').addEventListener('click', closeWizard);
    $('wizard-back').addEventListener('click', previousStep);
    $('wizard-next').addEventListener('click', nextStep);
    $('wizard-submit').addEventListener('click', submitNotification);
    $('notification-form').addEventListener('input', renderPreview);
    $('notification-form').addEventListener('change', renderPreview);
    $('close-edit').addEventListener('click', closeEditModal);
    $('cancel-edit').addEventListener('click', closeEditModal);
    $('save-edit').addEventListener('click', saveEdit);
    $('edit-form').addEventListener('input', renderEditPreview);
    $('edit-form').addEventListener('change', renderEditPreview);
    $('cancel-delete').addEventListener('click', closeDeleteModal);
    $('confirm-delete').addEventListener('click', deleteNotification);
}

async function loadNotifications() {
    const tbody = $('notifications-body');
    tbody.innerHTML = '<tr><td colspan="9"><span class="skeleton-line"></span></td></tr>';
    const params = new URLSearchParams();
    const search = $('search-input').value.trim();
    const type = $('type-filter').value;
    const status = $('status-filter').value;
    if (search) params.set('search', search);
    if (type) params.set('notification_type', type);
    if (status) params.set('status', status);

    try {
        state.notifications = await API.get(`/admin/notifications${params.toString() ? `?${params}` : ''}`);
        UI.hideAlert('alert-box');
        renderNotifications();
    } catch (error) {
        UI.showError('alert-box', error.message);
        tbody.innerHTML = '<tr><td colspan="9" class="empty-cell">Notificările nu au putut fi încărcate.</td></tr>';
    }
}

function renderNotifications() {
    const tbody = $('notifications-body');
    $('notifications-count').textContent = `${state.notifications.length} notificări`;
    if (!state.notifications.length) {
        tbody.innerHTML = `
            <tr>
                <td colspan="9" class="empty-cell">
                    <strong>Nu există notificări încă.</strong><br>
                    Creează prima notificare când ești gata să ajungi la utilizatori.
                </td>
            </tr>
        `;
        return;
    }

    tbody.innerHTML = state.notifications.map((item) => `
        <tr>
            <td>
                <strong>${escapeHtml(item.title)}</strong>
                <div class="muted truncate">${escapeHtml(item.description)}</div>
            </td>
            <td>${typeBadge(item.notification_type)}</td>
            <td>${categoryBadge(item)}</td>
            <td>${statusBadge(item.status)}</td>
            <td>${escapeHtml(item.content_item_title || '-')}</td>
            <td>${Number(item.delivered_count || 0)}</td>
            <td>${Number(item.read_count || 0)}</td>
            <td>${formatDate(item.created_at)}</td>
            <td>
                <div class="table-actions">
                    <button class="btn table-btn" onclick="openDetails(${item.id})">Detalii</button>
                    <button class="btn table-btn" onclick="openEditModal(${item.id})">Edit</button>
                    <button class="btn table-btn danger" onclick="openDeleteModal(${item.id})">Șterge</button>
                </div>
            </td>
        </tr>
    `).join('');
}

async function openDetails(id) {
    const drawer = $('details-drawer');
    drawer.classList.add('open');
    drawer.setAttribute('aria-hidden', 'false');
    $('drawer-title').textContent = 'Se încarcă...';
    $('drawer-subtitle').textContent = '';
    $('drawer-content').innerHTML = '<div class="drawer-loading">Se încarcă detaliile notificării...</div>';

    try {
        const item = await API.get(`/admin/notifications/${id}`);
        $('drawer-title').textContent = item.title;
        $('drawer-subtitle').innerHTML = `${typeBadge(item.notification_type)} ${categoryBadge(item)} ${statusBadge(item.status)} <span class="muted">Creată ${formatDate(item.created_at)}</span>`;
        $('drawer-content').innerHTML = renderDetails(item);
    } catch (error) {
        $('drawer-content').innerHTML = `<div class="empty-state">${escapeHtml(error.message)}</div>`;
    }
}

function closeDrawer() {
    $('details-drawer').classList.remove('open');
    $('details-drawer').setAttribute('aria-hidden', 'true');
}

async function openEditModal(id) {
    try {
        await loadOptions();
        const item = await API.get(`/admin/notifications/${id}`);
        state.editItem = item;
        state.editDraft = {
            title: item.title || '',
            description: item.description || '',
            category_id: item.category_id || null,
            image_url: item.image_url || '',
            content_item_id: item.content_item_id || null,
            interest_ids: (item.interests || []).map((interest) => Number(interest.id)),
            use_content_image: false,
        };
        $('edit-modal').classList.add('open');
        $('edit-modal').setAttribute('aria-hidden', 'false');
        $('edit-subtitle').innerHTML = `${typeBadge(item.notification_type)} ${statusBadge(item.status)} <span class="muted">Editarea nu retrimite notificarea.</span>`;
        UI.hideAlert('edit-error');
        renderEditForm();
    } catch (error) {
        UI.showError('alert-box', error.message);
    }
}

function closeEditModal() {
    $('edit-modal').classList.remove('open');
    $('edit-modal').setAttribute('aria-hidden', 'true');
    state.editItem = null;
    state.editDraft = null;
}

function renderEditForm() {
    const item = state.editItem;
    const draft = state.editDraft;
    if (!item || !draft) return;
    const categories = state.options.categories[item.notification_type] || [];
    let contentFields = '';
    if (item.notification_type === 'content') {
        contentFields = `
            <div class="form-grid">
                <div class="form-group wide">
                    <label for="edit-content-search">Selectare conținut cu căutare</label>
                    <input id="edit-content-search" type="search" placeholder="Filtrează conținutul">
                    <select id="edit-content-item-select" name="content_item_id" size="6">${optionsHtml(state.options.contentItems, contentLabel, draft.content_item_id)}</select>
                </div>
                ${renderImageControls('edit', draft)}
                <div class="form-group wide">
                    <label>Interese selectare multiplă</label>
                    <div id="edit-interest-selector" class="multi-select-grid">
                        ${state.options.interests.map((interest) => `
                            <label>
                                <input type="checkbox" name="edit_interest_ids" value="${interest.id}" ${(draft.interest_ids || []).includes(Number(interest.id)) ? 'checked' : ''}>
                                <span>${escapeHtml(interest.name)}</span>
                            </label>
                        `).join('')}
                    </div>
                    <p class="muted">Schimbarea intereselor nu retrimite automat notificarea și nu creează destinatari noi.</p>
                </div>
            </div>
        `;
    }
    $('edit-form').innerHTML = `
        <div class="form-grid">
            <div class="form-group wide">
                <label for="edit-title-input">Titlu</label>
                <input id="edit-title-input" maxlength="255" value="${escapeAttribute(draft.title)}">
            </div>
            <div class="form-group wide">
                <label for="edit-category-select">Categorie notificare</label>
                <select id="edit-category-select">
                    ${optionsHtml(categories, (category) => category.name, draft.category_id)}
                </select>
            </div>
            <div class="form-group wide">
                <label for="edit-description-input">Descriere</label>
                <textarea id="edit-description-input" rows="5">${escapeHtml(draft.description)}</textarea>
            </div>
        </div>
        ${contentFields}
    `;
    bindEditForm();
    renderEditPreview();
}

function bindEditForm() {
    const draft = state.editDraft;
    const item = state.editItem;
    if (!draft || !item) return;
    if ($('edit-content-search')) {
        $('edit-content-search').addEventListener('input', () => {
            const term = $('edit-content-search').value.trim().toLowerCase();
            const items = state.options.contentItems.filter((content) => contentLabel(content).toLowerCase().includes(term));
            $('edit-content-item-select').innerHTML = optionsHtml(items, contentLabel, draft.content_item_id);
        });
    }
    if (item.notification_type === 'content') {
        bindImageControls('edit', draft, () => {
            syncEditDraftFromDom();
            renderEditForm();
        });
    }
}

function syncEditDraftFromDom() {
    if (!state.editDraft) return;
    state.editDraft = {
        ...state.editDraft,
        title: $('edit-title-input')?.value.trim() || state.editDraft.title || '',
        description: $('edit-description-input')?.value.trim() || state.editDraft.description || '',
        category_id: Number($('edit-category-select')?.value || state.editDraft.category_id || 0) || null,
        content_item_id: Number($('edit-content-item-select')?.value || state.editDraft.content_item_id || 0) || null,
        image_url: $('edit-image-url-input')?.value.trim() || state.editDraft.image_url || '',
        interest_ids: [...document.querySelectorAll('input[name="edit_interest_ids"]:checked')].map((input) => Number(input.value)),
    };
}

function getEditPayload() {
    const draft = state.editDraft || {};
    const item = state.editItem || {};
    const payload = {
        title: $('edit-title-input')?.value.trim() || '',
        description: $('edit-description-input')?.value.trim() || '',
        category_id: Number($('edit-category-select')?.value || 0) || null,
    };
    if (item.notification_type === 'content') {
        payload.image_url = $('edit-image-url-input')?.value.trim() || draft.image_url || null;
        payload.content_item_id = Number($('edit-content-item-select')?.value || draft.content_item_id || 0) || null;
        payload.interest_ids = [...document.querySelectorAll('input[name="edit_interest_ids"]:checked')].map((input) => Number(input.value));
    }
    return payload;
}

function renderEditPreview() {
    if (!state.editItem) return;
    const payload = getEditPayload();
    const preview = {
        notification_type: state.editItem.notification_type,
        category_id: payload.category_id,
        title: payload.title || 'Titlul notificării',
        description: payload.description || 'Descriere notificare',
        image_url: payload.image_url,
    };
    $('edit-preview-type').className = `badge ${TYPES[state.editItem.notification_type]?.tone || 'content'}`;
    $('edit-preview-type').textContent = typeShortLabel(state.editItem.notification_type);
    $('edit-preview').innerHTML = renderPreviewCard(preview);
    if ($('edit-image-preview')) {
        $('edit-image-preview').innerHTML = payload.image_url ? `<img src="${escapeAttribute(payload.image_url)}" alt="Previzualizare">` : '';
    }
}

async function saveEdit() {
    if (!state.editItem || state.editing) return;
    const payload = getEditPayload();
    if (!payload.title || !payload.description || !payload.category_id) {
        UI.showError('edit-error', 'Titlul, descrierea și categoria sunt obligatorii.');
        return;
    }
    if (state.editItem.notification_type === 'content' && (!payload.content_item_id || !payload.interest_ids.length)) {
        UI.showError('edit-error', 'Alege un element de conținut și cel puțin un interes.');
        return;
    }
    state.editing = true;
    $('save-edit').disabled = true;
    $('save-edit').textContent = 'Se salvează...';
    try {
        await API.patch(`/admin/notifications/${state.editItem.id}`, payload);
        UI.showAlert('alert-box', 'Notificarea a fost actualizată.', 'success');
        closeEditModal();
        await loadNotifications();
    } catch (error) {
        UI.showError('edit-error', error.message);
    } finally {
        state.editing = false;
        $('save-edit').disabled = false;
        $('save-edit').textContent = 'Salvează modificările';
    }
}

function openDeleteModal(id) {
    const item = state.notifications.find((notification) => Number(notification.id) === Number(id));
    if (!item) return;
    state.deleteItem = item;
    $('delete-summary').innerHTML = `
        <strong>${escapeHtml(item.title)}</strong>
        <div class="muted">${typeBadge(item.notification_type)} ${categoryBadge(item)}</div>
    `;
    $('delete-error').hidden = true;
    $('delete-error').textContent = '';
    $('delete-modal').classList.add('open');
    $('delete-modal').setAttribute('aria-hidden', 'false');
}

function closeDeleteModal() {
    $('delete-modal').classList.remove('open');
    $('delete-modal').setAttribute('aria-hidden', 'true');
    state.deleteItem = null;
}

async function deleteNotification() {
    if (!state.deleteItem || state.deleting) return;
    state.deleting = true;
    $('confirm-delete').disabled = true;
    $('confirm-delete').textContent = 'Se șterge...';
    try {
        await API.delete(`/admin/notifications/${state.deleteItem.id}`);
        UI.showAlert('alert-box', 'Notificarea a fost ștearsă.', 'success');
        closeDeleteModal();
        await loadNotifications();
    } catch (error) {
        $('delete-error').hidden = false;
        $('delete-error').textContent = error.message;
    } finally {
        state.deleting = false;
        $('confirm-delete').disabled = false;
        $('confirm-delete').textContent = 'Șterge notificarea';
    }
}

function renderDetails(item) {
    const interests = (item.interests || []).map((interest) => `<span class="chip selected">${escapeHtml(interest.name)}</span>`).join('') || '<span class="muted">Nu există interese atașate.</span>';
    const recipients = (item.recipients || []).map((recipient) => {
        const name = [recipient.first_name, recipient.last_name].filter(Boolean).join(' ') || 'Fără nume în profil';
        return `
            <tr>
                <td>${escapeHtml(name)}</td>
                <td>${escapeHtml(recipient.email)}</td>
                <td>${formatDate(recipient.delivered_at)}</td>
                <td>${formatDate(recipient.read_at)}</td>
            </tr>
        `;
    }).join('') || '<tr><td colspan="4" class="empty-cell">Nu există destinatari înregistrați.</td></tr>';

    return `
        <div class="notification-detail-grid">
            <section class="admin-panel flat">
                <h4>Mesaj</h4>
                ${renderPreviewCard(item)}
            </section>
            <section class="admin-panel flat">
                <h4>Targetare</h4>
                <p class="muted">Livrată către ${Number(item.delivered_count || 0)} utilizatori. Citită de ${Number(item.read_count || 0)} utilizatori.</p>
                <div class="chip-grid">${interests}</div>
            </section>
        </div>
        <section class="admin-panel flat">
            <h4>Previzualizare destinatari</h4>
            <div class="table-scroll">
                <table class="compact-table">
                    <thead><tr><th>Nume</th><th>Email</th><th>Livrată</th><th>Citită</th></tr></thead>
                    <tbody>${recipients}</tbody>
                </table>
            </div>
        </section>
    `;
}

async function openWizard() {
    state.wizardStep = 1;
    state.selectedType = 'content';
    state.creating = false;
    state.draft = {};
    $('wizard-modal').classList.add('open');
    $('wizard-modal').setAttribute('aria-hidden', 'false');
    $('wizard-success').hidden = true;
    UI.hideAlert('wizard-error');
    await loadOptions();
    renderWizard();
}

function contentImageUrl(contentItemId) {
    const item = state.options.contentItems.find((content) => Number(content.id) === Number(contentItemId));
    return item?.thumbnail_url || item?.hero_image_url || '';
}

function applyContentImageToDraft(draft) {
    const url = contentImageUrl(draft.content_item_id);
    draft.image_url = url || '';
    draft.use_content_image = true;
    return url;
}

function renderImageControls(prefix, draft) {
    const warning = draft.use_content_image && !contentImageUrl(draft.content_item_id)
        ? '<div class="image-warning">Contentul selectat nu are imagine disponibilă.</div>'
        : '';
    return `
        <div class="form-group wide">
            <label>Imagine notificare</label>
            <div class="notification-image-options">
                <button class="btn ${draft.use_content_image ? 'btn-primary' : ''}" type="button" id="${prefix}-use-content-image">Use content image</button>
                <label class="upload-dropzone" for="${prefix}-image-upload">
                    <span>Upload imagine custom</span>
                    <small>JPG, PNG sau WEBP, max. 5MB</small>
                    <input id="${prefix}-image-upload" type="file" accept="image/jpeg,image/png,image/webp">
                </label>
            </div>
            ${warning}
            <input id="${prefix}-image-url-input" name="image_url" type="url" placeholder="https://..." value="${escapeAttribute(draft.image_url || '')}">
            <div id="${prefix}-upload-status" class="upload-status"></div>
            <div id="${prefix}-image-preview" class="media-preview"></div>
        </div>
    `;
}

function bindImageControls(prefix, draft, onChange) {
    const contentSelect = $(`${prefix}-content-item-select`);
    if (contentSelect) {
        contentSelect.addEventListener('change', () => {
            draft.content_item_id = Number(contentSelect.value || 0) || null;
            if (draft.use_content_image) applyContentImageToDraft(draft);
            onChange();
        });
    }
    const imageInput = $(`${prefix}-image-url-input`);
    if (imageInput) {
        imageInput.addEventListener('input', () => {
            draft.image_url = imageInput.value.trim();
            draft.use_content_image = false;
            onChange();
        });
    }
    const useContentButton = $(`${prefix}-use-content-image`);
    if (useContentButton) {
        useContentButton.addEventListener('click', () => {
            const contentId = Number($(`${prefix}-content-item-select`)?.value || draft.content_item_id || 0) || null;
            draft.content_item_id = contentId;
            const url = applyContentImageToDraft(draft);
            if (imageInput) imageInput.value = draft.image_url || '';
            if (!url) setUploadStatus(prefix, 'Contentul selectat nu are imagine disponibilă.', 'error');
            onChange();
        });
    }
    const uploadInput = $(`${prefix}-image-upload`);
    if (uploadInput) {
        uploadInput.addEventListener('change', async () => {
            const file = uploadInput.files?.[0];
            if (!file) return;
            if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
                setUploadStatus(prefix, 'Tip fișier neacceptat. Folosește JPG, PNG sau WEBP.', 'error');
                return;
            }
            if (file.size > 5 * 1024 * 1024) {
                setUploadStatus(prefix, 'Imaginea depășește limita de 5MB.', 'error');
                return;
            }
            try {
                setUploadStatus(prefix, 'Se încarcă imaginea...', '');
                const result = await uploadNotificationImage(file);
                draft.image_url = result.url;
                draft.use_content_image = false;
                if (imageInput) imageInput.value = result.url;
                setUploadStatus(prefix, 'Imagine încărcată cu succes.', 'success');
                onChange();
            } catch (error) {
                setUploadStatus(prefix, error.message, 'error');
            } finally {
                uploadInput.value = '';
            }
        });
    }
}

function setUploadStatus(prefix, message, type = '') {
    const target = $(`${prefix}-upload-status`);
    if (!target) return;
    target.textContent = message || '';
    target.className = `upload-status ${type}`.trim();
}

async function uploadNotificationImage(file) {
    const formData = new FormData();
    formData.append('file', file);
    const headers = {};
    const token = localStorage.getItem('pulse_admin_token');
    if (token) headers.Authorization = `Bearer ${token}`;
    const response = await fetch(`${CONFIG.API_BASE_URL}/admin/notifications/upload-image`, {
        method: 'POST',
        headers,
        body: formData,
    });
    const data = await response.json().catch(async () => ({ detail: await response.text().catch(() => '') }));
    if (!response.ok) {
        throw new Error(apiErrorMessage(data, `Upload eșuat: ${response.status}`));
    }
    return data;
}

function closeWizard() {
    $('wizard-modal').classList.remove('open');
    $('wizard-modal').setAttribute('aria-hidden', 'true');
}

async function loadOptions() {
    if (
        state.options.contentItems.length &&
        state.options.interests.length &&
        state.options.users.length &&
        state.options.categories.content.length &&
        state.options.categories.account.length &&
        state.options.categories.system.length
    ) return;
    const [contentItems, interests, users, contentCategories, accountCategories, systemCategories] = await Promise.all([
        API.get('/admin/notification-options/content-items'),
        API.get('/admin/notification-options/interests'),
        API.get('/admin/notification-options/users'),
        API.get('/admin/notification-options/categories?notification_type=content'),
        API.get('/admin/notification-options/categories?notification_type=account'),
        API.get('/admin/notification-options/categories?notification_type=system'),
    ]);
    state.options = {
        contentItems,
        interests,
        users,
        categories: {
            content: contentCategories,
            account: accountCategories,
            system: systemCategories,
        },
    };
}

function renderWizard() {
    renderSteps();
    renderTypeStep();
    renderDetailsStep();
    renderConfirmStep();
    [...document.querySelectorAll('.wizard-step-panel')].forEach((panel, index) => {
        panel.classList.toggle('active', index + 1 === state.wizardStep);
    });
    $('wizard-back').style.display = state.wizardStep === 1 ? 'none' : 'inline-flex';
    $('wizard-next').style.display = state.wizardStep === 3 ? 'none' : 'inline-flex';
    $('wizard-submit').style.display = state.wizardStep === 3 ? 'inline-flex' : 'none';
    renderPreview();
}

function renderSteps() {
    const labels = ['Selectează tipul', 'Completează detaliile', 'Previzualizează și confirmă'];
    $('wizard-steps').innerHTML = labels.map((label, index) => `
        <div class="wizard-step ${state.wizardStep === index + 1 ? 'active' : ''} ${state.wizardStep > index + 1 ? 'done' : ''}">
            <span>${index + 1}</span>
            <strong>${label}</strong>
        </div>
    `).join('');
}

function renderTypeStep() {
    $('step-type').innerHTML = `
        <div class="type-choice-grid">
            ${Object.entries(TYPES).map(([value, type]) => `
                <button class="type-choice ${state.selectedType === value ? 'selected' : ''}" type="button" data-type="${value}">
                    ${typeBadge(value)}
                    <strong>${type.label}</strong>
                    <span>${typeDescription(value)}</span>
                </button>
            `).join('')}
        </div>
    `;
    document.querySelectorAll('.type-choice').forEach((button) => {
        button.addEventListener('click', () => {
            state.selectedType = button.dataset.type;
            state.draft.category_id = null;
            renderWizard();
        });
    });
}

function renderDetailsStep() {
    const common = `
        <div class="form-grid">
            <div class="form-group wide">
                <label for="title-input">Titlu</label>
                <input id="title-input" name="title" maxlength="255" placeholder="Titlul notificării" value="${escapeAttribute(state.draft.title || '')}" required>
            </div>
            <div class="form-group wide">
                <label for="category-select">Categorie notificare</label>
                <select id="category-select" name="category_id">
                    <option value="">Selectează categoria</option>
                    ${optionsHtml(categoriesForSelectedType(), (category) => category.name, state.draft.category_id)}
                </select>
            </div>
            <div class="form-group wide">
                <label for="description-input">Descriere</label>
                <textarea id="description-input" name="description" rows="5" placeholder="Scrie un mesaj clar pentru utilizator" required>${escapeHtml(state.draft.description || '')}</textarea>
            </div>
        </div>
    `;
    let dynamic = '';
    if (state.selectedType === 'content') {
        dynamic = `
            <div class="form-grid">
                <div class="form-group wide">
                    <label for="content-search">Selectare conținut cu căutare</label>
                    <input id="content-search" type="search" placeholder="Filtrează conținutul">
                    <select id="create-content-item-select" name="content_item_id" size="6">${optionsHtml(state.options.contentItems, contentLabel, state.draft.content_item_id)}</select>
                </div>
                ${renderImageControls('create', state.draft)}
                <div class="form-group wide">
                    <label>Interese selectare multiplă</label>
                    <div id="interest-selector" class="multi-select-grid">
                        ${state.options.interests.map((interest) => `
                            <label>
                                <input type="checkbox" name="interest_ids" value="${interest.id}" ${(state.draft.interest_ids || []).includes(Number(interest.id)) ? 'checked' : ''}>
                                <span>${escapeHtml(interest.name)}</span>
                            </label>
                        `).join('')}
                    </div>
                </div>
            </div>
        `;
    } else if (state.selectedType === 'account') {
        dynamic = `
            <div class="form-grid">
                <div class="form-group wide">
                    <label for="user-search">Utilizator țintă cu căutare</label>
                    <input id="user-search" type="search" placeholder="Filtrează după nume sau email">
                    <select id="user-select" name="user_id" size="7">${optionsHtml(state.options.users, userLabel, state.draft.user_id)}</select>
                </div>
            </div>
        `;
    } else {
        dynamic = `
            <div class="system-warning">
                <strong>Broadcast de sistem</strong>
                <span>Această notificare va fi trimisă tuturor utilizatorilor activi după confirmare.</span>
            </div>
        `;
    }
    $('step-details').innerHTML = `${common}${dynamic}`;
    bindDynamicFilters();
    if (state.selectedType === 'content') {
        bindImageControls('create', state.draft, () => {
            saveDraft();
            renderWizard();
        });
    }
}

function renderConfirmStep() {
    $('step-confirm').innerHTML = `
        <div class="confirm-summary">
            <h4>Verifică înainte de trimitere</h4>
            <div id="confirm-content"></div>
        </div>
    `;
    updateConfirmSummary();
}

function bindDynamicFilters() {
    const contentSearch = $('content-search');
    if (contentSearch) {
        contentSearch.addEventListener('input', () => {
            const term = contentSearch.value.trim().toLowerCase();
            const items = state.options.contentItems.filter((item) => contentLabel(item).toLowerCase().includes(term));
            $('create-content-item-select').innerHTML = optionsHtml(items, contentLabel, state.draft.content_item_id);
        });
    }
    const userSearch = $('user-search');
    if (userSearch) {
        userSearch.addEventListener('input', () => {
            const term = userSearch.value.trim().toLowerCase();
            const users = state.options.users.filter((user) => userLabel(user).toLowerCase().includes(term));
            $('user-select').innerHTML = optionsHtml(users, userLabel, state.draft.user_id);
        });
    }
}

function previousStep() {
    saveDraft();
    if (state.wizardStep > 1) {
        state.wizardStep -= 1;
        UI.hideAlert('wizard-error');
        renderWizard();
    }
}

function nextStep() {
    saveDraft();
    if (!validateStep()) return;
    state.wizardStep += 1;
    UI.hideAlert('wizard-error');
    renderWizard();
}

function validateStep() {
    if (state.wizardStep === 1) return true;
    const payload = getPayload();
    if (!payload.title || !payload.description) {
        UI.showError('wizard-error', 'Titlul și descrierea sunt obligatorii.');
        return false;
    }
    if (!payload.category_id) {
        UI.showError('wizard-error', 'Alege categoria notificării.');
        return false;
    }
    if (state.selectedType === 'content' && (!payload.content_item_id || !payload.interest_ids.length)) {
        UI.showError('wizard-error', 'Alege un element de conținut și cel puțin un interes.');
        return false;
    }
    if (state.selectedType === 'account' && !payload.user_id) {
        UI.showError('wizard-error', 'Alege utilizatorul țintă.');
        return false;
    }
    return true;
}

async function submitNotification() {
    if (!validateStep() || state.creating) return;
    state.creating = true;
    $('wizard-submit').disabled = true;
    $('wizard-submit').textContent = 'Se trimite...';
    try {
        await API.post('/admin/notifications', getPayload());
        $('wizard-success').hidden = false;
        UI.hideAlert('wizard-error');
        await loadNotifications();
        setTimeout(closeWizard, 900);
    } catch (error) {
        UI.showError('wizard-error', error.message);
    } finally {
        state.creating = false;
        $('wizard-submit').disabled = false;
        $('wizard-submit').textContent = 'Trimite notificarea';
    }
}

function getPayload() {
    const title = $('title-input')?.value.trim() || '';
    const description = $('description-input')?.value.trim() || '';
    const payload = {
        notification_type: state.selectedType,
        category_id: Number($('category-select')?.value || 0) || null,
        title,
        description,
    };
    if (state.selectedType === 'content') {
        payload.image_url = $('create-image-url-input')?.value.trim() || state.draft.image_url || null;
        payload.content_item_id = Number($('create-content-item-select')?.value || state.draft.content_item_id || 0) || null;
        payload.interest_ids = [...document.querySelectorAll('input[name="interest_ids"]:checked')].map((input) => Number(input.value));
    }
    if (state.selectedType === 'account') {
        payload.user_id = Number($('user-select')?.value || 0) || null;
    }
    return payload;
}

function saveDraft() {
    state.draft = { ...state.draft, ...getPayload() };
}

function renderPreview() {
    saveDraft();
    const payload = getPayload();
    const previewItem = {
        notification_type: state.selectedType,
        category_id: payload.category_id,
        title: payload.title || 'Titlul notificării',
        description: payload.description || 'Previzualizarea mesajului apare aici pe măsură ce scrii.',
        image_url: payload.image_url,
    };
    $('preview-type').className = `badge ${TYPES[state.selectedType].tone}`;
    $('preview-type').textContent = typeShortLabel(state.selectedType);
    $('notification-preview').innerHTML = renderPreviewCard(previewItem);
    if ($('create-image-preview')) {
        $('create-image-preview').innerHTML = payload.image_url ? `<img src="${escapeAttribute(payload.image_url)}" alt="Previzualizare">` : '';
    }
    updateConfirmSummary();
}

function updateConfirmSummary() {
    const target = $('confirm-content');
    if (!target) return;
    const payload = getPayload();
    const selectedContent = state.options.contentItems.find((item) => Number(item.id) === Number(payload.content_item_id));
    const selectedUser = state.options.users.find((user) => Number(user.id) === Number(payload.user_id));
    const selectedCategory = categoriesForSelectedType().find((category) => Number(category.id) === Number(payload.category_id));
    const selectedInterests = state.options.interests.filter((interest) => (payload.interest_ids || []).includes(Number(interest.id)));
    target.innerHTML = `
        <dl class="summary-list">
            <div><dt>Tip</dt><dd>${typeBadge(state.selectedType)}</dd></div>
            <div><dt>Categorie</dt><dd>${escapeHtml(selectedCategory?.name || '-')}</dd></div>
            <div><dt>Titlu</dt><dd>${escapeHtml(payload.title || '-')}</dd></div>
            <div><dt>Descriere</dt><dd>${escapeHtml(payload.description || '-')}</dd></div>
            ${state.selectedType === 'content' ? `<div><dt>Conținut</dt><dd>${escapeHtml(selectedContent ? contentLabel(selectedContent) : '-')}</dd></div>` : ''}
            ${state.selectedType === 'content' ? `<div><dt>Interese</dt><dd>${selectedInterests.map((item) => escapeHtml(item.name)).join(', ') || '-'}</dd></div>` : ''}
            ${state.selectedType === 'account' ? `<div><dt>Utilizator</dt><dd>${escapeHtml(selectedUser ? userLabel(selectedUser) : '-')}</dd></div>` : ''}
            ${state.selectedType === 'system' ? '<div><dt>Țintă</dt><dd>Toți utilizatorii activi</dd></div>' : ''}
        </dl>
    `;
}

function renderPreviewCard(item) {
    const image = item.image_url ? `<img src="${escapeAttribute(item.image_url)}" alt="">` : '';
    return `
        <article class="notification-card ${escapeHtml(item.notification_type || 'content')}">
            ${image}
            <div>
                ${typeBadge(item.notification_type || 'content')}
                ${categoryBadge(item)}
                <h4>${escapeHtml(item.title || '-')}</h4>
                <p>${escapeHtml(item.description || '-')}</p>
            </div>
        </article>
    `;
}

function typeBadge(type) {
    const normalized = type || 'content';
    return `<span class="badge ${escapeHtml(normalized)}">${escapeHtml(TYPES[normalized]?.label || normalized)}</span>`;
}

function categoryBadge(item) {
    const name = item?.category_name || categoryNameById(item?.category_id) || 'Fără categorie';
    return `<span class="badge category">${escapeHtml(name)}</span>`;
}

function categoryNameById(categoryId) {
    if (!categoryId) return '';
    const allCategories = [
        ...state.options.categories.content,
        ...state.options.categories.account,
        ...state.options.categories.system,
    ];
    return allCategories.find((category) => Number(category.id) === Number(categoryId))?.name || '';
}

function categoriesForSelectedType() {
    return state.options.categories[state.selectedType] || [];
}

function statusBadge(status) {
    return `<span class="badge ${escapeHtml(status || 'draft')}">${escapeHtml(statusLabel(status))}</span>`;
}

function typeShortLabel(type) {
    return {
        content: 'conținut',
        account: 'cont',
        system: 'sistem',
    }[type] || type || 'conținut';
}

function statusLabel(status) {
    return {
        draft: 'draft',
        sent: 'trimis',
        cancelled: 'anulat',
        published: 'publicat',
        archived: 'arhivat',
        in_review: 'în revizie',
    }[status] || status || 'draft';
}

function contentTypeLabel(type) {
    return {
        article: 'articol',
        news: 'știre',
        course: 'curs',
        event: 'eveniment',
        publication: 'publicație',
    }[type] || type || 'conținut';
}

function typeDescription(type) {
    if (type === 'content') return 'Promovează conținut către utilizatori potriviți după interese medicale.';
    if (type === 'account') return 'Trimite un mesaj individual, precis, către un utilizator selectat.';
    return 'Trimite un mesaj de platformă către fiecare utilizator activ.';
}

function optionsHtml(items, labelFn, selectedId = null) {
    return items.map((item) => `<option value="${item.id}" ${Number(item.id) === Number(selectedId) ? 'selected' : ''}>${escapeHtml(labelFn(item))}</option>`).join('');
}

function contentLabel(item) {
    return `${item.title || 'Fără titlu'} - ${contentTypeLabel(item.content_type)} - ${statusLabel(item.status)}`;
}

function userLabel(user) {
    const name = user.full_name || [user.first_name, user.last_name].filter(Boolean).join(' ');
    return `${name ? `${name} - ` : ''}${user.email}${user.is_active ? '' : ' - inactiv'}`;
}

function formatDate(value) {
    if (!value) return '-';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return '-';
    return date.toLocaleString('ro-RO', { dateStyle: 'medium', timeStyle: 'short' });
}

function debounce(fn, wait = 250) {
    let timeout;
    return (...args) => {
        clearTimeout(timeout);
        timeout = setTimeout(() => fn(...args), wait);
    };
}

function escapeHtml(value) {
    return String(value ?? '').replace(/[&<>"']/g, (char) => ({
        '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;',
    }[char]));
}

function escapeAttribute(value) {
    return escapeHtml(value).replace(/`/g, '&#096;');
}
