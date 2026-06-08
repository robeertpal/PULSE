let subscriptionPlans = [];
let publicationOptions = [];

document.addEventListener('DOMContentLoaded', async () => {
    UI.init('subscriptions', 'Abonamente');
    document.getElementById('subscription_scope').addEventListener('change', updatePublicationFieldVisibility);
    await Promise.all([loadPublicationOptions(), loadSubscriptionPlans()]);
    updatePublicationFieldVisibility();
});

function escapeHTML(value) {
    return String(value ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

function valueOrNull(id) {
    const value = document.getElementById(id).value.trim();
    return value === '' ? null : value;
}

function formatDate(value) {
    if (!value) return '-';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return value;
    return date.toLocaleDateString('ro-RO', {
        year: 'numeric',
        month: 'short',
        day: '2-digit',
    });
}

function formatPrice(value) {
    const amount = Number(value ?? 0);
    return Number.isFinite(amount) ? amount.toFixed(2) : '0.00';
}

function scopeLabel(scope) {
    return scope === 'publication' ? 'Revistă' : 'Platformă';
}

async function loadPublicationOptions() {
    const select = document.getElementById('subscription_publication_id');
    try {
        publicationOptions = await API.get('/admin/publications/options');
        select.innerHTML = '<option value="">Alege revista</option>';
        publicationOptions.forEach((publication) => {
            const option = document.createElement('option');
            option.value = publication.id;
            option.textContent = publication.label || publication.name || publication.title || `Publicație #${publication.id}`;
            select.appendChild(option);
        });
    } catch (err) {
        select.innerHTML = '<option value="">Nu s-au putut încărca publicațiile</option>';
        UI.showAlert('alert-msg', 'Eroare la încărcarea publicațiilor: ' + err.message, 'error');
    }
}

async function loadSubscriptionPlans() {
    const tbody = document.getElementById('subscriptions-table-body');
    try {
        subscriptionPlans = await API.get('/admin/subscription-plans');
        renderSubscriptionPlans();
    } catch (err) {
        tbody.innerHTML = `<tr><td colspan="10">${escapeHTML(err.message)}</td></tr>`;
    }
}

function renderSubscriptionPlans() {
    const tbody = document.getElementById('subscriptions-table-body');
    tbody.innerHTML = '';

    if (!subscriptionPlans.length) {
        tbody.innerHTML = '<tr><td colspan="10">Nu există abonamente.</td></tr>';
        return;
    }

    subscriptionPlans.forEach((plan) => {
        const tr = document.createElement('tr');
        const activeLabel = plan.is_active ? 'Activ' : 'Inactiv';
        const activeClass = plan.is_active ? 'active' : 'archived';
        const toggleLabel = plan.is_active ? 'Dezactivează' : 'Activează';
        const scope = plan.scope || 'platform';
        const scopeClass = scope === 'publication' ? 'published' : 'draft';

        tr.innerHTML = `
            <td><strong>${escapeHTML(plan.name)}</strong></td>
            <td><span class="subscription-code">${escapeHTML(plan.code)}</span></td>
            <td><span class="badge ${scopeClass}">${escapeHTML(plan.scope_label || scopeLabel(scope))}</span></td>
            <td>${escapeHTML(plan.publication_label || '-')}</td>
            <td class="price-cell">${escapeHTML(formatPrice(plan.price))}</td>
            <td>${escapeHTML(plan.currency || 'RON')}</td>
            <td>${escapeHTML(plan.billing_period)}</td>
            <td><span class="badge ${activeClass}">${activeLabel}</span></td>
            <td>${escapeHTML(formatDate(plan.created_at))}</td>
            <td class="table-actions">
                <button type="button" onclick="editSubscriptionPlan(${plan.id})">Editare</button>
                <button type="button" onclick="toggleSubscriptionPlan(${plan.id})">${toggleLabel}</button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

function updatePublicationFieldVisibility() {
    const scope = document.getElementById('subscription_scope').value;
    const field = document.getElementById('publication-field');
    const select = document.getElementById('subscription_publication_id');
    const isPublication = scope === 'publication';
    field.style.display = isPublication ? 'block' : 'none';
    select.required = isPublication;
    if (!isPublication) select.value = '';
}

function newSubscriptionPlan() {
    document.getElementById('subscription-form').reset();
    document.getElementById('subscription_plan_id').value = '';
    document.getElementById('subscription_currency').value = 'RON';
    document.getElementById('subscription_billing_period').value = 'monthly';
    document.getElementById('subscription_scope').value = 'platform';
    document.getElementById('subscription_is_active').checked = true;
    updatePublicationFieldVisibility();
    document.getElementById('subscription-form-card').style.display = 'block';
    document.getElementById('subscription_name').focus();
}

function editSubscriptionPlan(id) {
    const plan = subscriptionPlans.find((item) => Number(item.id) === Number(id));
    if (!plan) return;

    document.getElementById('subscription_plan_id').value = plan.id;
    document.getElementById('subscription_name').value = plan.name || '';
    document.getElementById('subscription_code').value = plan.code || '';
    document.getElementById('subscription_price').value = plan.price ?? 0;
    document.getElementById('subscription_currency').value = plan.currency || 'RON';
    document.getElementById('subscription_billing_period').value = plan.billing_period || 'monthly';
    document.getElementById('subscription_scope').value = plan.scope || 'platform';
    document.getElementById('subscription_publication_id').value = plan.publication_id || '';
    document.getElementById('subscription_is_active').checked = plan.is_active !== false;
    updatePublicationFieldVisibility();
    document.getElementById('subscription-form-card').style.display = 'block';
    document.getElementById('subscription_name').focus();
}

function cancelSubscriptionPlanEdit() {
    document.getElementById('subscription-form-card').style.display = 'none';
}

function buildSubscriptionPlanPayload() {
    const name = valueOrNull('subscription_name');
    const code = valueOrNull('subscription_code');
    const price = Number(document.getElementById('subscription_price').value);
    const currency = valueOrNull('subscription_currency') || 'RON';
    const billingPeriod = valueOrNull('subscription_billing_period');
    const scope = document.getElementById('subscription_scope').value;
    const publicationId = document.getElementById('subscription_publication_id').value;

    if (!name) throw new Error('Completează numele abonamentului.');
    if (!code) throw new Error('Completează codul unic.');
    if (!Number.isFinite(price) || price < 0) throw new Error('Prețul trebuie să fie mai mare sau egal cu 0.');
    if (!currency) throw new Error('Completează moneda.');
    if (!billingPeriod) throw new Error('Completează perioada de facturare.');
    if (scope === 'publication' && !publicationId) throw new Error('Alege revista pentru abonamentul de tip Revistă.');

    return {
        name,
        code,
        price,
        currency,
        billing_period: billingPeriod,
        scope,
        publication_id: scope === 'publication' ? Number(publicationId) : null,
        is_active: document.getElementById('subscription_is_active').checked,
    };
}

async function saveSubscriptionPlan() {
    const id = document.getElementById('subscription_plan_id').value;
    try {
        const payload = buildSubscriptionPlanPayload();
        if (id) {
            await API.put(`/admin/subscription-plans/${id}`, payload);
            UI.showAlert('alert-msg', 'Abonamentul a fost actualizat.', 'success');
        } else {
            await API.post('/admin/subscription-plans', payload);
            UI.showAlert('alert-msg', 'Abonamentul a fost creat.', 'success');
        }
        cancelSubscriptionPlanEdit();
        await loadSubscriptionPlans();
    } catch (err) {
        UI.showAlert('alert-msg', 'Eroare: ' + err.message, 'error');
    }
}

async function toggleSubscriptionPlan(id) {
    const plan = subscriptionPlans.find((item) => Number(item.id) === Number(id));
    if (!plan) return;
    const action = plan.is_active ? 'dezactivezi' : 'activezi';
    if (!confirm(`Sigur vrei să ${action} acest abonament?`)) return;

    try {
        await API.patch(`/admin/subscription-plans/${id}/toggle-active`, {});
        UI.showAlert('alert-msg', 'Statusul abonamentului a fost actualizat.', 'success');
        await loadSubscriptionPlans();
    } catch (err) {
        UI.showAlert('alert-msg', 'Eroare la actualizarea statusului: ' + err.message, 'error');
    }
}
