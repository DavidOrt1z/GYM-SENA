// ==================== AUTENTICACIÓN ADMIN ====================

function normalizeRole(rawRole) {
    const value = String(rawRole || '').toLowerCase().trim();
    if (value === 'administrador') return 'admin';
    return value;
}

async function adminLogin(email, password) {
    try {
        await window.configReady;
        console.log('Iniciando login para:', email);
        
        // Paso 1: Autenticación en Supabase Auth
        const authResponse = await fetch(`${window.SUPABASE_URL}/auth/v1/token?grant_type=password`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'apikey': window.SUPABASE_ANON_KEY
            },
            body: JSON.stringify({
                email,
                password
            })
        });

        const authData = await authResponse.json();
        console.log('Auth Response:', authResponse.status, authData);

        if (!authResponse.ok) {
            console.error('Error de autenticación:', authData);
            return {
                success: false,
                message: 'Email o contraseña incorrectos'
            };
        }

        const token = authData.access_token;
        console.log('Token obtenido:', token.substring(0, 20) + '...');

        const authHeaders = {
            'apikey': window.SUPABASE_ANON_KEY,
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
        };

        // Paso 2: Buscar en tabla users (usuarios app con rol admin)
        let foundUser = null;
        const userResponse = await fetch(
            `${window.SUPABASE_URL}/rest/v1/users?correo_electronico=eq.${encodeURIComponent(email)}&select=*`,
            { method: 'GET', headers: authHeaders }
        );
        if (userResponse.ok) {
            const users = await userResponse.json();
            const match = (users || []).find(u => normalizeRole(u.rol) === 'admin');
            if (match) foundUser = { ...match, _source: 'users' };
        }

        // Paso 2b: Si no está en users, buscar en tabla personal
        if (!foundUser) {
            const staffResponse = await fetch(
                `${window.SUPABASE_URL}/rest/v1/personal?correo_electronico=eq.${encodeURIComponent(email)}&select=*`,
                { method: 'GET', headers: authHeaders }
            );
            if (staffResponse.ok) {
                const staff = await staffResponse.json();
                if (staff && staff.length > 0) {
                    foundUser = { ...staff[0], rol: staff[0].rol || 'admin', _source: 'personal' };
                }
            }
        }

        if (!foundUser) {
            console.error('Usuario no encontrado en la BD');
            return {
                success: false,
                message: 'Usuario no encontrado. Verifica que el administrador esté registrado.'
            };
        }

        if (foundUser._source === 'users' && normalizeRole(foundUser.rol) !== 'admin') {
            return { success: false, message: 'No tienes permisos de administrador' };
        }

        console.log('✅ Login exitoso para:', foundUser.correo_electronico);
        return {
            success: true,
            token: token,
            user: {
                id: foundUser.id,
                email: foundUser.correo_electronico,
                name: foundUser.nombre_completo || 'Administrador',
                role: 'admin'
            }
        };
    } catch (error) {
        console.error('❌ Error en login:', error);
        return {
            success: false,
            message: 'Error: ' + error.message
        };
    }
}

function checkAdminAuth() {
    const token = localStorage.getItem('adminToken');
    const user = localStorage.getItem('adminUser');

    if (!token || !user) {
        window.location.href = 'login.html';
        return null;
    }

    return JSON.parse(user);
}

function logoutAdmin() {
    localStorage.removeItem('adminToken');
    localStorage.removeItem('adminUser');
    
    // Limpiar UI antes de redirigir (opcional pero buena práctica)
    const adminNameEl = document.getElementById('adminName');
    const adminEmailEl = document.getElementById('adminEmail');
    if (adminNameEl) adminNameEl.textContent = '...';
    if (adminEmailEl) adminEmailEl.textContent = '...';

    window.location.href = 'login.html';
}

function setupMobileSidebar() {
    const sidebar = document.querySelector('.sidebar');
    const topBar = document.querySelector('.top-bar');
    if (!sidebar || !topBar) return;

    let menuButton = document.getElementById('mobileMenuBtn');
    if (!menuButton) {
        menuButton = document.createElement('button');
        menuButton.type = 'button';
        menuButton.id = 'mobileMenuBtn';
        menuButton.className = 'mobile-menu-btn';
        menuButton.setAttribute('aria-label', 'Abrir menu de navegacion');
        menuButton.innerHTML = `
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                <line x1="3" y1="6" x2="21" y2="6"></line>
                <line x1="3" y1="12" x2="21" y2="12"></line>
                <line x1="3" y1="18" x2="21" y2="18"></line>
            </svg>
        `;
        topBar.prepend(menuButton);
    }

    let backdrop = document.querySelector('.sidebar-backdrop');
    if (!backdrop) {
        backdrop = document.createElement('div');
        backdrop.className = 'sidebar-backdrop';
        document.body.appendChild(backdrop);
    }

    const closeSidebar = () => {
        sidebar.classList.remove('active');
        backdrop.classList.remove('show');
        document.body.classList.remove('sidebar-open');
    };

    const openSidebar = () => {
        sidebar.classList.add('active');
        backdrop.classList.add('show');
        document.body.classList.add('sidebar-open');
    };

    menuButton.addEventListener('click', () => {
        if (sidebar.classList.contains('active')) {
            closeSidebar();
            return;
        }
        openSidebar();
    });

    backdrop.addEventListener('click', closeSidebar);

    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape') {
            closeSidebar();
        }
    });

    sidebar.querySelectorAll('.nav-item').forEach((item) => {
        item.addEventListener('click', () => {
            if (window.innerWidth <= 900) {
                closeSidebar();
            }
        });
    });

    window.addEventListener('resize', () => {
        if (window.innerWidth > 900) {
            closeSidebar();
        }
    });
}

// ==================== VERIFICACIÓN INICIAL ====================

document.addEventListener('DOMContentLoaded', () => {
    // Verificar en cualquier página del panel (excepto login)
    if (!window.location.pathname.includes('login.html')) {
        const user = checkAdminAuth();
        
        if (user) {
            // Llenar datos del usuario si los elementos existen
            const adminNameEl = document.getElementById('adminName');
            const adminEmailEl = document.getElementById('adminEmail');
            const adminAvatarEl = document.querySelector('.admin-avatar');

            if (adminNameEl) adminNameEl.textContent = user.name || 'Administrador';
            if (adminEmailEl) adminEmailEl.textContent = user.email;
            if (adminAvatarEl) adminAvatarEl.textContent = user.name ? user.name.charAt(0).toUpperCase() : 'A';

            // Cargar datos específicos de la página si es necesario
            if (window.location.pathname.includes('dashboard.html') || window.location.pathname.endsWith('/') || window.location.pathname.endsWith('index.html')) {
                if (typeof loadDashboardData === 'function') {
                    loadDashboardData();
                }
            }
        }
    }
});

document.addEventListener('DOMContentLoaded', () => {
    setupMobileSidebar();
});
