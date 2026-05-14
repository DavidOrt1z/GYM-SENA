document.addEventListener('DOMContentLoaded', () => {
    const user = checkAdminAuth();
    if (user) {
        document.getElementById('adminName').textContent = user.name || 'Administrador';
        document.getElementById('adminEmail').textContent = user.email;
        const avatar = document.querySelector('.admin-avatar');
        if (avatar) {
            avatar.textContent = user.name ? user.name.charAt(0).toUpperCase() : 'A';
        }

        loadReservations();
    }
});

document.getElementById('logoutBtn')?.addEventListener('click', async (event) => {
    const button = event.currentTarget;
    if (typeof window.setButtonLoading === 'function') {
        window.setButtonLoading(button, true);
    }

    const confirmed = await showLogoutConfirm();
    if (confirmed) {
        logoutAdmin();
        return;
    }

    if (typeof window.setButtonLoading === 'function') {
        window.setButtonLoading(button, false);
    }
});
