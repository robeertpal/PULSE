let currentContentType = null;

document.addEventListener('DOMContentLoaded', async () => {
    UI.init('content', 'Adaugă / Editează Conținut');

    const contentType = document.getElementById('content_type');
    contentType.addEventListener('change', toggleDetailsSections);
    ['hero_image_url', 'thumbnail_url', 'publication_logo_url'].forEach(inputId => {
        document.getElementById(inputId).addEventListener('input', () => updateImagePreview(inputId));
    });

    await loadReferenceData();

    const urlParams = new URLSearchParams(window.location.search);
    const id = urlParams.get('id');
    const type = urlParams.get('type');

    if (type) {
        contentType.value = type;
    }

    toggleDetailsSections();

    if (id) {
        document.getElementById('content-id').value = id;
        await loadContentData(id);
    }
});

function valueOrNull(id) {
    const value = document.getElementById(id).value.trim();
    return value === '' ? null : value;
}

function intOrNull(id) {
    const value = valueOrNull(id);
    return value === null ? null : Number.parseInt(value, 10);
}

function floatOrNull(id) {
    const value = valueOrNull(id);
    return value === null ? null : Number.parseFloat(value);
}

function toDateTimeLocal(value) {
    if (!value) return '';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return '';
    return date.toISOString().slice(0, 16);
}

function dateTimeOrNull(id) {
    const value = valueOrNull(id);
    return value === null ? null : new Date(value).toISOString();
}

function generateSlug() {
    const title = document.getElementById('title').value;
    const slugInput = document.getElementById('slug');
    if (!document.getElementById('content-id').value) {
        slugInput.value = title
            .toLowerCase()
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .replace(/[^a-z0-9]+/g, '-')
            .replace(/(^-|-$)+/g, '');
    }
}

async function loadReferenceData() {
    const [categories, specializations, cities] = await Promise.all([
        API.get('/admin/categories'),
        API.get('/admin/specializations'),
        API.get('/admin/cities'),
    ]);

    fillSelect('category_id', categories, 'Fără categorie');
    fillSelect('specialization_id', specializations, 'Fără specializare');
    fillSelect('event_city_id', cities, 'Fără oraș');
}

function fillSelect(id, items, emptyLabel) {
    const select = document.getElementById(id);
    select.innerHTML = `<option value="">${emptyLabel}</option>`;
    items.forEach(item => {
        const option = document.createElement('option');
        option.value = item.id;
        option.textContent = item.name;
        select.appendChild(option);
    });
}

function toggleDetailsSections() {
    const type = document.getElementById('content_type').value;
    ['course', 'event', 'publication'].forEach(sectionType => {
        document.getElementById(`${sectionType}-fields`).classList.toggle('active', type === sectionType);
    });
}

async function loadContentData(id) {
    try {
        const data = await API.get(`/admin/content-items/${id}`);
        currentContentType = data.content_type;

        document.getElementById('title').value = data.title || '';
        document.getElementById('slug').value = data.slug || '';
        document.getElementById('content_type').value = data.content_type || 'article';
        document.getElementById('status').value = data.status || 'draft';
        document.getElementById('category_id').value = data.category_id || '';
        document.getElementById('specialization_id').value = data.specialization_id || '';
        document.getElementById('short_description').value = data.short_description || '';
        document.getElementById('body').value = data.body || '';
        document.getElementById('author_name').value = data.author_name || '';
        document.getElementById('hero_image_url').value = data.hero_image_url || '';
        document.getElementById('thumbnail_url').value = data.thumbnail_url || '';
        document.getElementById('source_url').value = data.source_url || '';
        document.getElementById('published_at').value = toDateTimeLocal(data.published_at);
        document.getElementById('is_featured').checked = data.is_featured || false;
        document.getElementById('is_active').checked = data.is_active !== false;
        updateImagePreview('hero_image_url');
        updateImagePreview('thumbnail_url');

        fillCourseFields(data.course || {});
        fillEventFields(data.event || {});
        fillPublicationFields(data.publication || {});
        toggleDetailsSections();
    } catch (err) {
        showAlert('Eroare la încărcarea datelor: ' + err.message, 'error');
    }
}

function fillCourseFields(course) {
    document.getElementById('course_emc_credits').value = course.emc_credits ?? '';
    document.getElementById('course_valid_from').value = toDateTimeLocal(course.valid_from);
    document.getElementById('course_valid_until').value = toDateTimeLocal(course.valid_until);
    document.getElementById('course_enrollment_url').value = course.enrollment_url || '';
    document.getElementById('course_provider').value = course.provider || '';
    document.getElementById('course_status').value = course.course_status || 'draft';
}

