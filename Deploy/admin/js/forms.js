let currentContentType = null;
let currentEventId = null;
let allEventPartners = [];
let selectedEventPartnerIds = [];
let draggedEventPartnerId = null;
let allAuthors = [];
let selectedPublicationAuthors = [];
let draggedPublicationAuthorId = null;
let allInterests = [];
let selectedContentInterestIds = [];

document.addEventListener('DOMContentLoaded', async () => {
    UI.init('content', 'Adaugă / Editează Conținut');

    const contentType = document.getElementById('content_type');
    contentType.addEventListener('change', toggleDetailsSections);
    document.getElementById('interest_search').addEventListener('input', renderContentInterests);
    document.getElementById('notify_interested_users').addEventListener('change', updateNotifyInterestsWarning);
    document.getElementById('event_future_price_type').addEventListener('change', syncFuturePriceAmountState);
    ['hero_image_url', 'thumbnail_url', 'publication_logo_url'].forEach(inputId => {
        document.getElementById(inputId).addEventListener('input', () => updateImagePreview(inputId));
    });

    await loadReferenceData();
    renderEventCurrentPriceInfo({});

    const urlParams = new URLSearchParams(window.location.search);
    const id = urlParams.get('id');
    const type = urlParams.get('type');

    if (type) {
        contentType.value = type;
    }

    toggleDetailsSections();
    loadEventPriceSchedule();

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
    const [categories, specializations, cities, partners, authors, interests] = await Promise.all([
        API.get('/admin/categories'),
        API.get('/admin/specializations'),
        API.get('/admin/cities'),
        API.get('/admin/event-partners'),
        API.get('/authors'),
        API.get('/admin/interests'),
    ]);

    fillSelect('category_id', categories, 'Fără categorie');
    fillSelect('specialization_id', specializations, 'Fără specializare');
    fillSelect('event_city_id', cities, 'Fără oraș');
    allEventPartners = partners || [];
    allAuthors = authors || [];
    allInterests = interests || [];
    renderContentInterests();
    renderEventPartners([]);
    renderPublicationAuthors([]);
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

function renderContentInterests() {
    const list = document.getElementById('content_interests_list');
    const selected = document.getElementById('selected_content_interests');
    if (!list || !selected) return;

    const term = document.getElementById('interest_search').value.trim().toLowerCase();
    const visibleInterests = allInterests.filter(interest => {
        const name = (interest.name || '').toLowerCase();
        const slug = (interest.slug || '').toLowerCase();
        return !term || name.includes(term) || slug.includes(term);
    });

    if (!visibleInterests.length) {
        list.innerHTML = '<div class="muted">Nu există interese pentru căutarea curentă.</div>';
    } else {
        list.innerHTML = visibleInterests.map(interest => `
            <label>
                <input type="checkbox" class="content-interest-checkbox" value="${interest.id}" ${selectedContentInterestIds.includes(Number(interest.id)) ? 'checked' : ''}>
                <span>${escapeHTML(interest.name)}</span>
            </label>
        `).join('');
        list.querySelectorAll('.content-interest-checkbox').forEach(checkbox => {
            checkbox.addEventListener('change', () => {
                const interestId = Number(checkbox.value);
                if (checkbox.checked && !selectedContentInterestIds.includes(interestId)) {
                    selectedContentInterestIds.push(interestId);
                }
                if (!checkbox.checked) {
                    selectedContentInterestIds = selectedContentInterestIds.filter(id => id !== interestId);
                }
                renderContentInterests();
                updateNotifyInterestsWarning();
            });
        });
    }

    const selectedInterests = selectedContentInterestIds
        .map(id => allInterests.find(interest => Number(interest.id) === id))
        .filter(Boolean);
    if (!selectedInterests.length) {
        selected.classList.add('empty');
        selected.innerHTML = '<span class="muted">Niciun interes selectat.</span>';
    } else {
        selected.classList.remove('empty');
        selected.innerHTML = selectedInterests.map(interest => `
            <button type="button" class="chip selected" data-interest-id="${interest.id}">
                ${escapeHTML(interest.name)} <span aria-hidden="true">×</span>
            </button>
        `).join('');
        selected.querySelectorAll('[data-interest-id]').forEach(button => {
            button.addEventListener('click', () => {
                const interestId = Number(button.dataset.interestId);
                selectedContentInterestIds = selectedContentInterestIds.filter(id => id !== interestId);
                renderContentInterests();
                updateNotifyInterestsWarning();
            });
        });
    }
    updateNotifyInterestsWarning();
}

function updateNotifyInterestsWarning() {
    const warning = document.getElementById('notify_interests_warning');
    const checkbox = document.getElementById('notify_interested_users');
    if (!warning || !checkbox) return;
    warning.style.display = checkbox.checked && selectedContentInterestIds.length === 0 ? 'block' : 'none';
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
        selectedContentInterestIds = (data.interest_ids || []).map(Number).filter(Boolean);
        renderContentInterests();

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
    currentEventId = event.id || null;
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
    renderEventCurrentPriceInfo(event);
    renderEventPartners(event.partners || []);
    loadEventPriceSchedule();
}

function formatCurrentPrice(event) {
    const price = event.price || {};
    const type = price.type || event.current_price_type || event.price_type;
    const amount = price.amount ?? event.current_price_amount ?? event.price_amount;
    const currency = price.currency || event.current_price_currency || 'RON';

    if (type === 'free') return 'Gratuit';
    if (type === 'subscription') return amount === null || amount === undefined ? 'Abonament' : `${amount} ${currency}`;
    if (amount === null || amount === undefined || amount === '') return '-';
    return `${amount} ${currency}`;
}

function renderEventCurrentPriceInfo(event) {
    const container = document.getElementById('event_current_price_info');
    if (!container) return;

    const nextChange = event.next_price_change || null;
    container.className = 'price-info-card';
    container.innerHTML = `
        <div><strong>Preț curent:</strong> ${escapeHTML(formatCurrentPrice(event))}</div>
        ${nextChange?.message ? `<div class="price-change-message">${escapeHTML(nextChange.message)}</div>` : '<div class="muted">Nu există o schimbare viitoare de preț programată.</div>'}
    `;
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

function escapeHTML(value) {
    return String(value ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

function formatScheduledPrice(item) {
    if (item.price_type === 'free') return 'Gratuit';
    const amount = item.price_amount ?? '-';
    return `${amount} ${item.currency || 'RON'}`;
}

function setEventPriceStatus(message, type = '') {
    const status = document.getElementById('event_price_schedule_status');
    if (!status) return;
    status.textContent = message;
    status.className = `upload-status ${type}`.trim();
}

async function loadEventPriceSchedule() {
    const list = document.getElementById('event_price_schedule_list');
    const button = document.getElementById('add_event_price_btn');
    if (!list || !button) return;

    hideEventPriceForm();
    setEventPriceStatus('');

    if (!currentEventId) {
        button.disabled = true;
        list.className = 'schedule-list muted';
        list.textContent = 'Salvați evenimentul înainte de a programa prețuri.';
        return;
    }

    button.disabled = false;
    list.className = 'schedule-list muted';
    list.textContent = 'Se încarcă prețurile programate...';

    try {
        const prices = await API.get(`/events/${currentEventId}/prices`);
        renderEventPriceSchedule(prices || []);
    } catch (err) {
        list.textContent = 'Nu am putut încărca prețurile programate.';
        setEventPriceStatus(err.message, 'error');
    }
}

function renderEventPriceSchedule(prices) {
    const list = document.getElementById('event_price_schedule_list');
    if (!list) return;

    if (!prices.length) {
        list.className = 'schedule-list muted';
        list.textContent = 'Nu există prețuri programate pentru acest eveniment.';
        return;
    }

    list.className = 'schedule-list';
    list.innerHTML = `
        <table class="compact-table">
            <thead>
                <tr>
                    <th>Tip</th>
                    <th>Preț</th>
                    <th>Monedă</th>
                    <th>Activ de la</th>
                    <th>Creat la</th>
                </tr>
            </thead>
            <tbody>
                ${prices.map(item => `
                    <tr>
                        <td>${escapeHTML(item.price_type || '-')}</td>
                        <td>${escapeHTML(formatScheduledPrice(item))}</td>
                        <td>${escapeHTML(item.currency || 'RON')}</td>
                        <td>${escapeHTML(formatDateTime(item.effective_from))}</td>
                        <td>${escapeHTML(formatDateTime(item.created_at))}</td>
                    </tr>
                `).join('')}
            </tbody>
        </table>
    `;
}

function showEventPriceForm() {
    if (!currentEventId) {
        setEventPriceStatus('Salvați evenimentul înainte de a programa prețuri.', 'error');
        return;
    }

    document.getElementById('event_future_price_type').value = 'paid';
    document.getElementById('event_future_price_amount').value = '';
    document.getElementById('event_future_price_currency').value = 'RON';
    document.getElementById('event_future_price_effective_from').value = '';
    syncFuturePriceAmountState();
    setEventPriceStatus('');
    document.getElementById('event_price_form').style.display = 'block';
}

function hideEventPriceForm() {
    const form = document.getElementById('event_price_form');
    if (form) form.style.display = 'none';
}

function syncFuturePriceAmountState() {
    const type = document.getElementById('event_future_price_type').value;
    const amountInput = document.getElementById('event_future_price_amount');
    if (type === 'free') {
        amountInput.value = '';
        amountInput.disabled = true;
        amountInput.required = false;
    } else {
        amountInput.disabled = false;
        amountInput.required = true;
    }
}

function buildFuturePricePayload() {
    const priceType = document.getElementById('event_future_price_type').value;
    const amount = floatOrNull('event_future_price_amount');
    const effectiveFrom = dateTimeOrNull('event_future_price_effective_from');

    if (!effectiveFrom) {
        throw new Error('Completați data și ora de la care prețul devine activ.');
    }
    if (priceType === 'free' && amount !== null) {
        throw new Error('Pentru gratuit, valoarea trebuie să fie goală.');
    }
    if (priceType !== 'free' && (amount === null || amount < 0)) {
        throw new Error('Pentru preț plătit sau abonament, valoarea trebuie completată și să fie >= 0.');
    }

    return {
        price_type: priceType,
        price_amount: priceType === 'free' ? null : amount,
        currency: valueOrNull('event_future_price_currency') || 'RON',
        effective_from: effectiveFrom,
    };
}

async function saveEventFuturePrice() {
    if (!currentEventId) {
        setEventPriceStatus('Salvați evenimentul înainte de a programa prețuri.', 'error');
        return;
    }

    try {
        const payload = buildFuturePricePayload();
        await API.post(`/events/${currentEventId}/prices`, payload);
        hideEventPriceForm();
        await loadEventPriceSchedule();
        setEventPriceStatus('Preț viitor programat cu succes.', 'success');
    } catch (err) {
        setEventPriceStatus(err.message, 'error');
        showAlert('Eroare la programarea prețului: ' + err.message, 'error');
    }
}

function renderEventPartners(selectedPartners) {
    const container = document.getElementById('event_partners_list');
    if (!container) return;

    selectedEventPartnerIds = (selectedPartners || [])
        .slice()
        .sort((a, b) => (a.display_order ?? 0) - (b.display_order ?? 0))
        .map(item => Number(item.partner_id || item.id))
        .filter(partnerId => allEventPartners.some(partner => Number(partner.id) === partnerId));

    if (!allEventPartners.length) {
        container.className = 'partner-selector empty muted';
        container.textContent = 'Nu există parteneri definiți încă.';
        return;
    }

    container.className = 'partner-selector';
    container.innerHTML = '';

    const picker = document.createElement('div');
    picker.className = 'partner-picker';

    allEventPartners.forEach(partner => {
        const row = document.createElement('div');
        row.className = 'partner-option';

        const label = document.createElement('label');
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.className = 'event-partner-checkbox';
        checkbox.value = partner.id;
        checkbox.checked = selectedEventPartnerIds.includes(Number(partner.id));

        const name = document.createElement('span');
        name.className = 'partner-name';
        name.textContent = partner.name;
        label.append(checkbox, name);

        checkbox.addEventListener('change', () => {
            const partnerId = Number(partner.id);
            if (checkbox.checked && !selectedEventPartnerIds.includes(partnerId)) {
                selectedEventPartnerIds.push(partnerId);
            }
            if (!checkbox.checked) {
                selectedEventPartnerIds = selectedEventPartnerIds.filter(id => id !== partnerId);
            }
            renderSelectedEventPartners();
        });

        row.append(label);
        picker.appendChild(row);
    });

    const selectedTitle = document.createElement('div');
    selectedTitle.className = 'selected-partners-title';
    selectedTitle.textContent = 'Parteneri selectați';

    const selectedList = document.createElement('div');
    selectedList.id = 'selected_event_partners';
    selectedList.className = 'selected-partner-list';
    selectedList.addEventListener('dragover', handleSelectedPartnerDragOver);
    selectedList.addEventListener('drop', handleSelectedPartnerDrop);

    container.append(picker, selectedTitle, selectedList);
    renderSelectedEventPartners();
}

function renderSelectedEventPartners() {
    const list = document.getElementById('selected_event_partners');
    if (!list) return;

    list.innerHTML = '';
    const selectedPartners = selectedEventPartnerIds
        .map(id => allEventPartners.find(partner => Number(partner.id) === id))
        .filter(Boolean);

    if (!selectedPartners.length) {
        list.classList.add('empty');
        list.textContent = 'Niciun partener selectat.';
        return;
    }

    list.classList.remove('empty');
    selectedPartners.forEach((partner, index) => {
        const item = document.createElement('div');
        item.className = 'selected-partner-item';
        item.draggable = true;
        item.dataset.partnerId = partner.id;

        const handle = document.createElement('span');
        handle.className = 'drag-handle';
        handle.textContent = '⋮⋮';
        handle.setAttribute('aria-hidden', 'true');

        const order = document.createElement('span');
        order.className = 'partner-order-index';
        order.textContent = String(index + 1);

        const name = document.createElement('span');
        name.className = 'partner-name';
        name.textContent = partner.name;

        const removeButton = document.createElement('button');
        removeButton.type = 'button';
        removeButton.className = 'partner-remove-btn';
        removeButton.textContent = 'Elimină';
        removeButton.addEventListener('click', () => removeSelectedEventPartner(Number(partner.id)));

        item.addEventListener('dragstart', handleSelectedPartnerDragStart);
        item.addEventListener('dragend', handleSelectedPartnerDragEnd);
        item.append(handle, order, name, removeButton);
        list.appendChild(item);
    });
}

function removeSelectedEventPartner(partnerId) {
    selectedEventPartnerIds = selectedEventPartnerIds.filter(id => id !== partnerId);
    const checkbox = document.querySelector(`.event-partner-checkbox[value="${partnerId}"]`);
    if (checkbox) checkbox.checked = false;
    renderSelectedEventPartners();
}

function handleSelectedPartnerDragStart(event) {
    draggedEventPartnerId = Number(event.currentTarget.dataset.partnerId);
    event.currentTarget.classList.add('dragging');
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('text/plain', String(draggedEventPartnerId));
}

function handleSelectedPartnerDragEnd(event) {
    event.currentTarget.classList.remove('dragging');
    draggedEventPartnerId = null;
}

function handleSelectedPartnerDragOver(event) {
    event.preventDefault();
    event.dataTransfer.dropEffect = 'move';
}

function handleSelectedPartnerDrop(event) {
    event.preventDefault();
    const sourceId = draggedEventPartnerId || Number(event.dataTransfer.getData('text/plain'));
    if (!sourceId) return;

    const targetItem = event.target.closest('.selected-partner-item');
    const targetId = targetItem ? Number(targetItem.dataset.partnerId) : null;
    if (sourceId === targetId) return;

    selectedEventPartnerIds = selectedEventPartnerIds.filter(id => id !== sourceId);
    if (targetId) {
        const targetIndex = selectedEventPartnerIds.indexOf(targetId);
        const rect = targetItem.getBoundingClientRect();
        const insertAfterTarget = event.clientY > rect.top + rect.height / 2;
        selectedEventPartnerIds.splice(targetIndex + (insertAfterTarget ? 1 : 0), 0, sourceId);
    } else {
        selectedEventPartnerIds.push(sourceId);
    }
    renderSelectedEventPartners();
}

function getSelectedEventPartners() {
    return selectedEventPartnerIds.map((partnerId, index) => ({
        partner_id: partnerId,
        display_order: index,
    }));
}

function fillPublicationFields(publication) {
    document.getElementById('publication_name').value = publication.name || '';
    document.getElementById('publication_logo_url').value = publication.logo_url || '';
    document.getElementById('publication_description').value = publication.description || '';
    document.getElementById('publication_emc_credits_text').value = publication.emc_credits_text || '';
    document.getElementById('publication_creditation_text').value = publication.creditation_text || '';
    document.getElementById('publication_indexing_text').value = publication.indexing_text || '';
    document.getElementById('publication_subscription_url').value = publication.subscription_url || '';
    renderPublicationAuthors(publication.authors || []);
    updateImagePreview('publication_logo_url');
}

function authorFullName(author) {
    return `${author.first_name || ''} ${author.last_name || ''}`.trim();
}

function renderPublicationAuthors(selectedAuthors) {
    const container = document.getElementById('publication_authors_list');
    if (!container) return;

    selectedPublicationAuthors = (selectedAuthors || [])
        .slice()
        .sort((a, b) => (a.display_order ?? 1) - (b.display_order ?? 1))
        .map(item => ({
            author_id: Number(item.author_id || item.id),
            role: item.role || 'author',
        }))
        .filter(item => allAuthors.some(author => Number(author.id) === item.author_id));

    if (!allAuthors.length) {
        container.className = 'partner-selector empty muted';
        container.textContent = 'Nu există autori definiți încă.';
        return;
    }

    container.className = 'partner-selector';
    container.innerHTML = '';

    const picker = document.createElement('div');
    picker.className = 'partner-picker';

    allAuthors.forEach(author => {
        const row = document.createElement('div');
        row.className = 'partner-option';

        const label = document.createElement('label');
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.className = 'publication-author-checkbox';
        checkbox.value = author.id;
        checkbox.checked = selectedPublicationAuthors.some(item => item.author_id === Number(author.id));

        const name = document.createElement('span');
        name.className = 'partner-name';
        name.textContent = authorFullName(author);
        label.append(checkbox, name);

        checkbox.addEventListener('change', () => {
            const authorId = Number(author.id);
            if (checkbox.checked && !selectedPublicationAuthors.some(item => item.author_id === authorId)) {
                selectedPublicationAuthors.push({ author_id: authorId, role: 'author' });
            }
            if (!checkbox.checked) {
                selectedPublicationAuthors = selectedPublicationAuthors.filter(item => item.author_id !== authorId);
            }
            renderSelectedPublicationAuthors();
        });

        row.append(label);
        picker.appendChild(row);
    });

    const selectedTitle = document.createElement('div');
    selectedTitle.className = 'selected-partners-title';
    selectedTitle.textContent = 'Autori selectați';

    const selectedList = document.createElement('div');
    selectedList.id = 'selected_publication_authors';
    selectedList.className = 'selected-partner-list';
    selectedList.addEventListener('dragover', handleSelectedAuthorDragOver);
    selectedList.addEventListener('drop', handleSelectedAuthorDrop);

    container.append(picker, selectedTitle, selectedList);
    renderSelectedPublicationAuthors();
}

function renderSelectedPublicationAuthors() {
    const list = document.getElementById('selected_publication_authors');
    if (!list) return;

    list.innerHTML = '';
    const selectedAuthors = selectedPublicationAuthors
        .map(link => ({
            ...link,
            author: allAuthors.find(author => Number(author.id) === link.author_id),
        }))
        .filter(item => item.author);

    if (!selectedAuthors.length) {
        list.classList.add('empty');
        list.textContent = 'Niciun autor selectat.';
        return;
    }

    list.classList.remove('empty');
    selectedAuthors.forEach((link, index) => {
        const item = document.createElement('div');
        item.className = 'selected-partner-item selected-author-item';
        item.draggable = true;
        item.dataset.authorId = link.author_id;

        const handle = document.createElement('span');
        handle.className = 'drag-handle';
        handle.textContent = '⋮⋮';
        handle.setAttribute('aria-hidden', 'true');

        const order = document.createElement('span');
        order.className = 'partner-order-index';
        order.textContent = String(index + 1);

        const name = document.createElement('span');
        name.className = 'partner-name';
        name.textContent = authorFullName(link.author);

        const roleInput = document.createElement('input');
        roleInput.className = 'author-role-input';
        roleInput.setAttribute('list', 'author_role_options');
        roleInput.placeholder = 'Rol';
        roleInput.value = link.role || '';
        roleInput.addEventListener('input', () => {
            const current = selectedPublicationAuthors.find(item => item.author_id === link.author_id);
            if (current) current.role = roleInput.value;
        });

        const removeButton = document.createElement('button');
        removeButton.type = 'button';
        removeButton.className = 'partner-remove-btn';
        removeButton.textContent = 'Elimină';
        removeButton.addEventListener('click', () => removeSelectedPublicationAuthor(link.author_id));

        item.addEventListener('dragstart', handleSelectedAuthorDragStart);
        item.addEventListener('dragend', handleSelectedAuthorDragEnd);
        item.append(handle, order, name, roleInput, removeButton);
        list.appendChild(item);
    });
}

function removeSelectedPublicationAuthor(authorId) {
    selectedPublicationAuthors = selectedPublicationAuthors.filter(item => item.author_id !== authorId);
    const checkbox = document.querySelector(`.publication-author-checkbox[value="${authorId}"]`);
    if (checkbox) checkbox.checked = false;
    renderSelectedPublicationAuthors();
}

function handleSelectedAuthorDragStart(event) {
    draggedPublicationAuthorId = Number(event.currentTarget.dataset.authorId);
    event.currentTarget.classList.add('dragging');
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('text/plain', String(draggedPublicationAuthorId));
}

function handleSelectedAuthorDragEnd(event) {
    event.currentTarget.classList.remove('dragging');
    draggedPublicationAuthorId = null;
}

function handleSelectedAuthorDragOver(event) {
    event.preventDefault();
    event.dataTransfer.dropEffect = 'move';
}

function handleSelectedAuthorDrop(event) {
    event.preventDefault();
    const sourceId = draggedPublicationAuthorId || Number(event.dataTransfer.getData('text/plain'));
    if (!sourceId) return;

    const targetItem = event.target.closest('.selected-author-item');
    const targetId = targetItem ? Number(targetItem.dataset.authorId) : null;
    if (sourceId === targetId) return;

    const source = selectedPublicationAuthors.find(item => item.author_id === sourceId);
    if (!source) return;

    selectedPublicationAuthors = selectedPublicationAuthors.filter(item => item.author_id !== sourceId);
    if (targetId) {
        const targetIndex = selectedPublicationAuthors.findIndex(item => item.author_id === targetId);
        const rect = targetItem.getBoundingClientRect();
        const insertAfterTarget = event.clientY > rect.top + rect.height / 2;
        selectedPublicationAuthors.splice(targetIndex + (insertAfterTarget ? 1 : 0), 0, source);
    } else {
        selectedPublicationAuthors.push(source);
    }
    renderSelectedPublicationAuthors();
}

function getSelectedPublicationAuthors() {
    return selectedPublicationAuthors.map((link, index) => ({
        author_id: link.author_id,
        role: link.role?.trim() || null,
        display_order: index + 1,
    }));
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
        interest_ids: selectedContentInterestIds.slice(),
        notify_interested_users: document.getElementById('notify_interested_users').checked,
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
        payload.partners = getSelectedEventPartners();
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
        payload.authors = getSelectedPublicationAuthors();
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
    if (payload.notify_interested_users && (!payload.interest_ids || payload.interest_ids.length === 0)) {
        throw new Error('Selectează cel puțin un interes pentru a trimite notificarea utilizatorilor interesați.');
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
    UI.showAlert('alert-msg', msg, type);
}
