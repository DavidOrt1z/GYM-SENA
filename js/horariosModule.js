/* ==================== HORARIOS MODULE ====================
   Templates de turnos + Calendario de cierres
*/

let allTemplates = [];
let calendarData = [];
let currentYear = new Date().getFullYear();
let currentMonth = new Date().getMonth() + 1; // 1-12

const MONTH_NAMES = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
const DAY_NAMES = ['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'];

function formatTimeWithPeriod(timeValue) {
    const raw = String(timeValue || '').trim();
    if (!raw) return '—';
    const hhmm = raw.substring(0, 5);
    const parts = hhmm.split(':');
    if (parts.length !== 2) return hhmm;
    const hour24 = Number(parts[0]);
    const minute = parts[1];
    if (Number.isNaN(hour24)) return hhmm;
    const period = hour24 >= 12 ? 'PM' : 'AM';
    const hour12 = hour24 % 12 === 0 ? 12 : hour24 % 12;
    return `${String(hour12).padStart(2, '0')}:${minute} ${period}`;
}

// ===================== TEMPLATES =====================

async function loadTemplates() {
    const tbody = document.getElementById('templatesBody');
    if (!tbody) return;
    tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:var(--text-muted)">Cargando...</td></tr>';
    try {
        await window.configReady;
        const slots = await getSlots();
        allTemplates = slots;
        renderTemplatesTable();
    } catch (e) {
        console.error('Error cargando templates:', e);
        tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:#FF6B6B;">Error al cargar turnos</td></tr>';
        showToast('Error al cargar turnos', 'error');
    }
}

function renderTemplatesTable() {
    const tbody = document.getElementById('templatesBody');
    if (!tbody) return;
    if (!allTemplates.length) {
        tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:var(--text-muted)">No hay turnos registrados. Crea el primero.</td></tr>';
        return;
    }
    tbody.innerHTML = allTemplates.map(t => {
        const activo = t.activo !== false;
        const badge = activo
            ? '<span class="badge-active">Activo</span>'
            : '<span class="badge-inactive">Inactivo</span>';
        return `<tr>
            <td>${t.nombre || '—'}</td>
            <td>${formatTimeWithPeriod(t.hora_inicio)}</td>
            <td>${formatTimeWithPeriod(t.hora_fin)}</td>
            <td style="text-align:center">${t.capacidad || 0}</td>
            <td>${badge}</td>
            <td class="action-btns">
                <button class="btn btn-secondary action-btn" onclick="openTemplateModal('${t.id}')">
                    <img src="assets/icons/edit.svg" alt="Editar" style="width:15px;height:15px;">
                </button>
                <button class="btn btn-danger action-btn" onclick="confirmDeleteTemplate('${t.id}')">
                    <img src="assets/icons/delete.svg" alt="Eliminar" style="width:15px;height:15px;">
                </button>
            </td>
        </tr>`;
    }).join('');
}

function openTemplateModal(templateId = null) {
    const modal = document.getElementById('templateModal');
    const title = document.getElementById('templateModalTitle');
    const form = document.getElementById('templateForm');
    if (!modal) return;

    if (templateId) {
        title.textContent = 'Editar Turno';
        const t = allTemplates.find(x => x.id === templateId || String(x.id) === String(templateId));
        if (t) {
            document.getElementById('templateNombre').value = t.nombre || '';
            document.getElementById('templateStartTime').value = (t.hora_inicio || '').substring(0, 5);
            document.getElementById('templateEndTime').value = (t.hora_fin || '').substring(0, 5);
            document.getElementById('templateCapacity').value = t.capacidad || '';
            form.dataset.templateId = templateId;
        }
    } else {
        title.textContent = 'Nuevo Turno';
        form.reset();
        delete form.dataset.templateId;
    }

    modal.classList.add('show');
    document.getElementById('templateNombre').focus();
}

function closeTemplateModal() {
    document.getElementById('templateModal')?.classList.remove('show');
}

