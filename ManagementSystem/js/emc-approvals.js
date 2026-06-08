const state = {
    courses: [],
    selectedCourseId: null,
    selectedCourse: null,
    participants: [],
    selectedUserIds: new Set(),
    searchTerm: '',
    isSubmitting: false,
};

const $ = (id) => document.getElementById(id);

function escapeHtml(value) {
    return String(value ?? '').replace(/[&<>"']/g, (char) => ({
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;',
    }[char]));
}

function formatDate(value) {
    if (!value) return '-';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return '-';
    return new Intl.DateTimeFormat('ro-RO', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
    }).format(date);
}

function formatPeriod(course) {
    return `${formatDate(course.valid_from)} - ${formatDate(course.valid_until)}`;
}

function statusBadge(course) {
    return `<span class="badge emc-${escapeHtml(course.emc_status_code || 'unprocessed')}">${escapeHtml(course.emc_status || 'Neprocesat')}</span>`;
}

function participantStatusLabel(status, progress) {
    const labels = {
        enrolled: 'Înscris',
        in_progress: 'În progres',
        completed: 'Finalizat',
        cancelled: 'Anulat',
    };
    const label = labels[status] || status || '-';
    return progress === null || progress === undefined ? label : `${label} (${progress}%)`;
}

function pendingParticipants() {
    return state.participants.filter((participant) => !participant.emc_awarded);
}

function filteredParticipants() {
    const term = state.searchTerm.trim().toLowerCase();
    if (!term) return state.participants;
    return state.participants.filter((participant) => {
        const name = String(participant.name || '').toLowerCase();
        const email = String(participant.email || '').toLowerCase();
        return name.includes(term) || email.includes(term);
    });
}

function renderCourses() {
    const tbody = $('courses-table-body');
    if (!state.courses.length) {
        tbody.innerHTML = '<tr><td colspan="8" class="empty-cell">Nu există cursuri finalizate.</td></tr>';
        return;
    }

    tbody.innerHTML = state.courses.map((course) => `
        <tr class="${Number(course.course_id) === Number(state.selectedCourseId) ? 'selected-row' : ''}">
            <td><strong>${escapeHtml(course.title)}</strong></td>
            <td>${escapeHtml(formatPeriod(course))}</td>
            <td>${escapeHtml(course.provider || '-')}</td>
            <td>${escapeHtml(course.emc_credits ?? 0)}</td>
            <td>${escapeHtml(course.total_participants ?? 0)}</td>
            <td>${escapeHtml(course.awarded_count ?? 0)} / ${escapeHtml(course.total_participants ?? 0)}</td>
            <td>${statusBadge(course)}</td>
            <td class="table-actions">
                <button type="button" data-open-course="${course.course_id}">Detalii</button>
            </td>
        </tr>
    `).join('');
}

function renderCourseDetail() {
    const panel = $('course-detail-panel');
    if (!state.selectedCourse) {
        panel.hidden = true;
        return;
    }

    panel.hidden = false;
    $('detail-title').textContent = state.selectedCourse.title || 'Detalii curs';
    $('detail-meta').textContent = `${formatPeriod(state.selectedCourse)} · ${state.selectedCourse.provider || 'Provider necompletat'} · ${state.selectedCourse.emc_credits || 0} puncte EMC`;
    renderParticipants();
}

function renderParticipants() {
    const tbody = $('participants-table-body');
    const participants = filteredParticipants();
    if (!participants.length) {
        tbody.innerHTML = '<tr><td colspan="6" class="empty-cell">Nu există participanți pentru filtrul curent.</td></tr>';
        updateSelectionSummary();
        return;
    }

    tbody.innerHTML = participants.map((participant) => {
        const isAwarded = participant.emc_awarded === true;
        const isChecked = state.selectedUserIds.has(Number(participant.user_id));
        return `
            <tr class="${isAwarded ? 'muted-row' : ''}">
                <td>
                    <input
                        type="checkbox"
                        data-user-id="${participant.user_id}"
                        ${isChecked ? 'checked' : ''}
                        ${isAwarded || state.isSubmitting ? 'disabled' : ''}
                        aria-label="Selectează participant"
                    >
                </td>
                <td><strong>${escapeHtml(participant.name || '-')}</strong></td>
                <td>${escapeHtml(participant.email || '-')}</td>
                <td>${escapeHtml(formatDate(participant.enrolled_at))}</td>
                <td>${escapeHtml(participantStatusLabel(participant.participation_status, participant.progress_percent))}</td>
                <td>${isAwarded ? '<span class="badge emc-completed">EMC acordat</span>' : '<span class="badge emc-unprocessed">Neacordat</span>'}</td>
            </tr>
        `;
    }).join('');
    updateSelectionSummary();
}

