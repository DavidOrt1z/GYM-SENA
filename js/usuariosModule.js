/* ==================== USUARIOS MODULE ====================
   Módulo JavaScript para la página de Usuarios
*/

let currentUserId = null;
let allUsers = [];
let currentSearchQuery = '';

let documentTypes = [];
let currentDocumentTypeId = null;

function slugPart(value) {
    return String(value || '')
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '.')
        .replace(/^\.+|\.+$/g, '');
}

function buildSyntheticEmail(name, lastName, documentNumber) {
    const first = slugPart(name) || 'usuario';
    const last = slugPart(lastName) || 'gym';
    const doc = String(documentNumber || '').replace(/\D/g, '').slice(-6) || '000000';
    return `${first}.${last}.${doc}@gymapp.local`;
}

function normalizeDocumentName(value) {
    return String(value || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
}

function getDefaultDocumentTypeId() {
    const cc = documentTypes.find((type) => normalizeDocumentName(type.nombre).includes('ciudadania'));
    return (cc || documentTypes[0])?.id ?? null;
}

async function loadDocumentTypes() {
    if (documentTypes.length) return documentTypes;

    const response = await fetch(`${window.SUPABASE_URL}/rest/v1/tipo_documentos?select=id,nombre&order=id.asc`, {
        headers: {
            'Authorization': `Bearer ${window.SUPABASE_ANON_KEY}`,
            'apikey': window.SUPABASE_ANON_KEY
        }
    });

    if (!response.ok) throw new Error('No se pudieron cargar los tipos de documento');
    documentTypes = await response.json();
    renderDocumentOptions();
    return documentTypes;
}

function renderDocumentOptions() {
    const options = document.getElementById('documentTypeOptions');
    if (!options) return;

    options.innerHTML = documentTypes.map((type) => `
        <button type="button" class="document-option" data-id="${escapeHtml(type.id)}">
            ${escapeHtml(type.nombre)}
        </button>
    `).join('');

    options.querySelectorAll('.document-option').forEach((option) => {
        option.addEventListener('click', () => {
            setDocumentType(option.dataset.id);
            closeDocumentOptions();
        });
    });
}

function setDocumentType(value) {
    const numericValue = value ? Number(value) : null;
    const isValidSelection = numericValue && documentTypes.some((type) => Number(type.id) === numericValue);
    currentDocumentTypeId = isValidSelection ? numericValue : null;

    const selected = documentTypes.find((type) => Number(type.id) === Number(currentDocumentTypeId));
    const label = selected?.nombre || 'Elige uno...';

    const hidden = document.getElementById('documentTypeId');
    const display = document.getElementById('documentTypeLabel');
    const numberLabel = document.getElementById('documentNumberLabel');
    const numberInput = document.getElementById('userDocumentNumber');

    if (hidden) hidden.value = currentDocumentTypeId ?? '';
    if (display) display.textContent = label;
    if (numberLabel) numberLabel.textContent = selected?.nombre || 'Número de Documento';
    if (numberInput) {
        numberInput.placeholder = selected?.nombre || 'Selecciona un tipo de documento';
        numberInput.setAttribute('aria-label', selected?.nombre || 'Número de Documento');
        if (!isValidSelection) {
            numberInput.value = '';
        }
    }

    document.querySelectorAll('.document-option').forEach((option) => {
        option.classList.toggle('selected', Number(option.dataset.id) === Number(currentDocumentTypeId));
    });
}

function closeDocumentOptions() {
    const options = document.getElementById('documentTypeOptions');
    const trigger = document.getElementById('documentTypeTrigger');
    options?.classList.remove('show');
    trigger?.setAttribute('aria-expanded', 'false');
}

function setupDocumentTypeSelect() {
    const trigger = document.getElementById('documentTypeTrigger');
    const options = document.getElementById('documentTypeOptions');
    if (!trigger || !options) return;

    trigger.addEventListener('click', (event) => {
        event.stopPropagation();
        const isOpen = options.classList.toggle('show');
        trigger.setAttribute('aria-expanded', String(isOpen));
    });

    document.addEventListener('click', closeDocumentOptions);
}

function escapeHtml(value) {
    return String(value ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/\"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function normalizeRole(role) {
    const raw = String(role || 'member').toLowerCase().trim();
    if (raw === 'usuario' || raw === 'user' || raw === 'miembro') return 'member';
    if (raw === 'administrador') return 'admin';
    return raw;
}

function getRoleLabel(role) {
    return 'Usuario';
}

function getRoleBadgeClass(role) {
    return 'badge-member';
}


function normalizeStatus(status) {
    const raw = String(status || 'active').toLowerCase().trim();
    const map = {
        activo: 'active',
        inactivo: 'inactive',
        pendiente: 'pending',
        suspendido: 'suspended',
        bloqueado: 'blocked'
    };
    return map[raw] || raw;
}

function resolveUserStatus(user) {
    const baseStatus = normalizeStatus(user?.estado);
    const email = String(user?.correo_electronico || '').trim().toLowerCase();
    const isIncompleteRegistration = !email || email.includes('@gymapp.local');

    if (isIncompleteRegistration && (baseStatus === 'active' || baseStatus === 'created' || !baseStatus)) {
        return 'pending';
    }

    return baseStatus || 'active';
}

function getStatusLabel(status) {
    const normalized = normalizeStatus(status);
    switch (normalized) {
        case 'active':
            return 'Activo';
        case 'inactive':
            return 'Inactivo';
        case 'pending':
            return 'Pendiente';
        case 'suspended':
            return 'Suspendido';
        case 'blocked':
            return 'Bloqueado';
        default:
            return 'Activo';
    }
}

function getStatusBadgeClass(status) {
    const normalized = normalizeStatus(status);
    if (normalized === 'inactive') return 'badge-inactive';
    if (normalized === 'pending') return 'badge-warning';
    if (normalized === 'suspended' || normalized === 'blocked') return 'badge-warning';
    return 'badge-active';
}

function normalizeSearchText(value) {
    return String(value || '')
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .toLowerCase()
        .trim();
}

function applyUserFilters() {
    const rol = document.getElementById('filterRol')?.value || '';
    const estado = document.getElementById('filterEstadoUsuario')?.value || '';
    const tipoDoc = document.getElementById('filterTipoDoc')?.value || '';
    const searchQuery = document.getElementById('searchInput')?.value || '';
    currentSearchQuery = searchQuery;

    let filtered = [...allUsers];

    if (rol) {
        filtered = filtered.filter((u) => normalizeRole(u.rol) === rol);
    }
    if (estado) {
        filtered = filtered.filter((u) => resolveUserStatus(u) === estado);
    }
    if (tipoDoc) {
        filtered = filtered.filter((u) => String(u.id_tipo_documento ?? u.Id_tipo_documento ?? u.tipo_documento_id ?? '') === tipoDoc);
    }
    if (searchQuery.trim()) {
        const q = normalizeSearchText(searchQuery);
        filtered = filtered.filter((u) => {
            const haystack = [
                u.id, u.nombre, u.apellido, u.numero_documento,
                u.correo_electronico, getRoleLabel(u.rol), getStatusLabel(resolveUserStatus(u))
            ].map((v) => normalizeSearchText(v)).join(' ');
            return haystack.includes(q);
        });
    }

    const hasFilters = rol || estado || tipoDoc || searchQuery.trim();
    renderUsersTable(filtered, hasFilters ? 'No se encontraron usuarios con esos filtros' : 'No hay usuarios');
}

function applyUsersSearchFilter() {
    applyUserFilters();
}

function populateTipoDocFilter() {
    const select = document.getElementById('filterTipoDoc');
    if (!select || !documentTypes.length) return;
    select.innerHTML = '<option value="">Todos</option>' +
        documentTypes.map((t) => `<option value="${escapeHtml(String(t.id))}">${escapeHtml(t.nombre)}</option>`).join('');
}

function clearUserFilters() {
    const filterRol = document.getElementById('filterRol');
    const filterEstado = document.getElementById('filterEstadoUsuario');
    const filterTipoDoc = document.getElementById('filterTipoDoc');
    const searchInput = document.getElementById('searchInput');
    if (filterRol) filterRol.value = '';
    if (filterEstado) filterEstado.value = '';
    if (filterTipoDoc) filterTipoDoc.value = '';
    if (searchInput) searchInput.value = '';
    currentSearchQuery = '';
    applyUserFilters();
}

function renderUsersTable(users, emptyMessage) {
    const tbody = document.getElementById('usersTable');
    if (!tbody) return;

    const rows = users.map(u => {
        const roleValue = normalizeRole(u.rol);
        const roleLabel = getRoleLabel(roleValue);
        const roleClass = getRoleBadgeClass(roleValue);

        const statusValue = resolveUserStatus(u);
        const statusLabel = getStatusLabel(statusValue);
        const statusClass = getStatusBadgeClass(statusValue);

        // Mostrar "No completado" si el email está vacío o es un email sintético
        const emailDisplay = u.correo_electronico && u.correo_electronico.includes('@') 
            ? (u.correo_electronico.includes('@gymapp.local') ? 'No completado' : escapeHtml(u.correo_electronico))
            : 'No completado';

        return `
            <tr>
                <td>${escapeHtml(String(u.id || '').substring(0, 8))}...</td>
                <td>${escapeHtml(u.nombre || 'N/A')}</td>
                <td>${escapeHtml(u.apellido || 'N/A')}</td>
                <td>${escapeHtml(u.numero_documento || 'N/A')}</td>
                <td>${emailDisplay}</td>
                <td><span class="badge ${roleClass}">${escapeHtml(roleLabel)}</span></td>
                <td><span class="badge ${statusClass}">${escapeHtml(statusLabel)}</span></td>
                <td>
                    <button class="btn btn-secondary" style="padding:6px 12px;margin-right:8px;" onclick="editUser('${escapeHtml(u.id)}')"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="width:16px;height:16px;"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg></button>
                    <button class="btn btn-danger" style="padding:6px 12px;" onclick="confirmDeleteUser('${escapeHtml(u.id)}', this)"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="width:16px;height:16px;"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg></button>
                </td>
            </tr>
        `;
    });

    tbody.innerHTML = rows.join('') || `<tr><td colspan="8" style="text-align:center;color:#CFCFCF;">${escapeHtml(emptyMessage)}</td></tr>`;
}

async function loadUsers() {
    console.log('👥 Cargando usuarios...');
    try {
        await window.configReady;
        await loadDocumentTypes();
        populateTipoDocFilter();
        const users = await getUsers();
        allUsers = users;

        applyUserFilters();
        console.log('✅ Usuarios cargados:', users.length);
    } catch (error) {
        console.error('❌ Error cargando usuarios:', error);
        showError('Error al cargar usuarios');
    }
}

function openUserModal(userId = null) {
    currentUserId = userId;
    const modal = document.getElementById('userModal');
    const title = document.querySelector('#userModal .modal-header h2');
    const form = document.getElementById('userForm');
    const roleSelect = document.getElementById('userRole');

    if (userId) {
        title.textContent = 'Editar Usuario';
        const user = allUsers.find(u => u.id === userId);
        if (user) {
            const resolvedDocType = user.id_tipo_documento ?? user.Id_tipo_documento ?? user.tipo_documento_id ?? null;
            const resolvedDocNumber = user.numero_documento ?? user.cedula ?? '';

            document.getElementById('userName').value = user.nombre || '';
            document.getElementById('userLastName').value = user.apellido || '';
            document.getElementById('userDocumentNumber').value = resolvedDocNumber;
            setDocumentType(resolvedDocType);
            if (roleSelect) roleSelect.value = 'member';
        }
    } else {
        title.textContent = 'Añadir Usuario';
        form.reset();
        document.getElementById('userLastName').value = '';
        document.getElementById('userDocumentNumber').value = '';
        setDocumentType(null);
        if (roleSelect) roleSelect.value = 'member';
    }

    modal.classList.add('show');
}

function closeUserModal() {
    document.getElementById('userModal').classList.remove('show');
    currentUserId = null;
}

async function submitUserForm(e) {
    e.preventDefault();
    await window.configReady;

    const submitButton = document.querySelector('#userForm button[type="submit"]');

    const name = document.getElementById('userName').value.trim();
    const lastName = document.getElementById('userLastName').value.trim();
    const documentNumber = document.getElementById('userDocumentNumber').value.trim();
    const tipoDocumentoId = document.getElementById('documentTypeId').value;
    const rol = document.getElementById('userRole')?.value || 'member';

    const currentUser = currentUserId
        ? allUsers.find((user) => String(user.id) === String(currentUserId))
        : null;
    const fallbackDocType = currentUser?.id_tipo_documento ?? currentUser?.Id_tipo_documento ?? currentUser?.tipo_documento_id ?? '';
    const fallbackDocNumber = currentUser?.numero_documento ?? currentUser?.cedula ?? '';

    const resolvedDocType = tipoDocumentoId || fallbackDocType;
    const resolvedDocNumber = documentNumber || fallbackDocNumber;

    if (!name) {
        showError('Por favor, ingresa el nombre.');
        return;
    }
    if (!lastName) {
        showError('Por favor, ingresa el apellido.');
        return;
    }
    if (!resolvedDocType) {
        showError('Por favor, elige un tipo de documento.');
        return;
    }
    if (!resolvedDocNumber) {
        showError('Por favor, ingresa el número de documento.');
        return;
    }
    const normalizedDocTypeId = Number(resolvedDocType);

    if (!Number.isInteger(normalizedDocTypeId) || normalizedDocTypeId <= 0) {
        showError('Tipo de documento inválido. Selecciona uno válido.');
        return;
    }

    const userData = {
        nombre: name,
        apellido: lastName,
        id_tipo_documento: normalizedDocTypeId,
        numero_documento: resolvedDocNumber,
        rol: rol,
    };

    if (typeof window.setButtonLoading === 'function') {
        window.setButtonLoading(submitButton, true);
    } else if (submitButton) {
        submitButton.disabled = true;
    }

    let submitError = null;
    let submitSuccessMessage = null;

    try {
        if (currentUserId) {
            const response = await fetch(`${window.API_BASE}/api/users/${encodeURIComponent(currentUserId)}`, {
                method: 'PATCH',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(userData),
            });

            const data = await response.json().catch(() => ({}));
            if (!response.ok) throw new Error(data.message || 'Error al actualizar usuario');
            submitSuccessMessage = 'Usuario actualizado exitosamente.';
        } else {
            const adminToken = localStorage.getItem('adminToken') || window.SUPABASE_ANON_KEY;
            const response = await fetch(`${window.SUPABASE_URL}/rest/v1/rpc/create_user_as_admin`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'apikey': window.SUPABASE_ANON_KEY,
                    'Authorization': `Bearer ${adminToken}`,
                },
                body: JSON.stringify({
                    p_nombre: userData.nombre,
                    p_apellido: userData.apellido,
                    p_id_tipo_documento: userData.id_tipo_documento,
                    p_numero_documento: userData.numero_documento,
                    p_rol: userData.rol,
                }),
            });

            const data = await response.json().catch(() => ({}));
            if (!response.ok || data.ok === false) throw new Error(data.message || 'Error al crear usuario');
            submitSuccessMessage = 'Usuario creado exitosamente.';
        }
    } catch (err) {
        submitError = err;
    } finally {
        if (typeof window.setButtonLoading === 'function') {
            window.setButtonLoading(submitButton, false);
        } else if (submitButton) {
            submitButton.disabled = false;
        }
    }

    if (submitError) {
        showError(`Error al guardar usuario: ${submitError.message}`);
        return;
    }

    if (submitSuccessMessage) {
        showSuccess(submitSuccessMessage);
        setTimeout(() => {
            location.reload();
        }, 900);
    }
}