async function submitTemplateForm(e) {
    e.preventDefault();
    const nombre = document.getElementById('templateNombre').value.trim();
    const startTime = document.getElementById('templateStartTime').value;
    const endTime = document.getElementById('templateEndTime').value;
    const capacity = parseInt(document.getElementById('templateCapacity').value, 10);

    if (!nombre) { showToast('El nombre del turno es requerido', 'error'); return; }
    if (!startTime || !endTime) { showToast('Las horas son requeridas', 'error'); return; }
    if (startTime >= endTime) { showToast('La hora inicio debe ser menor que la hora fin', 'error'); return; }
    if (!capacity || capacity < 1) { showToast('La capacidad debe ser mayor a 0', 'error'); return; }

    const form = document.getElementById('templateForm');
    const templateId = form.dataset.templateId;

    const payload = {
        nombre,
        hora_inicio: startTime + ':00',
        hora_fin: endTime + ':00',
        capacidad: capacity,
        activo: true
    };

    try {
        if (templateId) {
            const result = await updateSlot(templateId, payload);
            if (!result) throw new Error('updateSlot devolvió nulo');
            showToast('Turno actualizado correctamente', 'success');
        } else {
            const result = await createSlot(payload);
            if (!result) throw new Error('createSlot devolvió nulo');
            showToast('Turno creado correctamente', 'success');
        }
        closeTemplateModal();
        await loadTemplates();
        await loadCalendar();
    } catch (err) {
        console.error('Error guardando turno:', err);
        showToast('Error al guardar turno: ' + err.message, 'error');
    }
}

async function confirmDeleteTemplate(templateId) {
    const confirmed = await showDeleteConfirm({
        title: '¿Eliminar turno?',
        message: 'Se eliminará el turno. Las reservas existentes no se verán afectadas.',
        confirmText: 'Sí, eliminar',
        cancelText: 'Cancelar'
    });
    if (confirmed) {
        try {
            const ok = await deleteSlot(templateId);
            if (ok) {
                showToast('Turno eliminado', 'success');
                await loadTemplates();
                await loadCalendar();
            } else {
                showToast('Error al eliminar turno', 'error');
            }
        } catch (err) {
            showToast('Error al eliminar turno', 'error');
        }
    }
}

// ===================== CALENDAR =====================

async function loadCalendar() {
    const grid = document.getElementById('calendarGrid');
    const title = document.getElementById('calendarMonthTitle');
    if (!grid) return;

    const monthStr = `${currentYear}-${String(currentMonth).padStart(2, '0')}`;
    if (title) title.textContent = `${MONTH_NAMES[currentMonth - 1]} ${currentYear}`;

    grid.innerHTML = '<p style="text-align:center;color:var(--text-muted);grid-column:1/-1;padding:20px">Cargando...</p>';

    try {
        calendarData = await getCalendar(monthStr);
        renderCalendar();
    } catch (e) {
        console.error('Error cargando calendario:', e);
        grid.innerHTML = '<p style="text-align:center;color:#FF6B6B;grid-column:1/-1;padding:20px">Error al cargar calendario</p>';
    }
}

