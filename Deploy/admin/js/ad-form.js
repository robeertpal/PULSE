const AD_TYPES = ['publication', 'event', 'course', 'article', 'news', 'other'];
const AD_STATUSES = ['draft', 'active', 'paused', 'archived'];
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
const BADGE_TEXT_OPTIONS = ['Nou', 'Recomandat', 'Sponsor', 'Eveniment', 'Curs EMC', 'Revistă', 'Promovat'];
const ACCENT_COLOR_OPTIONS = ['#2563EB', '#0F766E', '#7C3AED', '#DC2626', '#EA580C'];

let adTemplates = [];
let isSyncingDesignJson = false;

document.addEventListener('DOMContentLoaded', async () => {
    UI.init('ads', 'Adaugă / Editează Reclamă');
    fillEnumSelect('ad_type', AD_TYPES);
    fillEnumSelect('status', AD_STATUSES);
    fillEnumSelect('placement', AD_PLACEMENTS);
    document.getElementById('status').value = 'draft';
    document.getElementById('placement').value = 'home_between_sections';

    bindFormEvents();
    populateDesignUIFromConfig({});
    await loadAdTemplates();
    syncDesignJsonFromUI();
    updateAdPreview();

    const urlParams = new URLSearchParams(window.location.search);
    const id = urlParams.get('id');
    if (id) {
        document.getElementById('ad-id').value = id;
        await loadAd(id);
    } else {
        await loadContentOptions(document.getElementById('ad_type').value);
    }

    toggleRelatedContent();
    syncDesignJsonFromUI();
    updateAdPreview();
});

function fillEnumSelect(id, values) {
    const select = document.getElementById(id);
    select.innerHTML = '';
    values.forEach(value => {
        const option = document.createElement('option');
        option.value = value;
        option.textContent = value;
        select.appendChild(option);
    });
}

function bindFormEvents() {
    document.getElementById('ad_type').addEventListener('change', async () => {
        document.getElementById('related_content_item_id').value = '';
        toggleRelatedContent();
        await loadContentOptions(document.getElementById('ad_type').value);
        updateAdPreview();
    });

    [
        'title',
        'description',
        'image_url',
        'sponsor_logo_url',
        'cta_label',
        'ad_design_template_id',
        'sponsor_name',
    ].forEach(id => {
        document.getElementById(id).addEventListener('input', updateAdPreview);
        document.getElementById(id).addEventListener('change', updateAdPreview);
    });

    [
        'show_badge',
        'badge_text_preset',
        'badge_text_custom',
        'accent_color_preset',
        'accent_color_picker',
        'accent_color_custom',
        'animation',
        'text_position',
        'image_overlay',
        'show_sponsor_logo',
    ].forEach(id => {
        document.getElementById(id).addEventListener('input', handleDesignUIChange);
        document.getElementById(id).addEventListener('change', handleDesignUIChange);
    });

    document.getElementById('accent_color_picker').addEventListener('input', () => {
        document.getElementById('accent_color_custom').value = document.getElementById('accent_color_picker').value.toUpperCase();
    });

    document.getElementById('accent_color_custom').addEventListener('input', () => {
        const value = document.getElementById('accent_color_custom').value.trim();
        if (/^#[0-9A-Fa-f]{6}$/.test(value)) {
            document.getElementById('accent_color_picker').value = value;
        }
    });

    document.getElementById('design_config').addEventListener('input', handleAdvancedJsonInput);

    ['image_url', 'mobile_image_url', 'background_image_url', 'sponsor_logo_url'].forEach(id => {
        document.getElementById(id).addEventListener('input', () => updateImagePreview(id));
    });
}

function handleDesignUIChange() {
    toggleDesignCustomInputs();
    syncDesignJsonFromUI();
    updateAdPreview();
}

async function loadAdTemplates() {
    const select = document.getElementById('ad_design_template_id');
    select.innerHTML = '<option value="">Fără template</option>';
    try {
        adTemplates = await API.get('/admin/ad-design-templates');
    } catch (err) {
        adTemplates = [];
        console.warn('Nu s-au putut încărca template-urile de reclamă pentru preview:', err);
        return;
    }
    adTemplates.forEach(template => {
        const option = document.createElement('option');
        option.value = template.id;
        option.textContent = `${template.name} (${template.code})`;
        select.appendChild(option);
    });
}