function fillEventFields(event) {
    document.getElementById('event_city_id').value = event.city_id || '';
    document.getElementById('event_venue_name').value = event.venue_name || '';
    document.getElementById('event_attendance_mode').value = event.attendance_mode || 'onsite';
    document.getElementById('event_start_date').value = toDateTimeLocal(event.start_date);
    document.getElementById('event_end_date').value = toDateTimeLocal(event.end_date);
    document.getElementById('event_price_type').value = event.price_type || 'free';
    document.getElementById('event_price_amount').value = event.price_amount ?? '';
    document.getElementById('event_emc_credits').value = event.emc_credits ?? '';
    document.getElementById('event_accreditation_status').value = event.accreditation_status || '';
    document.getElementById('event_page_url').value = event.event_page_url || '';
    document.getElementById('event_registration_url').value = event.registration_url || '';
}

function fillPublicationFields(publication) {
    document.getElementById('publication_name').value = publication.name || '';
    document.getElementById('publication_logo_url').value = publication.logo_url || '';
    document.getElementById('publication_description').value = publication.description || '';
    document.getElementById('publication_emc_credits_text').value = publication.emc_credits_text || '';
    document.getElementById('publication_creditation_text').value = publication.creditation_text || '';
    document.getElementById('publication_indexing_text').value = publication.indexing_text || '';
    document.getElementById('publication_subscription_url').value = publication.subscription_url || '';
    updateImagePreview('publication_logo_url');
}

function setUploadStatus(targetInputId, message, type = '') {
    const status = document.getElementById(`${targetInputId}_upload_status`);
    if (!status) return;
    status.textContent = message;
    status.className = `upload-status ${type}`.trim();
}

function updateImagePreview(targetInputId) {
    const input = document.getElementById(targetInputId);
    const preview = document.getElementById(`${targetInputId}_preview`);
    if (!input || !preview) return;

    const url = input.value.trim();
    preview.innerHTML = url ? `<img src="${url}" alt="Preview imagine">` : '';
}

function updatePdfPreview(targetInputId) {
    const input = document.getElementById(targetInputId);
    const preview = document.getElementById(`${targetInputId}_preview`);
    if (!input || !preview) return;

    const url = input.value.trim();
    preview.innerHTML = url ? `<a href="${url}" target="_blank" rel="noopener">Deschide PDF</a>` : '';
}

async function uploadFile(file, endpoint, targetInputId, previewType) {
    if (!file) {
        setUploadStatus(targetInputId, 'Alegeți un fișier înainte de upload.', 'error');
        return null;
    }

    const formData = new FormData();
    formData.append('file', file);

    setUploadStatus(targetInputId, 'Se încarcă...');

    try {
        const headers = {};
        const token = localStorage.getItem('pulse_admin_token');
        if (token) headers.Authorization = `Bearer ${token}`;

        const response = await fetch(`${CONFIG.API_BASE_URL}${endpoint}`, {
            method: 'POST',
            headers,
            body: formData,
        });

        const data = await response.json().catch(() => ({}));
        if (!response.ok) {
            throw new Error(data.detail || data.error || data.message || `Upload eșuat: ${response.status}`);
        }

        document.getElementById(targetInputId).value = data.url;
        if (previewType === 'image') updateImagePreview(targetInputId);
        if (previewType === 'pdf') updatePdfPreview(targetInputId);
        setUploadStatus(targetInputId, 'Upload finalizat.', 'success');
        return data;
    } catch (err) {
        setUploadStatus(targetInputId, err.message, 'error');
        throw err;
    }
}

async function uploadImage(file, targetInputId) {
    return uploadFile(file, '/admin/uploads/image', targetInputId, 'image');
}

async function uploadPdf(file, targetInputId) {
    return uploadFile(file, '/admin/uploads/pdf', targetInputId, 'pdf');
}

async function uploadImageFromInput(fileInputId, targetInputId) {
    const file = document.getElementById(fileInputId).files[0];
    try {
        await uploadImage(file, targetInputId);
    } catch (err) {
        showAlert('Eroare upload imagine: ' + err.message, 'error');
    }
}

async function uploadPdfFromInput(fileInputId, targetInputId) {
    const file = document.getElementById(fileInputId).files[0];
    try {
        await uploadPdf(file, targetInputId);
    } catch (err) {
        showAlert('Eroare upload PDF: ' + err.message, 'error');
    }
}