function updateSelectionSummary() {
    const selectedCount = state.selectedUserIds.size;
    const pendingCount = pendingParticipants().length;
    $('selection-summary').textContent = `${selectedCount} selectați · ${pendingCount} fără EMC acordat`;
    $('award-selected-btn').disabled = state.isSubmitting || selectedCount === 0;
    $('award-all-btn').disabled = state.isSubmitting || pendingCount === 0;
    $('select-all-btn').disabled = state.isSubmitting || pendingCount === 0;
}

async function loadCourses() {
    UI.hideAlert('error-msg');
    try {
        state.courses = await API.get('/admin/emc-approvals/courses');
        renderCourses();
    } catch (error) {
        UI.showError('error-msg', error.message);
    }
}

async function openCourse(courseId) {
    UI.hideAlert('error-msg');
    UI.hideAlert('success-msg');
    state.selectedCourseId = Number(courseId);
    state.selectedUserIds.clear();
    renderCourses();
    $('participants-table-body').innerHTML = '<tr><td colspan="6">Se încarcă...</td></tr>';
    $('course-detail-panel').hidden = false;

    try {
        const data = await API.get(`/admin/emc-approvals/courses/${courseId}`);
        state.selectedCourse = data.course;
        state.participants = data.participants || [];
        renderCourses();
        renderCourseDetail();
    } catch (error) {
        UI.showError('error-msg', error.message);
    }
}

function selectAllPending() {
    pendingParticipants().forEach((participant) => {
        state.selectedUserIds.add(Number(participant.user_id));
    });
    renderParticipants();
}

async function awardUsers(userIds) {
    if (!state.selectedCourseId || state.isSubmitting) return;
    const uniqueUserIds = [...new Set(userIds.map(Number).filter(Boolean))];
    if (!uniqueUserIds.length) {
        UI.showError('error-msg', 'Selectează cel puțin un participant.');
        return;
    }

    const points = state.selectedCourse?.emc_credits || 0;
    const confirmed = window.confirm(`Acorzi ${points} puncte EMC pentru ${uniqueUserIds.length} participant(i)?`);
    if (!confirmed) return;

    state.isSubmitting = true;
    updateSelectionSummary();
    UI.hideAlert('error-msg');
    UI.hideAlert('success-msg');

    try {
        const result = await API.post(`/admin/emc-approvals/courses/${state.selectedCourseId}/award`, {
            user_ids: uniqueUserIds,
        });
        const successMessage = result.message || 'Punctele EMC au fost acordate.';
        state.isSubmitting = false;
        await loadCourses();
        await openCourse(state.selectedCourseId);
        UI.showAlert('success-msg', successMessage, 'success');
    } catch (error) {
        console.error('EMC award failed:', error);
        UI.showError('error-msg', error.message);
    } finally {
        state.isSubmitting = false;
        updateSelectionSummary();
    }
}

document.addEventListener('DOMContentLoaded', async () => {
    UI.init('emc-approvals', 'Aprobări EMC');
    await loadCourses();

    $('refresh-courses-btn').addEventListener('click', loadCourses);
    $('close-detail-btn').addEventListener('click', () => {
        state.selectedCourseId = null;
        state.selectedCourse = null;
        state.participants = [];
        state.selectedUserIds.clear();
        renderCourses();
        renderCourseDetail();
    });

    $('participant-search').addEventListener('input', (event) => {
        state.searchTerm = event.target.value;
        renderParticipants();
    });

    $('select-all-btn').addEventListener('click', selectAllPending);
    $('award-selected-btn').addEventListener('click', () => awardUsers([...state.selectedUserIds]));
    $('award-all-btn').addEventListener('click', () => {
        const allPendingUserIds = pendingParticipants().map((participant) => participant.user_id);
        awardUsers(allPendingUserIds);
    });

    $('courses-table-body').addEventListener('click', (event) => {
        const button = event.target.closest('[data-open-course]');
        if (!button) return;
        openCourse(button.dataset.openCourse);
    });

    $('participants-table-body').addEventListener('change', (event) => {
        const checkbox = event.target.closest('input[type="checkbox"][data-user-id]');
        if (!checkbox) return;
        const userId = Number(checkbox.dataset.userId);
        if (checkbox.checked) {
            state.selectedUserIds.add(userId);
        } else {
            state.selectedUserIds.delete(userId);
        }
        updateSelectionSummary();
    });
});