function editUser(userId) {
    openUserModal(userId);
}

async function confirmDeleteUser(userId, button) {
    const confirmed = await showDeleteConfirm({
        title: '¿Estás seguro?',
        message: '¡El registro será eliminado!',
        confirmText: 'Sí, eliminarlo',
        cancelText: 'Cancelar'
    });

    if (confirmed) {
        deleteUser(userId, button);
    }
}

async function deleteUser(userId, button) {
    try {
        if (typeof window.setButtonLoading === 'function') {
            window.setButtonLoading(button, true);
        }
        await window.configReady;
        const adminToken = localStorage.getItem('adminToken') || window.SUPABASE_ANON_KEY;
        const response = await fetch(`${window.SUPABASE_URL}/rest/v1/rpc/delete_user_as_admin`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'apikey': window.SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${adminToken}`,
            },
            body: JSON.stringify({ p_user_id: userId }),
        });
        const data = await response.json().catch(() => ({}));
        if (response.ok && data.ok !== false) {
            console.log('✅ Usuario eliminado');
            await loadUsers();
            showSuccess('Usuario eliminado correctamente');
        } else {
            throw new Error(data.message || 'Error eliminando usuario');
        }
    } catch (error) {
        console.error('❌ Error eliminando usuario:', error);
        showError('Error al eliminar usuario: ' + error.message);
    } finally {
        if (typeof window.setButtonLoading === 'function') {
            window.setButtonLoading(button, false);
        }
    }
}

function searchUsers(query) {
    currentSearchQuery = query || '';
    applyUserFilters();
}

function showError(msg) {
    // Crear notificación visual si no existe
    let notification = document.getElementById('errorNotification');
    if (!notification) {
        notification = document.createElement('div');
        notification.id = 'errorNotification';
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: #D32F2F;
            color: white;
            padding: 16px 24px;
            border-radius: 6px;
            z-index: 10000;
            max-width: 400px;
            animation: slideIn 0.3s ease-out;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
            font-weight: 500;
            border-left: 4px solid #b71c1c;
            font-size: 14px;
            line-height: 1.4;
            display: flex;
            align-items: center;
            gap: 12px;
        `;
        document.body.appendChild(notification);
    }
    
    const iconHtml = '<img src="assets/icons/error.svg" style="width: 20px; height: 20px; flex-shrink: 0; filter: brightness(0) invert(1) saturate(2);" />';
    notification.innerHTML = iconHtml + '<span>' + msg + '</span>';
    notification.style.display = 'block';
    notification.style.animation = 'slideIn 0.3s ease-out';
    
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease-out';
        setTimeout(() => {
            notification.style.display = 'none';
        }, 300);
    }, 4500);
}

