const passwordInput = document.getElementById('password');
const togglePasswordBtn = document.getElementById('togglePasswordBtn');

function ensureButtonLoader(button) {
    if (!button) return null;

    let loader = button.querySelector('.btn-loader');
    if (!loader) {
        loader = document.createElement('span');
        loader.className = 'btn-loader';
        loader.innerHTML = '<span class="dot-triangle">' +
            '<span class="dot dot-a"></span>' +
            '<span class="dot dot-b"></span>' +
            '<span class="dot dot-c"></span>' +
            '</span>';
        button.appendChild(loader);
    }

    return loader;
}

function setLoginButtonLoading(button, isLoading) {
    if (!button) return;
    ensureButtonLoader(button);
    button.classList.toggle('is-loading', Boolean(isLoading));
    button.disabled = Boolean(isLoading);
    button.setAttribute('aria-busy', isLoading ? 'true' : 'false');
}

togglePasswordBtn?.addEventListener('click', () => {
    if (!passwordInput) return;

    const isVisible = passwordInput.type === 'text';
    passwordInput.type = isVisible ? 'password' : 'text';
    togglePasswordBtn.classList.toggle('is-visible', !isVisible);
    togglePasswordBtn.setAttribute('aria-pressed', String(!isVisible));
    togglePasswordBtn.setAttribute('aria-label', isVisible ? 'Mostrar contraseña' : 'Ocultar contraseña');
    passwordInput.focus();
});

document.getElementById('loginForm')?.addEventListener('submit', async (e) => {
    e.preventDefault();

    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const submitButton = document.getElementById('submitButton');
    const errorMessage = document.getElementById('errorMessage');
    const loadingStartedAt = Date.now();
    let keepLoading = false;

    setLoginButtonLoading(submitButton, true);

    try {
        const result = await adminLogin(email, password);

        if (result.success) {
            keepLoading = true;
            localStorage.setItem('adminToken', result.token);
            localStorage.setItem('adminUser', JSON.stringify(result.user));
            const elapsed = Date.now() - loadingStartedAt;
            const remainingDelay = Math.max(0, 850 - elapsed);

            setTimeout(() => {
                window.location.href = 'dashboard.html';
            }, remainingDelay);
        } else {
            errorMessage.textContent = result.message || 'Error en la autenticacion';
            errorMessage.style.display = 'block';
        }
    } catch (error) {
        errorMessage.textContent = 'Error: ' + error.message;
        errorMessage.style.display = 'block';
    } finally {
        if (keepLoading) return;
        setLoginButtonLoading(submitButton, false);
    }
});
