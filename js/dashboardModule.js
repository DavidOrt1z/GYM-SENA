/* ==================== DASHBOARD MODULE ====================
   Módulo JavaScript para la página de Dashboard
*/

let _activityChart = null;

function renderActivityChart(reservasPorDia) {
    const canvas = document.getElementById('activityChart');
    if (!canvas || typeof Chart === 'undefined') return;

    const isDark = document.documentElement.getAttribute('data-theme') !== 'light';
    const gridColor  = isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.06)';
    const tickColor  = isDark ? '#666666' : '#999999';
    const labelColor = isDark ? '#CFCFCF' : '#555555';

    const labels = (reservasPorDia || []).map(d => {
        const date = new Date(d.fecha + 'T00:00:00');
        return date.toLocaleDateString('es-ES', { weekday: 'short', day: '2-digit' });
    });
    const valores = (reservasPorDia || []).map(d => d.total || 0);
    const avg = valores.length > 0
        ? Math.round((valores.reduce((a, b) => a + b, 0) / valores.length) * 10) / 10
        : 0;

    if (_activityChart) {
        _activityChart.destroy();
        _activityChart = null;
    }

    _activityChart = new Chart(canvas, {
        type: 'bar',
        data: {
            labels,
            datasets: [
                {
                    label: 'Reservas',
                    data: valores,
                    backgroundColor: isDark ? 'rgba(186, 21, 5, 0.70)' : 'rgba(186, 21, 5, 0.80)',
                    borderColor: '#BA1505',
                    borderWidth: 0,
                    borderRadius: 6,
                    borderSkipped: false,
                    order: 2
                },
                {
                    label: `Promedio (${avg})`,
                    data: Array(labels.length).fill(avg),
                    type: 'line',
                    borderColor: '#F57C00',
                    backgroundColor: 'transparent',
                    borderWidth: 2,
                    borderDash: [6, 4],
                    pointRadius: 0,
                    pointHoverRadius: 0,
                    tension: 0,
                    order: 1
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            animation: { duration: 500, easing: 'easeOutQuart' },
            plugins: {
                legend: {
                    labels: {
                        color: labelColor,
                        font: { size: 12, family: 'Manrope, sans-serif' },
                        boxWidth: 14,
                        usePointStyle: true,
                        pointStyle: 'line'
                    }
                },
                tooltip: {
                    backgroundColor: isDark ? '#1A1A1A' : '#FFFFFF',
                    titleColor: isDark ? '#FFFFFF' : '#111111',
                    bodyColor: isDark ? '#CFCFCF' : '#555555',
                    borderColor: isDark ? 'rgba(207,207,207,0.15)' : 'rgba(0,0,0,0.1)',
                    borderWidth: 1,
                    padding: 10,
                    callbacks: {
                        label: ctx => ctx.dataset.label.startsWith('Promedio')
                            ? ` Promedio: ${avg} reservas`
                            : ` ${ctx.parsed.y} reservas`
                    }
                }
            },
            scales: {
                x: {
                    ticks: { color: tickColor, font: { size: 11, family: 'Manrope, sans-serif' } },
                    grid: { color: gridColor, drawBorder: false }
                },
                y: {
                    beginAtZero: true,
                    ticks: { color: tickColor, font: { size: 11, family: 'Manrope, sans-serif' }, precision: 0 },
                    grid: { color: gridColor, drawBorder: false }
                }
            }
        }
    });
}

function setMetric(id, value, suffix) {
    const el = document.getElementById(id);
    if (!el) return;
    el.textContent = (value !== null && value !== undefined) ? (value + (suffix || '')) : '—';
}

async function loadDashboardData() {
    try {
        const stats = await getStatistics();

        setMetric('totalUsers', stats.totalUsers);
        setMetric('todayReservations', stats.todayReservations);
        setMetric('asistenciaRate', stats.asistenciaRate != null ? stats.asistenciaRate : null, '%');
        setMetric('canceladasHoy', stats.canceladasHoy);

        renderActivityChart(stats.reservasPorDia || []);

        const tbody = document.getElementById('recentActivityTable');
        if (tbody) {
            const activities = stats.recentActivity || [];
            if (activities.length === 0) {
                tbody.innerHTML = '<tr><td colspan="4" style="text-align:center;color:var(--text-muted)">Sin actividad reciente</td></tr>';
            } else {
                tbody.innerHTML = activities.map(a => {
                    const dateValue = a.fecha ? new Date(a.fecha) : null;
                    const isSmallScreen = window.innerWidth <= 768;
                    const fecha = dateValue
                        ? dateValue.toLocaleString('es-ES', {
                            day: '2-digit', month: '2-digit',
                            year: isSmallScreen ? '2-digit' : 'numeric',
                            hour: '2-digit', minute: '2-digit'
                        })
                        : 'N/A';
                    const tipoBadge = a.tipo === 'Personal'
                        ? `<span class="badge" style="background:rgba(186,21,5,0.2);color:#BA1505;">${a.tipo}</span>`
                        : `<span class="badge" style="background:rgba(56,142,60,0.2);color:#4CAF50;">${a.tipo}</span>`;
                    return `<tr>
                        <td>${tipoBadge}</td>
                        <td class="activity-description">${a.descripcion || 'N/A'}</td>
                        <td class="activity-user">${a.usuario || 'N/A'}</td>
                        <td class="activity-date">${fecha}</td>
                    </tr>`;
                }).join('');
            }
        }
    } catch (error) {
        console.error('Error cargando dashboard:', error);
    }
}

function normalizeSearchText(value) {
    return String(value || '')
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .toLowerCase()
        .trim();
}

function filterDashboardActivityRows(query) {
    const tbody = document.getElementById('recentActivityTable');
    if (!tbody) return;

    const normalizedQuery = normalizeSearchText(query);
    const rows = Array.from(tbody.querySelectorAll('tr'));

    rows.forEach((row) => {
        const isEmptyRow = row.children.length === 1;
        if (isEmptyRow) {
            row.style.display = '';
            return;
        }

        if (!normalizedQuery) {
            row.style.display = '';
            return;
        }

        const text = normalizeSearchText(row.textContent);
        row.style.display = text.includes(normalizedQuery) ? '' : 'none';
    });
}

function showError(message) {
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
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
            font-weight: 500;
            border-left: 4px solid #b71c1c;
            font-size: 14px;
            display: flex;
            align-items: center;
            gap: 12px;
        `;
        document.body.appendChild(notification);
    }
    notification.innerHTML = '<span>' + message + '</span>';
    notification.style.display = 'flex';
    setTimeout(() => { notification.style.display = 'none'; }, 4500);
}

// Ejecutar cuando carga la página
document.addEventListener('DOMContentLoaded', () => {
    const user = checkAdminAuth();
    if (user) {
        loadDashboardData();
    }

    const searchInput = document.getElementById('searchInput');
    if (searchInput) {
        searchInput.addEventListener('input', (e) => {
            filterDashboardActivityRows(e.target.value);
        });
    }
});