function showSuccess(msg) {
    // Crear notificación visual si no existe
    let notification = document.getElementById('successNotification');
    if (!notification) {
        notification = document.createElement('div');
        notification.id = 'successNotification';
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: #4CAF50;
            color: white;
            padding: 16px 24px;
            border-radius: 6px;
            z-index: 10000;
            max-width: 400px;
            animation: slideIn 0.3s ease-out;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
            font-weight: 500;
            border-left: 4px solid #45a049;
            font-size: 14px;
            line-height: 1.4;
            display: flex;
            align-items: center;
            gap: 12px;
        `;
        document.body.appendChild(notification);
    }
    
    const iconHtml = '<img src="assets/icons/exito.svg" style="width: 20px; height: 20px; flex-shrink: 0; filter: brightness(0) invert(1) saturate(1);" />';
    notification.innerHTML = iconHtml + '<span>' + msg + '</span>';
    notification.style.display = 'block';
    notification.style.animation = 'slideIn 0.3s ease-out';
    
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease-out';
        setTimeout(() => {
            notification.style.display = 'none';
        }, 300);
    }, 3500);
}

// Event listeners
document.addEventListener('DOMContentLoaded', () => {
    const user = checkAdminAuth();
    if (user) {
        loadUsers();
    }

    setupDocumentTypeSelect();

    document.getElementById('addUserBtn')?.addEventListener('click', () => openUserModal());
    document.getElementById('cancelUserBtn')?.addEventListener('click', closeUserModal);
    document.getElementById('closeUserModal')?.addEventListener('click', closeUserModal);
    document.getElementById('userModal')?.addEventListener('click', (e) => {
        if (e.target.id === 'userModal') closeUserModal();
    });

    const userForm = document.getElementById('userForm');
    if (userForm) userForm.addEventListener('submit', submitUserForm);

    document.getElementById('logoutBtn')?.addEventListener('click', async () => {
        const confirmed = await showLogoutConfirm();
        if (confirmed) logoutAdmin();
    });

    const searchInput = document.getElementById('searchInput');
    if (searchInput) {
        currentSearchQuery = searchInput.value || '';
        searchInput.addEventListener('input', () => applyUserFilters());
    }

    const filterRol = document.getElementById('filterRol');
    if (filterRol) filterRol.addEventListener('change', applyUserFilters);

    const filterEstado = document.getElementById('filterEstadoUsuario');
    if (filterEstado) filterEstado.addEventListener('change', applyUserFilters);

    const filterTipoDoc = document.getElementById('filterTipoDoc');
    if (filterTipoDoc) filterTipoDoc.addEventListener('change', applyUserFilters);

    const clearFiltersBtn = document.getElementById('clearFiltersBtn');
    if (clearFiltersBtn) clearFiltersBtn.addEventListener('click', clearUserFilters);
});