async function loadContentOptions(type, selectedId = null) {
    const group = document.getElementById('related-content-group');
    const select = document.getElementById('related_content_item_id');

    if (type === 'other') {
        select.innerHTML = '<option value="">Fără content asociat</option>';
        group.style.display = 'none';
        return;
    }

    group.style.display = 'block';
    select.innerHTML = '<option value="">Se încarcă...</option>';

    try {
        const items = await API.get(`/admin/content-options?type=${encodeURIComponent(type || 'all')}`);
        select.innerHTML = '<option value="">Fără content asociat</option>';
        items.forEach(item => {
            const option = document.createElement('option');
            option.value = item.id;
            option.textContent = `${item.title} (${item.status || 'status nesetat'})`;
            select.appendChild(option);
        });
        if (selectedId) select.value = String(selectedId);
    } catch (err) {
        select.innerHTML = '<option value="">Eroare la încărcare</option>';
        showAlert('Eroare content asociabil: ' + err.message, 'error');
    }
}

function toggleRelatedContent() {
    const type = document.getElementById('ad_type').value;
    const group = document.getElementById('related-content-group');
    const select = document.getElementById('related_content_item_id');
    const isOther = type === 'other';
    group.style.display = isOther ? 'none' : 'block';
    select.disabled = isOther;
    if (isOther) select.value = '';
}

async function loadAd(id) {
    try {
        const ad = await API.get(`/admin/ads/${id}`);
        document.getElementById('title').value = ad.title || '';
        document.getElementById('description').value = ad.description || '';
        document.getElementById('ad_type').value = ad.ad_type || 'other';
        document.getElementById('status').value = ad.status || 'draft';
        document.getElementById('placement').value = ad.placement || 'home_between_sections';
        document.getElementById('ad_design_template_id').value = ad.ad_design_template_id || '';
        document.getElementById('image_url').value = ad.image_url || '';
        document.getElementById('mobile_image_url').value = ad.mobile_image_url || '';
        document.getElementById('background_image_url').value = ad.background_image_url || '';
        document.getElementById('sponsor_name').value = ad.sponsor_name || '';
        document.getElementById('sponsor_logo_url').value = ad.sponsor_logo_url || '';
        document.getElementById('cta_label').value = ad.cta_label || '';
        document.getElementById('cta_url').value = ad.cta_url || '';
        document.getElementById('priority').value = ad.priority ?? 0;
        document.getElementById('starts_at').value = toDateTimeLocal(ad.starts_at);
        document.getElementById('ends_at').value = toDateTimeLocal(ad.ends_at);
        document.getElementById('is_active').checked = ad.is_active !== false;
        populateDesignUIFromConfig(ad.design_config || {});

        toggleRelatedContent();
        await loadContentOptions(ad.ad_type || 'all', ad.related_content_item_id);
        ['image_url', 'mobile_image_url', 'background_image_url', 'sponsor_logo_url'].forEach(updateImagePreview);
        syncDesignJsonFromUI();
        updateAdPreview();
    } catch (err) {
        showAlert('Eroare la încărcarea reclamei: ' + err.message, 'error');
    }
}

function valueOrNull(id) {
    const value = document.getElementById(id).value.trim();
    return value === '' ? null : value;
}

function intOrNull(id) {
    const value = valueOrNull(id);
    return value === null ? null : Number.parseInt(value, 10);
}

function dateTimeOrNull(id) {
    const value = valueOrNull(id);
    return value === null ? null : new Date(value).toISOString();
}

