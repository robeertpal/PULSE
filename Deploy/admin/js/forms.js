document.addEventListener('DOMContentLoaded', async () => {
    UI.init('content', 'Adaugă / Editează Conținut');
    
    const urlParams = new URLSearchParams(window.location.search);
    const id = urlParams.get('id');
    
    if (id) {
        document.getElementById('content-id').value = id;
        await loadContentData(id);
    }
});

function generateSlug() {
    const title = document.getElementById('title').value;
    const slugInput = document.getElementById('slug');
    if (!document.getElementById('content-id').value) {
        slugInput.value = title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)+/g, '');
    }
}

async function loadContentData(id) {
    try {
        const data = await API.get(`/admin/content-items/${id}`);
        
        document.getElementById('title').value = data.title;
        document.getElementById('slug').value = data.slug;
        document.getElementById('content_type').value = data.content_type;
        document.getElementById('status').value = data.status;
        document.getElementById('short_description').value = data.short_description || '';
        document.getElementById('body').value = data.body || '';
        document.getElementById('author_name').value = data.author_name || '';
        document.getElementById('hero_image_url').value = data.hero_image_url || '';
        document.getElementById('source_url').value = data.source_url || '';
        document.getElementById('is_featured').checked = data.is_featured || false;
        
    } catch (err) {
        showAlert('Eroare la încărcarea datelor: ' + err.message, 'error');
    }
}

async function saveContent() {
    const id = document.getElementById('content-id').value;
    
    const payload = {
        title: document.getElementById('title').value,
        slug: document.getElementById('slug').value,
        content_type: document.getElementById('content_type').value,
        status: document.getElementById('status').value,
        short_description: document.getElementById('short_description').value,
        body: document.getElementById('body').value,
        author_name: document.getElementById('author_name').value,
        hero_image_url: document.getElementById('hero_image_url').value,
        source_url: document.getElementById('source_url').value,
        is_featured: document.getElementById('is_featured').checked,
        is_active: true
    };
    
    if (!payload.title || !payload.slug || !payload.content_type) {
        showAlert('Completați toate câmpurile obligatorii!', 'error');
        return;
    }

    try {
        if (id) {
            await API.put(`/admin/content-items/${id}`, payload);
            showAlert('Conținut actualizat cu succes!', 'success');
        } else {
            payload.published_at = new Date().toISOString();
            await API.post('/admin/content-items', payload);
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