function renderCalendar() {
    const grid = document.getElementById('calendarGrid');
    if (!grid) return;

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const firstDayOfMonth = new Date(currentYear, currentMonth - 1, 1);
    // JS weekday: 0=Sun, 1=Mon ... 6=Sat. We want Mon=0
    let startOffset = (firstDayOfMonth.getDay() + 6) % 7;

    const dayMap = {};
    calendarData.forEach(d => { dayMap[d.fecha] = d; });

    let html = '';

    // Day headers
    DAY_NAMES.forEach(d => {
        html += `<div class="calendar-day-header">${d}</div>`;
    });

    // Empty cells before first day
    for (let i = 0; i < startOffset; i++) {
        html += '<div class="calendar-day empty"></div>';
    }

    // Days of month
    const daysInMonth = new Date(currentYear, currentMonth, 0).getDate();
    for (let day = 1; day <= daysInMonth; day++) {
        const fechaStr = `${currentYear}-${String(currentMonth).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
        const dayObj = dayMap[fechaStr];
        const date = new Date(currentYear, currentMonth - 1, day);
        const isPast = date < today;
        const isToday = date.getTime() === today.getTime();

        let cls = 'calendar-day';
        if (isPast) {
            cls += ' past';
        } else if (dayObj) {
            cls += ` ${dayObj.estado}`;
        } else {
            cls += ' open';
        }
        if (isToday) cls += ' today';

        const estado = dayObj?.estado || 'abierto';
        html += `<div class="${cls}" data-fecha="${fechaStr}" data-estado="${estado}" onclick="openCierreModal('${fechaStr}')" title="${fechaStr}">
            ${day}
        </div>`;
    }

    grid.innerHTML = html;
}

function prevMonth() {
    currentMonth--;
    if (currentMonth < 1) { currentMonth = 12; currentYear--; }
    loadCalendar();
}

function nextMonth() {
    currentMonth++;
    if (currentMonth > 12) { currentMonth = 1; currentYear++; }
    loadCalendar();
}

// ===================== CIERRE MODAL =====================

let selectedDate = null;

function openCierreModal(fecha) {
    selectedDate = fecha;
    const panel = document.getElementById('cierrePanel');
    const titleEl = document.getElementById('cierrePanelTitle');
    if (!panel || !titleEl) return;

    // Limpiar seleccion anterior en calendario
    document.querySelectorAll('.calendar-day.selected').forEach(d => d.classList.remove('selected'));
    // Marcar nuevo dia seleccionado
    const selectedCell = document.querySelector(`.calendar-day[data-fecha="${fecha}"]`);
    if (selectedCell) selectedCell.classList.add('selected');

    const [y, m, d] = fecha.split('-');
    titleEl.textContent = `Gestionar ${d}/${m}/${y}`;

    const dayObj = calendarData.find(x => x.fecha === fecha);
    const cierresExistentes = dayObj?.cierres || [];

    const mananaTemplates = allTemplates.filter(t => {
        const h = parseInt(t.hora_inicio?.split(':')[0]) || 0;
        return h < 13;
    });
    const tardeTemplates = allTemplates.filter(t => {
        const h = parseInt(t.hora_inicio?.split(':')[0]) || 0;
        return h >= 13;
    });

    const mananaTime = mananaTemplates.length > 0
        ? `${mananaTemplates[0].hora_inicio?.slice(0,5) || '--'} - ${mananaTemplates[mananaTemplates.length-1].hora_fin?.slice(0,5) || '--'}`
        : 'Sin turnos';
    const tardeTime = tardeTemplates.length > 0
        ? `${tardeTemplates[0].hora_inicio?.slice(0,5) || '--'} - ${tardeTemplates[tardeTemplates.length-1].hora_fin?.slice(0,5) || '--'}`
        : 'Sin turnos';

    const isMananaBlocked = mananaTemplates.length > 0 && mananaTemplates.every(t =>
        cierresExistentes.some(c => !c.turno || c.turno === t.nombre)
    );
    const isTardeBlocked = tardeTemplates.length > 0 && tardeTemplates.every(t =>
        cierresExistentes.some(c => !c.turno || c.turno === t.nombre)
    );
    const isFullBlocked = isMananaBlocked && isTardeBlocked;

    const cierreMotivo = cierresExistentes[0]?.motivo || '';
    const mananaIcon = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>`;
    const tardeIcon = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>`;
    const lockIcon = `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>`;
    const unlockIcon = `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 9.9-1"/></svg>`;

    const body = document.getElementById('cierrePanelBody');
    body.innerHTML = `
        <div class="shift-toggle ${isMananaBlocked ? 'blocked' : ''}" onclick="toggleShift('${fecha}', 'manana')">
            <div style="display:flex;align-items:center;gap:10px;">
                <span style="color:var(--warning-color)">${mananaIcon}</span>
                <div>
                    <div class="shift-name">Mañana</div>
                    <div class="shift-time">${mananaTime}</div>
                </div>
            </div>
            <span class="shift-status ${isMananaBlocked ? 'blocked' : 'open'}">${isMananaBlocked ? lockIcon + ' Cerrado' : unlockIcon + ' Abierto'}</span>
        </div>

        <div class="shift-toggle ${isTardeBlocked ? 'blocked' : ''}" onclick="toggleShift('${fecha}', 'tarde')">
            <div style="display:flex;align-items:center;gap:10px;">
                <span style="color:#7B8FCE">${tardeIcon}</span>
                <div>
                    <div class="shift-name">Tarde</div>
                    <div class="shift-time">${tardeTime}</div>
                </div>
            </div>
            <span class="shift-status ${isTardeBlocked ? 'blocked' : 'open'}">${isTardeBlocked ? lockIcon + ' Cerrado' : unlockIcon + ' Abierto'}</span>
        </div>

        <input type="text" id="cierreMotivoInput" class="cierre-motive-input" placeholder="Motivo (obligatorio): paro SENA, mantenimiento..." value="${cierreMotivo}" required>

        <div style="text-align:center;margin-top:4px;">
            <button class="btn ${isFullBlocked ? 'btn-secondary' : 'btn-danger'} btn-sm" onclick="closeFullDay('${fecha}')">
                ${isFullBlocked ? unlockIcon + ' Reabrir dia completo' : lockIcon + ' Cerrar dia completo'}
            </button>
        </div>
    `;

    panel.style.display = '';
}

async function toggleShift(fecha, jornada) {
    const motivoInput = document.getElementById('cierreMotivoInput');
    const motivo = motivoInput?.value?.trim() || '';
    const mananaTemplates = allTemplates.filter(t => (parseInt(t.hora_inicio?.split(':')[0]) || 0) < 13);
    const tardeTemplates = allTemplates.filter(t => (parseInt(t.hora_inicio?.split(':')[0]) || 0) >= 13);
    const templates = jornada === 'manana' ? mananaTemplates : tardeTemplates;

    const dayObj = calendarData.find(x => x.fecha === fecha);
    const cierres = dayObj?.cierres || [];
    const isCurrentlyBlocked = templates.every(t =>
        cierres.some(c => !c.turno || c.turno === t.nombre)
    );

    if (!isCurrentlyBlocked) {
        if (!motivo) {
            if (motivoInput) { motivoInput.style.borderColor = 'var(--danger)'; motivoInput.focus(); }
            showToast('El motivo es obligatorio para cerrar', 'error');
            return;
        }
        const jornadaLabel = jornada === 'manana' ? 'Mañana' : 'Tarde';
        const confirmed = await showDeleteConfirm({
            title: `¿Cerrar jornada ${jornadaLabel}?`,
            message: `Se cerrará la jornada de ${jornadaLabel} del ${fecha}. Motivo: ${motivo}`,
            confirmText: 'Si, cerrar jornada',
            cancelText: 'Cancelar'
        });
        if (!confirmed) return;
    }

    try {
        if (isCurrentlyBlocked) {
            for (const c of cierres) {
                if (!c.turno || c.turno === '' || templates.some(t => t.nombre === c.turno)) {
                    await deleteCierre(c.id);
                }
            }
        } else {
            for (const t of templates) {
                await createCierre({ fecha, turno: t.nombre, motivo });
            }
        }
        if (motivoInput) motivoInput.style.borderColor = '';
        await loadCalendar();
        openCierreModal(fecha);
    } catch (err) {
        showToast('Error: ' + err.message, 'error');
    }
}

async function closeFullDay(fecha) {
    const motivoInput = document.getElementById('cierreMotivoInput');
    const motivo = motivoInput?.value?.trim() || '';
    const dayObj = calendarData.find(x => x.fecha === fecha);
    const cierres = dayObj?.cierres || [];
    const isBlocked = (dayObj?.estado === 'cerrado');

    // Si va a CERRAR, validar motivo obligatorio
    if (!isBlocked) {
        if (!motivo) {
            if (motivoInput) { motivoInput.style.borderColor = 'var(--danger)'; motivoInput.focus(); }
            showToast('El motivo es obligatorio para cerrar el dia', 'error');
            return;
        }
        const confirmed = await showDeleteConfirm({
            title: '¿Cerrar dia completo?',
            message: `Se cerrara el dia ${fecha} completamente. Motivo: ${motivo}`,
            confirmText: 'Si, cerrar dia',
            cancelText: 'Cancelar'
        });
        if (!confirmed) return;
    }

    try {
        if (isBlocked) {
            for (const c of cierres) await deleteCierre(c.id);
        } else {
            await createCierre({ fecha, turno: null, motivo });
        }
        if (motivoInput) motivoInput.style.borderColor = '';
        await loadCalendar();
        openCierreModal(fecha);
    } catch (err) {
        showToast('Error: ' + err.message, 'error');
    }
}

async function saveCierreFromPanel(fecha) {
    await loadCalendar();
    openCierreModal(fecha);
    showToast('Cambios guardados', 'success');
}

function renderCierreModalBody(fecha, dayObj) {
    const body = document.getElementById('cierreModalBody');
    if (!body) return;

    const cierresExistentes = dayObj?.cierres || [];
    const templateNames = allTemplates.map(t => t.nombre).filter(Boolean);

    let cierreListHtml = '';
    if (cierresExistentes.length > 0) {
        cierreListHtml = '<div class="cierre-list"><p style="font-size:13px;color:var(--text-muted);margin-bottom:10px;font-weight:600;">Cierres registrados:</p>';
        cierresExistentes.forEach(c => {
            const turnoLabel = c.turno ? `Turno: <strong>${c.turno}</strong>` : '<strong>Día completo</strong>';
            const motivoLabel = c.motivo ? `— ${c.motivo}` : '';
            cierreListHtml += `
                <div class="cierre-item">
                    <div class="cierre-info">
                        <span class="cierre-turno">${turnoLabel}</span>
                        <span class="cierre-motivo">${motivoLabel}</span>
                    </div>
                    <button class="btn btn-danger action-btn" onclick="deleteCierreAndRefresh('${c.id}', '${fecha}')">
                        <img src="assets/icons/delete.svg" alt="Eliminar" style="width:13px;height:13px;filter:brightness(0) invert(1);">
                    </button>
                </div>`;
        });
        cierreListHtml += '</div>';
    }

    const turnoOptions = `<option value="">Día completo</option>` +
        templateNames.map(n => `<option value="${n}">${n}</option>`).join('');

    body.innerHTML = `
        ${cierreListHtml}
        <div class="cierre-form">
            <h3>Registrar cierre</h3>
            <div class="form-row">
                <div class="form-group">
                    <label class="filter-label">Turno</label>
                    <select id="cierreTurno" class="filter-select" style="width:100%">
                        ${turnoOptions}
                    </select>
                </div>
                <div class="form-group">
                    <label class="filter-label">Motivo (opcional)</label>
                    <input type="text" id="cierreMotivo" class="filter-input" placeholder="Mantenimiento, festivo..." style="width:100%">
                </div>
            </div>
            <div style="display:flex;justify-content:flex-end;gap:10px;margin-top:16px;">
                <button class="btn btn-secondary" onclick="closeCierreModal()">Cancelar</button>
                <button class="btn btn-primary" onclick="submitCierre('${fecha}')">Registrar cierre</button>
            </div>
        </div>`;
}

async function submitCierre(fecha) {
    const turno = document.getElementById('cierreTurno')?.value || '';
    const motivo = document.getElementById('cierreMotivo')?.value?.trim() || '';

    try {
        await createCierre({ fecha, turno: turno || null, motivo });
        showToast('Cierre registrado', 'success');
        closeCierreModal();
        await loadCalendar();
    } catch (err) {
        console.error('Error creando cierre:', err);
        showToast('Error al registrar cierre: ' + err.message, 'error');
    }
}

async function deleteCierreAndRefresh(cierreId, fecha) {
    try {
        const ok = await deleteCierre(cierreId);
        if (ok) {
            showToast('Cierre eliminado', 'success');
            await loadCalendar();
            // Re-open modal with updated data
            openCierreModal(fecha);
        } else {
            showToast('Error al eliminar cierre', 'error');
        }
    } catch (err) {
        showToast('Error al eliminar cierre', 'error');
    }
}

function closeCierreModal() {
    document.getElementById('cierreModal')?.classList.remove('show');
}

// ===================== TOAST =====================

function showError(msg) { showToast(msg, 'error'); }
function showSuccess(msg) { showToast(msg, 'success'); }

function showToast(msg, type = 'success') {
    document.querySelectorAll('.toast-notification').forEach(t => t.remove());
    const toast = document.createElement('div');
    toast.className = 'toast-notification';
    toast.style.cssText = `
        position:fixed;bottom:28px;right:28px;z-index:9999;
        padding:14px 22px;border-radius:8px;font-size:14px;font-weight:500;
        color:#fff;box-shadow:0 8px 24px rgba(0,0,0,0.35);
        animation:slideUp 0.3s ease;
        background:${type === 'success' ? '#1a7a3a' : '#c0392b'};
        border-left:4px solid ${type === 'success' ? '#2ecc71' : '#e74c3c'};
        max-width:340px;display:flex;align-items:center;gap:10px;`;

    const icon = document.createElement('img');
    icon.src = type === 'success' ? 'assets/icons/exito.svg' : 'assets/icons/error.svg';
    icon.style.cssText = 'width:20px;height:20px;flex-shrink:0;filter:brightness(0) invert(1);';

    const text = document.createElement('span');
    text.textContent = msg;

    toast.appendChild(icon);
    toast.appendChild(text);
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 3500);
}

