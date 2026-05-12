/* ==================== THEME MANAGER ==================== */
(function () {
    const STORAGE_KEY = 'gym_admin_theme';

    function getSystemTheme() {
        return window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark';
    }

    function getActiveTheme() {
        return localStorage.getItem(STORAGE_KEY) || 'system';
    }

    function resolveTheme(preference) {
        if (preference === 'light') return 'light';
        if (preference === 'dark') return 'dark';
        return getSystemTheme(); // 'system'
    }

    function applyTheme(preference) {
        const theme = resolveTheme(preference);
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem(STORAGE_KEY, preference);
        syncButtonUI(theme);
    }

    const SVG_SUN = `<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>`;
    const SVG_MOON = `<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>`;

    function syncButtonUI(resolvedTheme) {
        const btn = document.getElementById('themeToggleBtn');
        if (!btn) return;
        const icon = btn.querySelector('.theme-icon');
        const label = btn.querySelector('.theme-label');
        if (icon) icon.innerHTML = resolvedTheme === 'dark' ? SVG_SUN : SVG_MOON;
        if (label) label.textContent = resolvedTheme === 'dark' ? 'Modo Claro' : 'Modo Oscuro';
    }

    // Apply immediately (before DOMContentLoaded) to prevent flash
    const savedPref = localStorage.getItem(STORAGE_KEY) || 'system';
    document.documentElement.setAttribute('data-theme', resolveTheme(savedPref));

    // React to system preference changes (when user hasn't manually overridden)
    window.matchMedia('(prefers-color-scheme: light)').addEventListener('change', () => {
        const pref = localStorage.getItem(STORAGE_KEY) || 'system';
        if (pref === 'system') {
            applyTheme('system');
        }
    });

    // Global toggle function called by button
    window.toggleTheme = function () {
        const current = document.documentElement.getAttribute('data-theme');
        const next = current === 'dark' ? 'light' : 'dark';
        applyTheme(next);
    };

    // Wire button after DOM is ready
    document.addEventListener('DOMContentLoaded', function () {
        const btn = document.getElementById('themeToggleBtn');
        if (btn) {
            btn.addEventListener('click', window.toggleTheme);
        }
        // Sync UI icons on load
        const pref = localStorage.getItem(STORAGE_KEY) || 'system';
        const theme = resolveTheme(pref);
        syncButtonUI(theme);
    });
})();