function buildContentPayload() {
    return {
        title: valueOrNull('title'),
        slug: valueOrNull('slug'),
        content_type: document.getElementById('content_type').value,
        status: document.getElementById('status').value,
        short_description: valueOrNull('short_description'),
        body: valueOrNull('body'),
        category_id: intOrNull('category_id'),
        specialization_id: intOrNull('specialization_id'),
        hero_image_url: valueOrNull('hero_image_url'),
        thumbnail_url: valueOrNull('thumbnail_url'),
        author_name: valueOrNull('author_name'),
        source_url: valueOrNull('source_url'),
        is_featured: document.getElementById('is_featured').checked,
        is_active: document.getElementById('is_active').checked,
        published_at: dateTimeOrNull('published_at'),
    };
}

function buildPayload() {
    const payload = buildContentPayload();

    if (payload.content_type === 'course') {
        payload.course = {
            emc_credits: intOrNull('course_emc_credits'),
            valid_from: dateTimeOrNull('course_valid_from'),
            valid_until: dateTimeOrNull('course_valid_until'),
            enrollment_url: valueOrNull('course_enrollment_url'),
            provider: valueOrNull('course_provider'),
            course_status: document.getElementById('course_status').value,
        };
    }

    if (payload.content_type === 'event') {
        payload.event = {
            city_id: intOrNull('event_city_id'),
            venue_name: valueOrNull('event_venue_name'),
            attendance_mode: document.getElementById('event_attendance_mode').value,
            start_date: dateTimeOrNull('event_start_date'),
            end_date: dateTimeOrNull('event_end_date'),
            price_type: document.getElementById('event_price_type').value,
            price_amount: floatOrNull('event_price_amount'),
            emc_credits: intOrNull('event_emc_credits'),
            accreditation_status: valueOrNull('event_accreditation_status'),
            event_page_url: valueOrNull('event_page_url'),
            registration_url: valueOrNull('event_registration_url'),
        };
    }

    if (payload.content_type === 'publication') {
        payload.publication = {
            name: valueOrNull('publication_name') || payload.title,
            logo_url: valueOrNull('publication_logo_url'),
            description: valueOrNull('publication_description'),
            emc_credits_text: valueOrNull('publication_emc_credits_text'),
            creditation_text: valueOrNull('publication_creditation_text'),
            indexing_text: valueOrNull('publication_indexing_text'),
            subscription_url: valueOrNull('publication_subscription_url'),
        };
    }

    removeImmutableIds(payload);
    return payload;
}

function removeImmutableIds(payload) {
    delete payload.id;
    delete payload.content_item_id;

    ['course', 'event', 'publication'].forEach(childKey => {
        if (!payload[childKey]) return;
        delete payload[childKey].id;
        delete payload[childKey].content_item_id;
    });
}

function validatePayload(payload) {
    if (!payload.title || !payload.slug || !payload.content_type) {
        throw new Error('Completați titlul, slug-ul și tipul de conținut.');
    }
    if (payload.content_type === 'event' && (!payload.event.start_date || !payload.event.end_date)) {
        throw new Error('Evenimentele au nevoie de data de început și data de sfârșit.');
    }
}

function endpointForType(type, id) {
    const base = {
        course: '/admin/courses',
        event: '/admin/events',
        publication: '/admin/publications',
    }[type] || '/admin/content-items';

    return id ? `${base}/${id}` : base;
}

async function saveContent() {
    const id = document.getElementById('content-id').value;
    const payload = buildPayload();

    try {
        validatePayload(payload);

        if (id && currentContentType && currentContentType !== payload.content_type) {
            showAlert('Schimbarea tipului de conținut existent nu este permisă în MVP. Creați un element nou pentru alt tip.', 'error');
            return;
        }

        const endpoint = endpointForType(payload.content_type, id);
        if (id) {
            await API.put(endpoint, payload);
            showAlert('Conținut actualizat cu succes!', 'success');
        } else {
            await API.post(endpoint, payload);
            showAlert('Conținut creat cu succes!', 'success');
            setTimeout(() => window.location.href = 'content.html', 1500);
        }
    } catch (err) {
        showAlert('Eroare: ' + err.message, 'error');
    }
}

function showAlert(msg, type) {
    const alertBox = document.getElementById('alert-msg');
    alertBox.textContent = msg;
    alertBox.className = `alert ${type}`;
    alertBox.style.display = 'block';
    setTimeout(() => { alertBox.style.display = 'none'; }, 5000);
}