// ===================== EVENT LISTENERS =====================

document.addEventListener('DOMContentLoaded', () => {
    loadTemplates();
    loadCalendar();

    document.getElementById('addTemplateBtn')?.addEventListener('click', () => openTemplateModal());
    document.getElementById('toggleTemplatesBtn')?.addEventListener('click', () => {
        const section = document.getElementById('templatesSection');
        if (section) section.style.display = section.style.display === 'none' ? '' : 'none';
    });

    const form = document.getElementById('templateForm');
    if (form) form.addEventListener('submit', submitTemplateForm);

    document.getElementById('closeTemplateModal')?.addEventListener('click', closeTemplateModal);
    document.getElementById('cancelTemplateBtn')?.addEventListener('click', closeTemplateModal);

    document.getElementById('templateModal')?.addEventListener('click', (e) => {
        if (e.target === document.getElementById('templateModal')) closeTemplateModal();
    });

    document.getElementById('closeCierreModal')?.addEventListener('click', closeCierreModal);

    document.getElementById('prevMonthBtn')?.addEventListener('click', prevMonth);
    document.getElementById('nextMonthBtn')?.addEventListener('click', nextMonth);

    document.getElementById('logoutBtn')?.addEventListener('click', async () => {
        const confirmed = await showLogoutConfirm();
        if (confirmed) logoutAdmin();
    });
});