function toDateTimeLocal(value) {
    if (!value) return '';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return '';
    const pad = number => String(number).padStart(2, '0');
    return [
        date.getFullYear(),
        pad(date.getMonth() + 1),
        pad(date.getDate()),
    ].join('-') + `T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function parseDesignConfig(raw = document.getElementById('design_config').value.trim()) {
    if (!raw) return {};
    try {
        const parsed = JSON.parse(raw);
        if (parsed === null || Array.isArray(parsed) || typeof parsed !== 'object') {
            throw new Error('design_config trebuie să fie obiect JSON.');
        }
        return parsed;
    } catch (err) {
        throw new Error('design_config nu este JSON valid: ' + err.message);
    }
}

function normalizeHexColor(value) {
    const color = (value || '').trim();
    if (!/^#[0-9A-Fa-f]{6}$/.test(color)) {
        throw new Error('Culoarea accent custom trebuie să fie în format hex, de exemplu #2563EB.');
    }
    return color.toUpperCase();
}

function getBadgeTextFromUI() {
    const preset = document.getElementById('badge_text_preset').value;
    if (preset === 'custom') {
        return valueOrNull('badge_text_custom') || 'Custom';
    }
    return preset || 'Nou';
}

function getAccentColorFromUI() {
    const preset = document.getElementById('accent_color_preset').value;
    if (preset === 'custom') {
        return normalizeHexColor(valueOrNull('accent_color_custom') || document.getElementById('accent_color_picker').value);
    }
    return preset || '#2563EB';
}

function buildDesignConfigFromUI() {
    const baseConfig = parseDesignConfig();
    return {
        ...baseConfig,
        show_badge: document.getElementById('show_badge').checked,
        badge_text: getBadgeTextFromUI(),
        accent_color: getAccentColorFromUI(),
        animation: document.getElementById('animation').value || 'none',
        text_position: document.getElementById('text_position').value || 'bottom_left',
        image_overlay: document.getElementById('image_overlay').value || 'dark_gradient',
        show_sponsor_logo: document.getElementById('show_sponsor_logo').checked,
    };
}

function populateDesignUIFromConfig(config, syncJson = true) {
    const safeConfig = config && typeof config === 'object' && !Array.isArray(config) ? config : {};
    const badgeText = safeConfig.badge_text || 'Nou';
    const accentColor = (safeConfig.accent_color || '#2563EB').toUpperCase();

    document.getElementById('show_badge').checked = safeConfig.show_badge !== false;
    if (BADGE_TEXT_OPTIONS.includes(badgeText)) {
        document.getElementById('badge_text_preset').value = badgeText;
        document.getElementById('badge_text_custom').value = '';
    } else {
        document.getElementById('badge_text_preset').value = 'custom';
        document.getElementById('badge_text_custom').value = badgeText;
    }

    if (ACCENT_COLOR_OPTIONS.includes(accentColor)) {
        document.getElementById('accent_color_preset').value = accentColor;
        document.getElementById('accent_color_custom').value = accentColor;
    } else {
        document.getElementById('accent_color_preset').value = 'custom';
        document.getElementById('accent_color_custom').value = /^#[0-9A-Fa-f]{6}$/.test(accentColor) ? accentColor : '#2563EB';
    }
    document.getElementById('accent_color_picker').value = /^#[0-9A-Fa-f]{6}$/.test(accentColor) ? accentColor : '#2563EB';

    document.getElementById('animation').value = safeConfig.animation || 'none';
    document.getElementById('text_position').value = safeConfig.text_position || 'bottom_left';
    document.getElementById('image_overlay').value = safeConfig.image_overlay || 'dark_gradient';
    document.getElementById('show_sponsor_logo').checked = safeConfig.show_sponsor_logo !== false;

    toggleDesignCustomInputs();
    if (syncJson) {
        writeDesignJson({
            ...safeConfig,
            show_badge: document.getElementById('show_badge').checked,
            badge_text: getBadgeTextFromUI(),
            accent_color: getAccentColorFromUI(),
            animation: document.getElementById('animation').value,
            text_position: document.getElementById('text_position').value,
            image_overlay: document.getElementById('image_overlay').value,
            show_sponsor_logo: document.getElementById('show_sponsor_logo').checked,
        });
    }
}

function toggleDesignCustomInputs() {
    document.getElementById('badge_text_custom').classList.toggle(
        'active',
        document.getElementById('badge_text_preset').value === 'custom',
    );
    document.getElementById('accent_color_custom_group').classList.toggle(
        'active',
        document.getElementById('accent_color_preset').value === 'custom',
    );
}

function writeDesignJson(config) {
    isSyncingDesignJson = true;
    document.getElementById('design_config').value = JSON.stringify(config, null, 2);
    isSyncingDesignJson = false;
    setDesignJsonStatus('JSON valid.', 'success');
}

function syncDesignJsonFromUI() {
    try {
        writeDesignJson(buildDesignConfigFromUI());
    } catch (err) {
        setDesignJsonStatus(err.message, 'error');
    }
}

function validateDesignConfig() {
    const config = parseDesignConfig();
    setDesignJsonStatus('JSON valid.', 'success');
    return config;
}

function handleAdvancedJsonInput() {
    if (isSyncingDesignJson) return;
    try {
        const config = validateDesignConfig();
        populateDesignUIFromConfig(config, false);
        updateAdPreview();
    } catch (err) {
        setDesignJsonStatus(err.message, 'error');
    }
}

function setDesignJsonStatus(message, type = '') {
    const status = document.getElementById('design_config_status');
    if (!status) return;
    status.textContent = message;
    status.className = `upload-status ${type}`.trim();
}

function buildPayload() {
    const adType = document.getElementById('ad_type').value;
    validateDesignConfig();
    return {
        title: valueOrNull('title'),
        description: valueOrNull('description'),
        ad_type: adType,
        status: document.getElementById('status').value,
        placement: document.getElementById('placement').value,
        ad_design_template_id: intOrNull('ad_design_template_id'),
        design_config: buildDesignConfigFromUI(),
        related_content_item_id: adType === 'other' ? null : intOrNull('related_content_item_id'),
        image_url: valueOrNull('image_url'),
        mobile_image_url: valueOrNull('mobile_image_url'),
        background_image_url: valueOrNull('background_image_url'),
        sponsor_name: valueOrNull('sponsor_name'),
        sponsor_logo_url: valueOrNull('sponsor_logo_url'),
        cta_label: valueOrNull('cta_label'),
        cta_url: valueOrNull('cta_url'),
        priority: intOrNull('priority') ?? 0,
        starts_at: dateTimeOrNull('starts_at'),
        ends_at: dateTimeOrNull('ends_at'),
        is_active: document.getElementById('is_active').checked,
    };
}

function validatePayload(payload) {
    if (!payload.title || !payload.ad_type || !payload.status || !payload.placement) {
        throw new Error('Completați titlul, tipul, statusul și placement-ul.');
    }

    if (
        payload.status === 'active'
        && payload.ad_type !== 'other'
        && !payload.related_content_item_id
        && !payload.cta_url
    ) {
        throw new Error('Pentru reclame active non-other, alegeți content asociat sau completați CTA URL.');
    }

    if (payload.starts_at && payload.ends_at && new Date(payload.starts_at) > new Date(payload.ends_at)) {
        throw new Error('Data de început trebuie să fie înainte de data de sfârșit.');
    }
}

async function saveAd() {
    const id = document.getElementById('ad-id').value;

    try {
        const payload = buildPayload();
        validatePayload(payload);

        if (id) {
            await API.put(`/admin/ads/${id}`, payload);
            showAlert('Reclamă actualizată cu succes.', 'success');
        } else {
            await API.post('/admin/ads', payload);
            showAlert('Reclamă creată cu succes.', 'success');
            setTimeout(() => window.location.href = 'ads.html', 1200);
        }
    } catch (err) {
        showAlert('Eroare: ' + err.message, 'error');
    }
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
    preview.innerHTML = url ? `<img src="${escapeAttr(url)}" alt="Preview imagine">` : '';
    updateAdPreview();
}

async function uploadImage(file, targetInputId) {
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

        const response = await fetch(`${CONFIG.API_BASE_URL}/admin/uploads/image`, {
            method: 'POST',
            headers,
            body: formData,
        });

        const data = await response.json().catch(() => ({}));
        if (!response.ok) {
            throw new Error(data.detail || data.error || data.message || `Upload eșuat: ${response.status}`);
        }

        document.getElementById(targetInputId).value = data.url;
        updateImagePreview(targetInputId);
        setUploadStatus(targetInputId, 'Upload finalizat.', 'success');
        return data;
    } catch (err) {
        setUploadStatus(targetInputId, err.message, 'error');
        throw err;
    }
}

async function uploadImageFromInput(fileInputId, targetInputId) {
    const file = document.getElementById(fileInputId).files[0];
    try {
        await uploadImage(file, targetInputId);
    } catch (err) {
        showAlert('Eroare upload imagine: ' + err.message, 'error');
    }
}

function updateAdPreview() {
    const title = valueOrNull('title') || 'Titlu reclamă';
    const description = valueOrNull('description');
    const imageUrl = getPreferredAdImageUrl();
    const logoUrl = valueOrNull('sponsor_logo_url');
    const sponsorName = valueOrNull('sponsor_name') || 'Promovat';
    const ctaLabel = valueOrNull('cta_label');
    const selectedTemplate = getSelectedAdTemplate();
    let designConfig = {};
    try {
        designConfig = buildDesignConfigFromUI();
    } catch (err) {
        designConfig = {
            show_badge: document.getElementById('show_badge').checked,
            badge_text: getBadgeTextFromUI(),
            accent_color: '#2563EB',
            animation: 'none',
            text_position: 'bottom_left',
            image_overlay: 'dark_gradient',
            show_sponsor_logo: document.getElementById('show_sponsor_logo').checked,
        };
    }
    const mergedConfig = {
        ...asPlainObject(selectedTemplate?.default_config || selectedTemplate?.template_default_config),
        ...asPlainObject(designConfig),
    };
    const templateInfo = normalizeTemplateInfo(selectedTemplate);
    const templateKind = getPreviewTemplateKind(templateInfo);
    const accentColor = sanitizeHexColor(mergedConfig.accent_color, '#2563EB');
    const hasImage = Boolean(imageUrl);
    const onDark = templateKind === 'gradient' || (templateKind === 'hero' && hasImage);
    const previewRoot = document.getElementById('ad-preview-root');

    previewRoot.innerHTML = buildAdPreviewHtml({
        title,
        description,
        imageUrl,
        logoUrl,
        sponsorName,
        ctaLabel,
        config: mergedConfig,
        templateKind,
        accentColor,
        onDark,
    });

    const card = previewRoot.querySelector('.flutter-ad-preview');
    if (card) {
        card.style.setProperty('--ad-accent', accentColor);
        card.style.setProperty('--ad-accent-soft', hexToRgba(accentColor, 0.14));
        card.style.setProperty('--ad-accent-line', hexToRgba(accentColor, 0.18));
        card.style.setProperty('--ad-accent-dark', darkenHexColor(accentColor, 0.28));
        card.style.setProperty('--ad-card-radius', `${getCornerRadius(mergedConfig)}px`);
    }

    document.getElementById('preview-template').textContent = selectedTemplate
        ? `${selectedTemplate.name} (${templateInfo.code || 'template'})`
        : 'Fără template - fallback compact';
}

function getSelectedAdTemplate() {
    const selectedId = document.getElementById('ad_design_template_id').value;
    return adTemplates.find(template => String(template.id) === selectedId) || null;
}

function getPreferredAdImageUrl() {
    return valueOrNull('mobile_image_url') || valueOrNull('image_url') || valueOrNull('background_image_url');
}

function asPlainObject(value) {
    if (value && typeof value === 'object' && !Array.isArray(value)) return value;
    return {};
}

function normalizeTemplateInfo(template) {
    return {
        code: String(template?.code || template?.template_code || '').trim(),
        layout: String(template?.layout || template?.template_layout || '').trim(),
        variant: String(template?.variant || template?.template_variant || '').trim(),
    };
}

function getPreviewTemplateKind(templateInfo) {
    const code = templateInfo.code;
    const layout = templateInfo.layout;
    const variant = templateInfo.variant;

    if (code === 'gradient_card' || variant === 'gradient' || layout === 'gradient') return 'gradient';
    if (
        code === 'hero_banner'
        || code === 'event_promo'
        || variant === 'hero'
        || variant === 'event_promo'
        || layout === 'hero'
    ) {
        return 'hero';
    }
    if (code === 'sponsor_banner' || layout === 'sponsor' || variant === 'sponsor') return 'sponsor';
    return 'compact';
}

function buildAdPreviewHtml(state) {
    const animationClass = ['fade_in', 'soft_pulse'].includes(state.config.animation) ? state.config.animation : '';
    const positionClass = getTextPositionClass(state.config.text_position);
    const darkClass = state.onDark ? 'on-dark' : '';
    const mediaHtml = state.templateKind === 'gradient' ? '' : buildMediaHtml(state.imageUrl);
    const overlayHtml = state.templateKind === 'hero' && state.imageUrl && state.config.image_overlay !== 'none'
        ? '<div class="flutter-ad-overlay"></div>'
        : '';
    const contentHtml = buildTextBlockHtml(state);

    if (state.templateKind === 'sponsor') {
        return `
            <div class="flutter-ad-preview sponsor ${animationClass} ${positionClass} ${darkClass}">
                <div class="flutter-ad-content">${contentHtml}</div>
                ${mediaHtml}
            </div>
        `;
    }

    if (state.templateKind === 'hero') {
        return `
            <div class="flutter-ad-preview hero ${animationClass} ${positionClass} ${darkClass}">
                ${mediaHtml}
                ${overlayHtml}
                <div class="flutter-ad-content">${contentHtml}</div>
            </div>
        `;
    }

    if (state.templateKind === 'gradient') {
        return `
            <div class="flutter-ad-preview gradient ${animationClass} ${positionClass} on-dark">
                <div class="flutter-ad-content">${contentHtml}</div>
            </div>
        `;
    }

    return `
        <div class="flutter-ad-preview compact ${animationClass} ${positionClass} ${darkClass}">
            ${mediaHtml}
            <div class="flutter-ad-content">${contentHtml}</div>
        </div>
    `;
}

function buildMediaHtml(imageUrl) {
    const imageHtml = imageUrl
        ? `<img src="${escapeAttr(imageUrl)}" alt="Imagine reclamă" onerror="this.parentElement.classList.add('missing');this.remove();">`
        : '';
    return `<div class="flutter-ad-media ${imageUrl ? '' : 'missing'}">${imageHtml}</div>`;
}

function buildTextBlockHtml({ title, description, logoUrl, sponsorName, ctaLabel, config, templateKind }) {
    const showBadge = config.show_badge !== false;
    const showSponsorLogo = config.show_sponsor_logo !== false && Boolean(logoUrl);
    const badgeText = config.badge_text || getDefaultBadgeText(templateKind);
    const sponsorLogoHtml = showSponsorLogo
        ? `
            <span class="flutter-ad-logo">
                <img src="${escapeAttr(logoUrl)}" alt="Logo sponsor" onerror="this.closest('.flutter-ad-logo').remove();">
            </span>
        `
        : '';
    const badgeHtml = showBadge ? `<span class="flutter-ad-badge">${escapeHtml(badgeText)}</span>` : '';
    const descriptionHtml = description
        ? `<div class="flutter-ad-description">${escapeHtml(description)}</div>`
        : '';
    const ctaHtml = ctaLabel
        ? `<div class="flutter-ad-actions"><span class="flutter-ad-cta">${escapeHtml(ctaLabel)}</span></div>`
        : '';

    return `
        <div class="flutter-ad-meta">
            ${badgeHtml}
            <span class="flutter-ad-sponsor-name">${escapeHtml(sponsorName)}</span>
            ${sponsorLogoHtml}
        </div>
        <div class="flutter-ad-title">${escapeHtml(title)}</div>
        ${descriptionHtml}
        ${ctaHtml}
    `;
}

function getDefaultBadgeText(templateKind) {
    const templateInfo = normalizeTemplateInfo(getSelectedAdTemplate());
    if (templateInfo.code === 'event_promo') return 'Eveniment';
    if (templateInfo.code === 'course_promo') return 'Curs EMC';
    if (templateInfo.code === 'publication_promo') return 'Revistă';
    if (templateInfo.code === 'sponsor_banner' || templateKind === 'sponsor') return 'Sponsor';
    return 'Promovat';
}

function getTextPositionClass(position) {
    if (position === 'center') return 'text-center';
    if (position === 'top_left') return 'text-top-left';
    return 'text-bottom-left';
}

function getCornerRadius(config) {
    const radius = Number.parseFloat(config.corner_radius);
    if (Number.isFinite(radius)) return Math.max(16, Math.min(28, radius));
    return 22;
}

function sanitizeHexColor(value, fallback) {
    const color = String(value || '').trim();
    return /^#[0-9A-Fa-f]{6}$/.test(color) ? color.toUpperCase() : fallback;
}

function hexToRgba(hex, alpha) {
    const color = sanitizeHexColor(hex, '#2563EB').slice(1);
    const red = Number.parseInt(color.slice(0, 2), 16);
    const green = Number.parseInt(color.slice(2, 4), 16);
    const blue = Number.parseInt(color.slice(4, 6), 16);
    return `rgba(${red}, ${green}, ${blue}, ${alpha})`;
}

function darkenHexColor(hex, amount) {
    const color = sanitizeHexColor(hex, '#2563EB').slice(1);
    const red = Math.round(Number.parseInt(color.slice(0, 2), 16) * (1 - amount));
    const green = Math.round(Number.parseInt(color.slice(2, 4), 16) * (1 - amount));
    const blue = Math.round(Number.parseInt(color.slice(4, 6), 16) * (1 - amount));
    return `#${toHexByte(red)}${toHexByte(green)}${toHexByte(blue)}`;
}

function toHexByte(value) {
    return Math.max(0, Math.min(255, value)).toString(16).padStart(2, '0').toUpperCase();
}

function showAlert(msg, type) {
    const alertBox = document.getElementById('alert-msg');
    alertBox.textContent = msg;
    alertBox.className = `alert ${type}`;
    alertBox.style.display = 'block';
    setTimeout(() => { alertBox.style.display = 'none'; }, 5000);
}

function escapeAttr(value) {
    return String(value ?? '')
        .replace(/&/g, '&amp;')
        .replace(/"/g, '&quot;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;');
}

function escapeHtml(value) {
    return String(value ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}
