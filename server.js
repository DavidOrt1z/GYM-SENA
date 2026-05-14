require('dotenv').config();
const express = require('express');
const path = require('path');
const { randomUUID } = require('crypto');
const { createClient } = require('@supabase/supabase-js');

const app = express();
const PORT = process.env.ADMIN_PANEL_PORT || 5500;

console.log('🚀 Iniciando servidor JACEK GYM Admin Panel...');
console.log(`📁 __dirname: ${__dirname}`);
console.log(`🔧 Variables de entorno cargadas`);

// Verificar variables críticas
const supabaseUrl = process.env.SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const anonKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !serviceRoleKey || !anonKey) {
    console.error('❌ CRÍTICO: Faltan variables de Supabase');
    console.error(`   SUPABASE_URL: ${supabaseUrl ? '✅' : '❌'}`);
    console.error(`   SUPABASE_SERVICE_ROLE_KEY: ${serviceRoleKey ? '✅' : '❌'}`);
    console.error(`   SUPABASE_ANON_KEY: ${anonKey ? '✅' : '❌'}`);
    process.exit(1);
}

const supabase = createClient(supabaseUrl, serviceRoleKey);
console.log('✅ Supabase inicializado correctamente');

// Middleware
app.use(express.json());

// CORS - Permitir requests desde cualquier origen
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
    
    if (req.method === 'OPTIONS') {
        return res.sendStatus(200);
    }
    next();
});

// ============================================
// RUTAS DE API
// ============================================

// Ruta de config - CRÍTICA para inicializar el frontend
app.get('/api/config', (req, res) => {
    console.log('📡 [GET /api/config] Solicitada');
    res.json({
        supabaseUrl: process.env.SUPABASE_URL,
        supabaseKey: process.env.SUPABASE_ANON_KEY
    });
});

// Ruta para obtener usuarios (usa service role para evitar RLS)
app.get('/api/get-users', async (req, res) => {
    try {
        const { data: users, error } = await supabase
            .from('users')
            .select('*')
            .neq('rol', 'admin')
            .order('fecha_creacion', { ascending: false });

        if (error) {
            console.log(`❌ Error obteniendo usuarios: ${error.message}`);
            return res.status(400).json([]);
        }

        console.log(`✅ Usuarios obtenidos: ${users?.length || 0} registros`);
        res.status(200).json(users || []);
    } catch (error) {
        console.error(`❌ ERROR en /api/get-users:`, error.message);
        res.status(500).json([]);
    }
});

// Ruta para obtener personal
app.get('/api/get-staff', async (req, res) => {
    try {
        console.log(`\n📋 [GET /api/get-staff] Solicitud recibida`);
        
        const { data: staffData, error: staffError } = await supabase
            .from('personal')
            .select('*')
            .order('fecha_creacion', { ascending: false });

        if (staffError) {
            console.log(`❌ Error obteniendo personal: ${staffError.message}`);
            return res.status(400).json({
                error: staffError.message,
                data: []
            });
        }

        console.log(`✅ Personal obtenido: ${staffData?.length || 0} registros`);
        res.status(200).json(staffData || []);

    } catch (error) {
        console.error(`❌ ERROR en /api/get-staff:`, error.message);
        res.status(500).json({
            error: error.message,
            data: []
        });
    }
});

// Ruta para obtener reservas (usa service role para evitar bloqueos RLS del panel)
app.get('/api/get-reservations', async (req, res) => {
    try {
        const { estado } = req.query;
        const today = new Date();
        const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());

        let query = supabase
            .from('reservas')
            .select('id, id_usuario, hora_inicio, hora_fin, estado, fecha_creacion, token_qr, fecha')
            .order('fecha_creacion', { ascending: false });

        if (estado) {
            query = query.eq('estado', estado);
        }

        const { data, error } = await query;

        if (error) {
            return res.status(400).json({ error: error.message, data: [] });
        }

        const reservationRows = data || [];

        const enrichedRows = reservationRows.map(r => {
            let normalizedStatus = String(r.estado || '').toLowerCase().trim();

            // Normalizacion visual: reserva activa de fecha pasada → completada
            if (normalizedStatus === 'active' && r.fecha) {
                const slotDate = new Date(`${r.fecha}T00:00:00`);
                if (!Number.isNaN(slotDate.getTime()) && slotDate < todayStart) {
                    normalizedStatus = 'completed';
                }
            }

            return {
                ...r,
                estado: normalizedStatus,
                hora_inicio: r.hora_inicio || null,
                hora_fin: r.hora_fin || null,
                fecha_horario: r.fecha || null
            };
        });

        const filteredRows = estado
            ? enrichedRows.filter((row) => String(row.estado || '').toLowerCase().trim() === String(estado).toLowerCase().trim())
            : enrichedRows;

        return res.status(200).json(filteredRows);
    } catch (error) {
        console.error('❌ ERROR en /api/get-reservations:', error.message);
        return res.status(500).json({ error: error.message, data: [] });
    }
});

function parseQrToken(rawToken) {
    const raw = String(rawToken || '').trim();
    if (!raw) return '';

    let token = raw;
    try {
        const parsedUrl = new URL(raw);
        token = parsedUrl.searchParams.get('token') || raw;
    } catch (_) {
        // No es URL valida; usar valor original.
    }

    token = String(token).trim();
    if (token.startsWith('resv:')) {
        token = token.slice(5).trim();
    }

    return token;
}

async function findReservationByTokenOrId(token) {
    let reservation = null;

    const { data: reservasData, error: reservasError } = await supabase
        .from('reservas')
        .select('id, id_usuario, hora_inicio, hora_fin, estado, fecha_creacion, token_qr, fecha')
        .eq('token_qr', token)
        .order('fecha_creacion', { ascending: false })
        .limit(1)
        .maybeSingle();

    if (!reservasError && reservasData) {
        reservation = reservasData;
    }

    if (!reservation) {
        const { data: byIdData, error: byIdError } = await supabase
            .from('reservas')
            .select('id, id_usuario, hora_inicio, hora_fin, estado, fecha_creacion, token_qr, fecha')
            .eq('id', token)
            .order('fecha_creacion', { ascending: false })
            .limit(1)
            .maybeSingle();

        if (!byIdError && byIdData) {
            reservation = byIdData;
        }
    }

    return reservation;
}

async function sendCompletedReservationNotification({ userId, reservationId, fecha, horaInicio: horaInicioParam, horaFin: horaFinParam }) {
    if (!userId) return;

    let horaInicio = horaInicioParam || '';
    let horaFin = horaFinParam || '';
    let fechaStr = fecha || '';

    if (!fechaStr && reservationId) {
        const { data: resData } = await supabase
            .from('reservas')
            .select('fecha')
            .eq('id', reservationId)
            .maybeSingle();
        fechaStr = resData?.fecha || '';
    }

    const notificationBase = {
        titulo: 'Reserva completada',
        cuerpo: fechaStr && horaInicio
            ? `Tu reserva de ${fechaStr}, ${horaInicio} - ${horaFin} fue completada.`
            : 'Tu reserva fue marcada como completada.',
        tipo: 'reserva_completada',
        datos: {
            reserva_id: reservationId,
            fecha: fechaStr,
            hora_inicio: horaInicio,
            hora_fin: horaFin
        },
        entregada: true,
        abierta: false
    };

    const userColumns = ['id_usuario_notif', 'id_usuario', 'usuario_id', 'user_id'];
    for (const userColumn of userColumns) {
        const { error } = await supabase
            .from('notificaciones_historial')
            .insert({
                ...notificationBase,
                [userColumn]: userId
            });

        if (!error) {
            return;
        }
    }

    console.log('⚠️ No se pudo guardar notificación de reserva completada para:', userId);
}

async function completeReservationBySource(reservationId) {
    const nowIso = new Date().toISOString();

    const { data: reservationRow } = await supabase
        .from('reservas')
        .select('id_usuario, hora_inicio, hora_fin, fecha')
        .eq('id', reservationId)
        .maybeSingle();

    const payloadCandidates = [
        { estado: 'completed', fecha_actualizacion: nowIso, completed_at: nowIso },
        { estado: 'completed', fecha_actualizacion: nowIso },
        { estado: 'completed' }
    ];

    let updateError = null;
    for (const payload of payloadCandidates) {
        const { error } = await supabase
            .from('reservas')
            .update(payload)
            .eq('id', reservationId);

        if (!error) {
            updateError = null;
            break;
        }

        updateError = error;
    }

    if (updateError) {
        return { ok: false, error: updateError.message };
    }

    const { data: verifyRow } = await supabase
        .from('reservas')
        .select('estado')
        .eq('id', reservationId)
        .maybeSingle();

    const completed = String(verifyRow?.estado || '').toLowerCase().trim() === 'completed';

    if (completed && reservationRow?.id_usuario) {
        try {
            await sendCompletedReservationNotification({
                userId: reservationRow.id_usuario,
                reservationId,
                horaInicio: reservationRow.hora_inicio || null,
                horaFin: reservationRow.hora_fin || null,
                fecha: reservationRow.fecha || null
            });
        } catch (_) {
            // No bloquear validacion de QR por fallo de notificacion.
        }
    }

    return { ok: completed, error: completed ? null : 'No se confirmo estado completed en reservas' };
}

async function setReservationStatusById(reservationId, nextStatus) {
    const validStatuses = new Set(['active', 'completed', 'cancelled']);
    const normalizedStatus = String(nextStatus || '').toLowerCase().trim();

    if (!validStatuses.has(normalizedStatus)) {
        return { ok: false, code: 400, message: 'Estado invalido' };
    }

    const { data: rowInReservas } = await supabase
        .from('reservas')
        .select('id, id_usuario, hora_inicio, hora_fin, fecha')
        .eq('id', reservationId)
        .maybeSingle();

    if (rowInReservas?.id) {
        const nowIso = new Date().toISOString();
        const payloadCandidates = [
            { estado: normalizedStatus, fecha_actualizacion: nowIso },
            { estado: normalizedStatus }
        ];

        let updateError = null;
        for (const payload of payloadCandidates) {
            const { error } = await supabase
                .from('reservas')
                .update(payload)
                .eq('id', reservationId);

            if (!error) {
                updateError = null;
                break;
            }
            updateError = error;
        }

        if (updateError) {
            return { ok: false, code: 400, message: updateError.message };
        }

        const { data: verifyRow } = await supabase
            .from('reservas')
            .select('estado')
            .eq('id', reservationId)
            .maybeSingle();

        const verifiedStatus = String(verifyRow?.estado || '').toLowerCase().trim() || normalizedStatus;
        if (verifiedStatus === 'completed' && rowInReservas?.id_usuario) {
            try {
                await sendCompletedReservationNotification({
                    userId: rowInReservas.id_usuario,
                    reservationId,
                    horaInicio: rowInReservas.hora_inicio || null,
                    horaFin: rowInReservas.hora_fin || null,
                    fecha: rowInReservas.fecha || null
                });
            } catch (_) {
                // No bloquear cambio de estado por fallo de notificacion.
            }
        }

        return {
            ok: verifiedStatus === normalizedStatus,
            code: 200,
            source: 'reservas',
            status: verifiedStatus,
            message: 'Estado actualizado'
        };
    }

    return { ok: false, code: 404, message: 'Reserva no encontrada' };
}

const SERVICE_NOTICE_TYPES = {
    cierre_temporal: 'aviso_cierre_temporal',
    habilitacion: 'aviso_habilitacion'
};

function normalizeServiceNoticeType(rawType) {
    const normalized = String(rawType || '').trim().toLowerCase();
    if (normalized === 'cierre_temporal' || normalized === 'cierre') {
        return 'cierre_temporal';
    }
    if (normalized === 'habilitacion' || normalized === 'habilitación') {
        return 'habilitacion';
    }
    return '';
}

function isValidDate(value) {
    return /^\d{4}-\d{2}-\d{2}$/.test(String(value || '').trim());
}

function isValidTime(value) {
    return /^([01]\d|2[0-3]):[0-5]\d$/.test(String(value || '').trim());
}

function isTimeRangeValid(start, end) {
    const safeStart = String(start || '').trim();
    const safeEnd = String(end || '').trim();
    return isValidTime(safeStart) && isValidTime(safeEnd) && safeStart < safeEnd;
}

function buildServiceNoticeNotificationText(type, fecha, horaInicio, horaFin, mensaje) {
    const cleanMessage = String(mensaje || '').trim();

    if (type === 'habilitacion') {
        return {
            titulo: 'Aviso de habilitacion',
            cuerpo: cleanMessage
                ? `El servicio estara habilitado el ${fecha} de ${horaInicio} a ${horaFin}. ${cleanMessage}`
                : `El servicio estara habilitado el ${fecha} de ${horaInicio} a ${horaFin}.`
        };
    }

    return {
        titulo: 'Aviso de cierre temporal',
        cuerpo: cleanMessage
            ? `El servicio estara cerrado temporalmente el ${fecha} de ${horaInicio} a ${horaFin}. ${cleanMessage}`
            : `El servicio estara cerrado temporalmente el ${fecha} de ${horaInicio} a ${horaFin}.`
    };
}

async function getServiceNoticeRecipients() {
    const { data, error } = await supabase
        .from('users')
        .select('id, id_autenticacion, rol, estado');

    if (error) {
        throw error;
    }

    const recipients = new Set();
    for (const user of data || []) {
        const role = String(user?.rol || '').toLowerCase().trim();
        const status = String(user?.estado || '').toLowerCase().trim();

        if (role === 'admin') continue;
        if (status === 'inactive' || status === 'inactivo' || status === 'blocked' || status === 'bloqueado') continue;

        if (user?.id) recipients.add(String(user.id));
    }

    return Array.from(recipients);
}

async function insertServiceNoticeWithColumnFallback(recipientIds, baseNotification) {
    if (!Array.isArray(recipientIds) || recipientIds.length === 0) {
        return { ok: true, inserted: 0, userColumn: null };
    }

    const userColumns = ['id_usuario_notif', 'id_usuario', 'usuario_id', 'user_id'];
    let lastError = null;

    for (const userColumn of userColumns) {
        const rows = recipientIds.map((userId) => ({
            ...baseNotification,
            [userColumn]: userId
        }));

        const { error } = await supabase
            .from('notificaciones_historial')
            .insert(rows);

        if (!error) {
            return {
                ok: true,
                inserted: rows.length,
                userColumn
            };
        }

        lastError = error;
    }

    return {
        ok: false,
        inserted: 0,
        userColumn: null,
        error: lastError
    };
}

function mapServiceNoticeHistory(rows) {
    const grouped = new Map();

    for (const row of rows || []) {
        const details = row?.datos && typeof row.datos === 'object' ? row.datos : {};
        const noticeId = String(details.aviso_id || row?.id || randomUUID());

        if (!grouped.has(noticeId)) {
            const rawType = String(details.tipo_aviso || '').toLowerCase().trim();
            const fallbackType = String(row?.tipo || '').toLowerCase().includes('habilit') ? 'habilitacion' : 'cierre_temporal';
            const normalizedType = rawType === 'habilitacion' || rawType === 'habilitación'
                ? 'habilitacion'
                : (rawType === 'cierre_temporal' ? 'cierre_temporal' : fallbackType);

            grouped.set(noticeId, {
                id: noticeId,
                tipo: normalizedType,
                titulo: row?.titulo || '',
                cuerpo: row?.cuerpo || '',
                mensaje: String(details.mensaje || '').trim(),
                fecha: details.fecha || null,
                hora_inicio: details.hora_inicio || null,
                hora_fin: details.hora_fin || null,
                destinatarios: Number(details.destinatarios || 0),
                created_at: row?.fecha_creacion || row?.created_at || null,
                inserted_rows: 0
            });
        }

        const current = grouped.get(noticeId);
        current.inserted_rows += 1;
    }

    return Array.from(grouped.values())
        .map((item) => ({
            ...item,
            destinatarios: item.destinatarios > 0 ? item.destinatarios : item.inserted_rows
        }))
        .sort((a, b) => {
            const aTime = new Date(a.created_at || 0).getTime();
            const bTime = new Date(b.created_at || 0).getTime();
            return bTime - aTime;
        });
}

app.post('/api/notifications/service-notices', async (req, res) => {
    try {
        const tipo = normalizeServiceNoticeType(req.body?.tipo);
        const fecha = String(req.body?.fecha || '').trim();
        const horaInicio = String(req.body?.hora_inicio || '').trim();
        const horaFin = String(req.body?.hora_fin || '').trim();
        const mensaje = String(req.body?.mensaje || '').trim();

        if (!tipo) {
            return res.status(400).json({ ok: false, message: 'Tipo de aviso invalido' });
        }
        if (!isValidDate(fecha)) {
            return res.status(400).json({ ok: false, message: 'Fecha invalida (usa formato YYYY-MM-DD)' });
        }
        if (!isTimeRangeValid(horaInicio, horaFin)) {
            return res.status(400).json({ ok: false, message: 'Rango horario invalido' });
        }

        const recipients = await getServiceNoticeRecipients();
        const avisoId = randomUUID();
        const { titulo, cuerpo } = buildServiceNoticeNotificationText(tipo, fecha, horaInicio, horaFin, mensaje);
        const dbType = SERVICE_NOTICE_TYPES[tipo];

        const notificationPayload = {
            titulo,
            cuerpo,
            tipo: dbType,
            datos: {
                aviso_id: avisoId,
                tipo_aviso: tipo,
                fecha,
                hora_inicio: horaInicio,
                hora_fin: horaFin,
                mensaje,
                destino: 'usuarios',
                origen: 'admin_panel_notificaciones',
                destinatarios: recipients.length,
                enviado_en: new Date().toISOString()
            },
            entregada: true,
            abierta: false
        };

        const inserted = await insertServiceNoticeWithColumnFallback(recipients, notificationPayload);
        if (!inserted.ok) {
            return res.status(500).json({
                ok: false,
                message: inserted.error?.message || 'No se pudo registrar el aviso en notificaciones_historial'
            });
        }

        return res.status(201).json({
            ok: true,
            message: inserted.inserted > 0
                ? 'Aviso enviado correctamente'
                : 'No hay usuarios destinatarios para este aviso',
            aviso: {
                id: avisoId,
                tipo,
                fecha,
                hora_inicio: horaInicio,
                hora_fin: horaFin,
                mensaje,
                titulo,
                cuerpo,
                destinatarios: inserted.inserted,
                created_at: new Date().toISOString()
            }
        });
    } catch (error) {
        console.error('❌ ERROR en POST /api/notifications/service-notices:', error.message);
        return res.status(500).json({ ok: false, message: 'Error creando aviso de servicio' });
    }
});

app.get('/api/notifications/service-notices', async (req, res) => {
    try {
        const parsedLimit = Number.parseInt(String(req.query?.limit || ''), 10);
        const limit = Number.isFinite(parsedLimit) ? Math.min(Math.max(parsedLimit, 1), 300) : 100;
        const typeFilter = [SERVICE_NOTICE_TYPES.cierre_temporal, SERVICE_NOTICE_TYPES.habilitacion];

        const attempts = [
            {
                select: 'id, tipo, titulo, cuerpo, datos, fecha_creacion',
                orderBy: 'fecha_creacion'
            },
            {
                select: 'id, tipo, titulo, cuerpo, datos, created_at',
                orderBy: 'created_at'
            }
        ];

        let result = null;
        for (const attempt of attempts) {
            const response = await supabase
                .from('notificaciones_historial')
                .select(attempt.select)
                .in('tipo', typeFilter)
                .order(attempt.orderBy, { ascending: false })
                .limit(limit * 20);

            if (!response.error) {
                result = response;
                break;
            }

            result = response;
        }

        if (result.error) {
            return res.status(400).json({ ok: false, message: result.error.message, data: [] });
        }

        const notices = mapServiceNoticeHistory(result.data || []).slice(0, limit);
        return res.status(200).json({ ok: true, data: notices });
    } catch (error) {
        console.error('❌ ERROR en GET /api/notifications/service-notices:', error.message);
        return res.status(500).json({ ok: false, message: 'Error obteniendo historial de avisos', data: [] });
    }
});

async function buildQrLookupPayload(rawToken, completeActiveReservation = false) {
    const token = parseQrToken(rawToken);
    if (!token) {
        return {
            code: 400,
            body: {
                found: false,
                valid: false,
                message: 'Token QR invalido'
            }
        };
    }

    const reservation = await findReservationByTokenOrId(token);

    if (!reservation) {
        return {
            code: 200,
            body: {
                found: false,
                valid: false,
                message: 'No tiene reserva registrada con ese QR'
            }
        };
    }

    const userId = reservation.id_usuario ? String(reservation.id_usuario) : '';

    let user = null;
    if (userId) {
        const { data: userData } = await supabase
            .from('users')
            .select('id, id_autenticacion, nombre, apellido, cedula, correo_electronico, email')
            .or(`id.eq.${userId},id_autenticacion.eq.${userId}`)
            .order('fecha_creacion', { ascending: false })
            .limit(1)
            .maybeSingle();
        user = userData || null;
    }

    const estadoOriginal = String(reservation.estado || '').toLowerCase().trim();
    let estadoFinal = estadoOriginal;
    let message = 'Reserva encontrada';

    if (completeActiveReservation && estadoOriginal === 'active') {
        const completionResult = await completeReservationBySource(reservation.id);
        if (completionResult.ok) {
            estadoFinal = 'completed';
            message = 'Ingreso validado. Reserva completada automaticamente.';
        } else {
            message = 'Reserva valida, pero no se pudo actualizar a completada.';
            console.log('⚠️ No se pudo marcar la reserva como completada:', completionResult.error || 'sin detalle');
        }
    }

    const isValidReservation = estadoFinal === 'active' || estadoFinal === 'completed';

    let userName = [user?.nombre, user?.apellido].filter(Boolean).join(' ').trim()
        || user?.nombre
        || null;
    let userEmail = user?.correo_electronico || user?.email || null;

    if (userId && (!userName || !userEmail)) {
        const { data: authUserData, error: authUserError } = await supabase.auth.admin.getUserById(userId);
        if (!authUserError && authUserData?.user) {
            const authUser = authUserData.user;
            const metadata = authUser.user_metadata || {};
            userName = userName
                || metadata.nombre_completo
                || metadata.full_name
                || metadata.name
                || null;
            userEmail = userEmail || authUser.email || null;
        }
    }

    if (userEmail && !userName) {
        const { data: userByEmailData, error: userByEmailError } = await supabase
            .from('users')
            .select('nombre, apellido, cedula, correo_electronico, email')
            .or(`correo_electronico.eq.${userEmail},email.eq.${userEmail}`)
            .order('fecha_creacion', { ascending: false })
            .limit(1)
            .maybeSingle();

        if (!userByEmailError && userByEmailData) {
            userName = userName
                || [userByEmailData.nombre, userByEmailData.apellido].filter(Boolean).join(' ').trim()
                || userByEmailData.nombre
                || null;
            userEmail = userEmail || userByEmailData.correo_electronico || userByEmailData.email || null;
        }
    }

    return {
        code: 200,
        body: {
            found: true,
            valid: isValidReservation,
            reservation_id: reservation.id,
            status: estadoFinal || 'unknown',
            message: isValidReservation
                ? message
                : 'La reserva no esta activa para ingreso',
            usuario_nombre: userName,
            usuario_email: userEmail,
            fecha_horario: reservation.fecha || null,
            hora_inicio: reservation.hora_inicio || null,
            hora_fin: reservation.hora_fin || null
        }
    };
}

// Ruta solo de consulta QR (sin efectos secundarios)
app.get('/api/qr-lookup', async (req, res) => {
    try {
        const result = await buildQrLookupPayload(req.query.token, false);
        return res.status(result.code).json(result.body);
    } catch (error) {
        console.error('❌ ERROR en /api/qr-lookup:', error.message);
        return res.status(500).json({
            found: false,
            valid: false,
            message: 'Error consultando QR',
            error: error.message
        });
    }
});

async function updateRowWithTimestampFallback(tableName, id, payload, timestampColumnCandidates = []) {
    const safePayload = { ...(payload || {}) };

    const attempts = [];
    if (timestampColumnCandidates.length > 0) {
        for (const tsColumn of timestampColumnCandidates) {
            attempts.push({ ...safePayload, [tsColumn]: new Date().toISOString() });
        }
    }
    attempts.push(safePayload);

    let lastError = null;
    for (const candidate of attempts) {
        const { error } = await supabase
            .from(tableName)
            .update(candidate)
            .eq('id', id);

        if (!error) {
            return { ok: true };
        }
        lastError = error;
    }

    return { ok: false, error: lastError };
}

app.patch('/api/users/:userId', async (req, res) => {
    try {
        const userId = String(req.params.userId || '').trim();
        if (!userId) return res.status(400).json({ ok: false, message: 'ID de usuario invalido' });

        const body = req.body || {};
        const payload = {};

        if (Object.prototype.hasOwnProperty.call(body, 'nombre')) {
            payload.nombre = String(body.nombre || '').trim();
        }
        if (Object.prototype.hasOwnProperty.call(body, 'apellido')) {
            payload.apellido = String(body.apellido || '').trim();
        }
        if (Object.prototype.hasOwnProperty.call(body, 'numero_documento')) {
            payload.numero_documento = String(body.numero_documento || '').trim();
        }
        if (!payload.numero_documento && Object.prototype.hasOwnProperty.call(body, 'cedula')) {
            payload.numero_documento = String(body.cedula || '').trim();
        }
        if (Object.prototype.hasOwnProperty.call(body, 'id_tipo_documento')) {
            const documentTypeId = Number(body.id_tipo_documento);
            if (!Number.isInteger(documentTypeId) || documentTypeId <= 0) {
                return res.status(400).json({ ok: false, message: 'Tipo de documento invalido' });
            }
            payload.id_tipo_documento = documentTypeId;
        }
        if (!payload.id_tipo_documento && Object.prototype.hasOwnProperty.call(body, 'Id_tipo_documento')) {
            const documentTypeId = Number(body.Id_tipo_documento);
            if (!Number.isInteger(documentTypeId) || documentTypeId <= 0) {
                return res.status(400).json({ ok: false, message: 'Tipo de documento invalido' });
            }
            payload.id_tipo_documento = documentTypeId;
        }
        if (!payload.id_tipo_documento && Object.prototype.hasOwnProperty.call(body, 'tipo_documento_id')) {
            const documentTypeId = Number(body.tipo_documento_id);
            if (!Number.isInteger(documentTypeId) || documentTypeId <= 0) {
                return res.status(400).json({ ok: false, message: 'Tipo de documento invalido' });
            }
            payload.id_tipo_documento = documentTypeId;
        }
        if (Object.prototype.hasOwnProperty.call(body, 'rol')) {
            payload.rol = String(body.rol || 'member').trim() || 'member';
        }
        if (Object.prototype.hasOwnProperty.call(body, 'estado')) {
            payload.estado = String(body.estado || 'active').trim() || 'active';
        }

        if (!payload.nombre || !payload.apellido || !payload.id_tipo_documento) {
            return res.status(400).json({ ok: false, message: 'Nombre, apellido y tipo de documento son requeridos' });
        }

        // Determinar qué columna de identificación usar (cedula o numero_documento)
        // Probamos ambas si una falla en el updateRowWithTimestampFallback
        const result = await updateRowWithTimestampFallback('users', userId, payload, ['fecha_actualizacion', 'updated_at']);
        
        if (!result.ok && payload.numero_documento && result.error?.message?.includes('numero_documento')) {
            console.log('⚠️ Reintentando con cedula en lugar de numero_documento...');
            const altPayload = { ...payload };
            altPayload.cedula = payload.numero_documento;
            delete altPayload.numero_documento;
            
            const secondResult = await updateRowWithTimestampFallback('users', userId, altPayload, ['fecha_actualizacion', 'updated_at']);
            if (secondResult.ok) {
                return res.status(200).json({ ok: true, message: 'Usuario actualizado (vía cedula)' });
            }
            result.error = secondResult.error;
        }

        if (!result.ok) {
            const message = String(result.error?.message || 'No se pudo actualizar usuario');
            if (message.toLowerCase().includes('duplicate') || message.toLowerCase().includes('unique')) {
                return res.status(409).json({ ok: false, message: 'La identificación ya esta registrada en otro usuario' });
            }
            return res.status(400).json({ ok: false, message: result.error?.message || 'No se pudo actualizar usuario' });
        }

        return res.status(200).json({ ok: true, message: 'Usuario actualizado' });
    } catch (error) {
        console.error('❌ ERROR en PATCH /api/users/:userId:', error.message);
        return res.status(500).json({ ok: false, message: 'Error actualizando usuario' });
    }
});

app.delete('/api/users/:userId', async (req, res) => {
    try {
        const userId = String(req.params.userId || '').trim();
        if (!userId) return res.status(400).json({ ok: false, message: 'ID de usuario invalido' });

        const { error } = await supabase
            .from('users')
            .delete()
            .eq('id', userId);

        if (error) {
            return res.status(400).json({ ok: false, message: error.message || 'No se pudo eliminar usuario' });
        }

        return res.status(200).json({ ok: true, message: 'Usuario eliminado' });
    } catch (error) {
        console.error('❌ ERROR en DELETE /api/users/:userId:', error.message);
        return res.status(500).json({ ok: false, message: 'Error eliminando usuario' });
    }
});

app.patch('/api/staff/:staffId', async (req, res) => {
    try {
        const staffId = String(req.params.staffId || '').trim();
        if (!staffId) return res.status(400).json({ ok: false, message: 'ID de personal invalido' });

        const payload = req.body || {};
        const result = await updateRowWithTimestampFallback('personal', staffId, payload, ['fecha_actualizacion', 'updated_at']);
        if (!result.ok) {
            return res.status(400).json({ ok: false, message: result.error?.message || 'No se pudo actualizar personal' });
        }

        return res.status(200).json({ ok: true, message: 'Personal actualizado' });
    } catch (error) {
        console.error('❌ ERROR en PATCH /api/staff/:staffId:', error.message);
        return res.status(500).json({ ok: false, message: 'Error actualizando personal' });
    }
});

app.delete('/api/staff/:staffId', async (req, res) => {
    try {
        const staffId = String(req.params.staffId || '').trim();
        if (!staffId) return res.status(400).json({ ok: false, message: 'ID de personal invalido' });

        const { error } = await supabase
            .from('personal')
            .delete()
            .eq('id', staffId);

        if (error) {
            return res.status(400).json({ ok: false, message: error.message || 'No se pudo eliminar personal' });
        }

        return res.status(200).json({ ok: true, message: 'Personal eliminado' });
    } catch (error) {
        console.error('❌ ERROR en DELETE /api/staff/:staffId:', error.message);
        return res.status(500).json({ ok: false, message: 'Error eliminando personal' });
    }
});

app.patch('/api/slots/:slotId', async (req, res) => {
    try {
        const slotId = String(req.params.slotId || '').trim();
        if (!slotId) return res.status(400).json({ ok: false, message: 'ID de horario invalido' });

        const payload = req.body || {};
        const result = await updateRowWithTimestampFallback('franjas_horarias', slotId, payload, ['fecha_actualizacion', 'updated_at']);
        if (!result.ok) {
            return res.status(400).json({ ok: false, message: result.error?.message || 'No se pudo actualizar horario' });
        }

        return res.status(200).json({ ok: true, message: 'Horario actualizado' });
    } catch (error) {
        console.error('❌ ERROR en PATCH /api/slots/:slotId:', error.message);
        return res.status(500).json({ ok: false, message: 'Error actualizando horario' });
    }
});

app.delete('/api/slots/:slotId', async (req, res) => {
    try {
        const slotId = String(req.params.slotId || '').trim();
        if (!slotId) return res.status(400).json({ ok: false, message: 'ID de horario invalido' });

        const { error } = await supabase
            .from('franjas_horarias')
            .delete()
            .eq('id', slotId);

        if (error) {
            return res.status(400).json({ ok: false, message: error.message || 'No se pudo eliminar horario' });
        }

        return res.status(200).json({ ok: true, message: 'Horario eliminado' });
    } catch (error) {
        console.error('❌ ERROR en DELETE /api/slots/:slotId:', error.message);
        return res.status(500).json({ ok: false, message: 'Error eliminando horario' });
    }
});

app.delete('/api/reservations/:reservationId', async (req, res) => {
    try {
        const reservationId = String(req.params.reservationId || '').trim();
        if (!reservationId) return res.status(400).json({ ok: false, message: 'ID de reserva invalido' });

        const { error } = await supabase
            .from('reservas')
            .delete()
            .eq('id', reservationId);

        if (error) {
            return res.status(400).json({ ok: false, message: error.message || 'No se pudo eliminar reserva' });
        }

        return res.status(200).json({ ok: true, message: 'Reserva eliminada' });
    } catch (error) {
        console.error('❌ ERROR en DELETE /api/reservations/:reservationId:', error.message);
        return res.status(500).json({ ok: false, message: 'Error eliminando reserva' });
    }
});

app.patch('/api/equipment/:equipmentId', async (req, res) => {
    try {
        const equipmentId = String(req.params.equipmentId || '').trim();
        if (!equipmentId) return res.status(400).json({ ok: false, message: 'ID de equipo invalido' });

        const payload = req.body || {};
        const result = await updateRowWithTimestampFallback('equipment', equipmentId, payload, ['fecha_actualizacion', 'updated_at']);
        if (!result.ok) {
            return res.status(400).json({ ok: false, message: result.error?.message || 'No se pudo actualizar equipo' });
        }

        return res.status(200).json({ ok: true, message: 'Equipo actualizado' });
    } catch (error) {
        console.error('❌ ERROR en PATCH /api/equipment/:equipmentId:', error.message);
        return res.status(500).json({ ok: false, message: 'Error actualizando equipo' });
    }
});

app.delete('/api/equipment/:equipmentId', async (req, res) => {
    try {
        const equipmentId = String(req.params.equipmentId || '').trim();
        if (!equipmentId) return res.status(400).json({ ok: false, message: 'ID de equipo invalido' });

        const { error } = await supabase
            .from('equipment')
            .delete()
            .eq('id', equipmentId);

        if (error) {
            return res.status(400).json({ ok: false, message: error.message || 'No se pudo eliminar equipo' });
        }

        return res.status(200).json({ ok: true, message: 'Equipo eliminado' });
    } catch (error) {
        console.error('❌ ERROR en DELETE /api/equipment/:equipmentId:', error.message);
        return res.status(500).json({ ok: false, message: 'Error eliminando equipo' });
    }
});

// Ruta de validacion + completado automatico al escanear QR
app.post('/api/qr-validate-and-complete', async (req, res) => {
    try {
        const result = await buildQrLookupPayload(req.body?.token, true);
        return res.status(result.code).json(result.body);
    } catch (error) {
        console.error('❌ ERROR en /api/qr-validate-and-complete:', error.message);
        return res.status(500).json({
            found: false,
            valid: false,
            message: 'Error validando QR',
            error: error.message
        });
    }
});

// Ruta segura para actualizar estado de reserva desde panel
app.post('/api/reservations/:reservationId/status', async (req, res) => {
    try {
        const reservationId = String(req.params.reservationId || '').trim();
        const nextStatus = req.body?.status;

        if (!reservationId) {
            return res.status(400).json({ ok: false, message: 'ID de reserva invalido' });
        }

        const result = await setReservationStatusById(reservationId, nextStatus);
        return res.status(result.code || 500).json({
            ok: !!result.ok,
            source: result.source || null,
            status: result.status || null,
            message: result.message || 'No se pudo actualizar estado'
        });
    } catch (error) {
        console.error('❌ ERROR en /api/reservations/:reservationId/status:', error.message);
        return res.status(500).json({ ok: false, message: 'Error actualizando estado de reserva' });
    }
});

// ============================================
// RUTA PARA ESTADÍSTICAS DEL DASHBOARD
// ============================================
app.get('/api/get-dashboard-stats', async (req, res) => {
    try {
        console.log(`\n📊 [GET /api/get-dashboard-stats] Solicitud recibida`);

        // Obtener conteos en paralelo
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        // Rango de los últimos 7 días para gráfica
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 6);
        sevenDaysAgo.setHours(0, 0, 0, 0);

        const [
            { count: totalUsers },
            { count: totalSlots },
            { count: todayReservations },
            { data: recentActivity },
            { count: totalReservas },
            { count: reservasCompletadas },
            { count: canceladasHoy },
            { data: reservas7dias }
        ] = await Promise.all([
            supabase.from('users').select('*', { count: 'exact', head: true }),
            supabase.from('franjas_horarias').select('*', { count: 'exact', head: true }),
            supabase.from('reservas')
                .select('*', { count: 'exact', head: true })
                .gte('fecha_creacion', today.toISOString()),
            supabase.from('reservas')
                .select('id, id_usuario, estado, fecha_creacion')
                .order('fecha_creacion', { ascending: false })
                .limit(10),
            supabase.from('reservas').select('*', { count: 'exact', head: true }),
            supabase.from('reservas')
                .select('*', { count: 'exact', head: true })
                .eq('estado', 'completed'),
            supabase.from('reservas')
                .select('*', { count: 'exact', head: true })
                .eq('estado', 'cancelled')
                .gte('fecha_creacion', today.toISOString()),
            supabase.from('reservas')
                .select('fecha_creacion')
                .gte('fecha_creacion', sevenDaysAgo.toISOString())
                .order('fecha_creacion', { ascending: true })
        ]);

        // Actividad reciente: últimos personal creados
        const { data: recentStaff } = await supabase
            .from('personal')
            .select('id, nombre_completo, rol, correo_electronico, fecha_creacion')
            .order('fecha_creacion', { ascending: false })
            .limit(5);

        // Combinar actividades
        const activities = [];

        (recentStaff || []).forEach(s => {
            activities.push({
                tipo: 'Personal',
                descripcion: `Nuevo administrador: ${s.nombre_completo} (${s.rol})`,
                usuario: s.correo_electronico,
                fecha: s.fecha_creacion
            });
        });

        (recentActivity || []).forEach(r => {
            activities.push({
                tipo: 'Reserva',
                descripcion: `Reserva ${r.estado || 'creada'}`,
                usuario: r.id_usuario,
                fecha: r.fecha_creacion
            });
        });

        // Ordenar por fecha más reciente
        activities.sort((a, b) => new Date(b.fecha) - new Date(a.fecha));

        // Tasa de asistencia
        const asistenciaRate = totalReservas > 0
            ? Math.round((reservasCompletadas / totalReservas) * 100)
            : 0;

        // Reservas por día (últimos 7 días)
        const diasMap = {};
        for (let i = 6; i >= 0; i--) {
            const d = new Date();
            d.setDate(d.getDate() - i);
            const key = d.toISOString().slice(0, 10);
            diasMap[key] = 0;
        }
        (reservas7dias || []).forEach(r => {
            const key = r.fecha_creacion ? r.fecha_creacion.slice(0, 10) : null;
            if (key && diasMap[key] !== undefined) diasMap[key]++;
        });
        const reservasPorDia = Object.entries(diasMap).map(([fecha, total]) => ({ fecha, total }));

        res.status(200).json({
            totalUsers: totalUsers || 0,
            todayReservations: todayReservations || 0,
            totalSlots: totalSlots || 0,
            asistenciaRate,
            canceladasHoy: canceladasHoy || 0,
            reservasPorDia,
            recentActivity: activities.slice(0, 8)
        });

    } catch (error) {
        console.error(`❌ ERROR en /api/get-dashboard-stats:`, error.message);
        res.status(500).json({ totalUsers: 0, todayReservations: 0, totalSlots: 0, recentActivity: [] });
    }
});

// ============================================
// RUTA PARA CREAR ADMINISTRADOR
// ============================================
app.post('/api/create-admin-user', async (req, res) => {
    try {
        const { email, password, nombre_completo, rol, telefono } = req.body;

        console.log(`\n📝 [POST /api/create-admin-user] Solicitud recibida`);
        console.log(`   Email: ${email}`);
        console.log(`   Nombre: ${nombre_completo}`);

        if (!email || !password) {
            console.log(`❌ Validación fallida: faltan campos`);
            return res.status(400).json({ 
                error: 'Email y password son requeridos' 
            });
        }

        // 1. Crear usuario en Supabase Auth
        console.log(`🔐 Creando usuario en Auth...`);
        const { data: authData, error: authError } = await supabase.auth.admin.createUser({
            email: email,
            password: password,
            email_confirm: true,
            user_metadata: {
                nombre_completo: nombre_completo,
            }
        });

        if (authError) {
            console.log(`❌ Error en Auth: ${authError.message}`);
            
            // Detectar email duplicado
            if (authError.message && authError.message.toLowerCase().includes('already')) {
                return res.status(409).json({
                    error: `El correo "${email}" ya está registrado`,
                    code: 'email_exists'
                });
            }
            
            return res.status(400).json({
                error: authError.message,
                code: 'auth_error'
            });
        }

        if (!authData?.user?.id) {
            console.log(`❌ No se creó usuario en Auth`);
            return res.status(500).json({ 
                error: 'Error al crear usuario en Auth' 
            });
        }

        console.log(`✅ Usuario Auth creado: ${authData.user.id}`);

        // 2. Guardar en tabla personal
        console.log(`💾 Guardando en tabla personal...`);
        const { data: staffData, error: staffError } = await supabase
            .from('personal')
            .insert({
                nombre_completo: nombre_completo,
                rol: rol || 'Instructor',
                correo_electronico: email,
                teléfono: telefono || '',
                estado: 'active'
            })
            .select()
            .single();

        if (staffError) {
            console.log(`⚠️  Error guardando en personal: ${staffError.message}`);
            // No fallar, el usuario en Auth se creó
        } else {
            console.log(`✅ Personal guardado: ${staffData?.id}`);
        }

        // 3. Enviar respuesta
        const response = {
            user: {
                id: authData.user.id,
                email: authData.user.email,
                nombre_completo: nombre_completo
            },
            staff: staffData || null
        };

        console.log(`📤 Enviando respuesta 200 OK`);
        res.status(200).json(response);

    } catch (error) {
        console.error(`❌ ERROR en /api/create-admin-user:`, error.message);
        res.status(500).json({
            error: error.message || 'Error desconocido',
            type: error.name
        });
    }
});

// ============================================
// RUTAS DE HORARIOS (TEMPLATES + CALENDARIO)
// ============================================

app.get('/api/calendar', async (req, res) => {
    try {
        const month = req.query.month;
        if (!month) return res.status(400).json({ error: 'month required (YYYY-MM)' });

        const [year, m] = month.split('-').map(Number);
        const firstDay = new Date(year, m - 1, 1);
        const lastDay = new Date(year, m, 0);

        const { data: templates } = await supabase
            .from('franjas_horarias')
            .select('id, nombre, hora_inicio, hora_fin, capacidad')
            .eq('activo', true);

        const { data: cierres } = await supabase
            .from('cierres_gym')
            .select('id, fecha, turno, motivo')
            .gte('fecha', firstDay.toISOString().slice(0, 10))
            .lte('fecha', lastDay.toISOString().slice(0, 10));

        const cierresMap = {};
        (cierres || []).forEach(c => {
            if (!cierresMap[c.fecha]) cierresMap[c.fecha] = [];
            cierresMap[c.fecha].push(c);
        });

        const { data: reservas } = await supabase
            .from('reservas')
            .select('hora_inicio, fecha')
            .eq('estado', 'active')
            .gte('fecha', firstDay.toISOString().slice(0, 10))
            .lte('fecha', lastDay.toISOString().slice(0, 10));

        // Contar por fecha + hora_inicio (primeros 5 chars: "HH:MM")
        const reservasCount = {};
        (reservas || []).forEach(r => {
            const hora = String(r.hora_inicio || '').slice(0, 5);
            if (!hora) return;
            const key = `${r.fecha}_${hora}`;
            reservasCount[key] = (reservasCount[key] || 0) + 1;
        });

        const result = [];
        const cursor = new Date(firstDay);
        while (cursor <= lastDay) {
            const fechaStr = cursor.toISOString().slice(0, 10);
            const diaCierres = cierresMap[fechaStr] || [];
            const diaCerradoCompleto = diaCierres.some(c => !c.turno || c.turno === '');

            const slots = (templates || []).map(t => {
                const turnoCerrado = diaCierres.some(c => c.turno === t.nombre);
                const bloqueado = diaCerradoCompleto || turnoCerrado;
                const horaKey = String(t.hora_inicio || '').slice(0, 5);
                const reservado = reservasCount[`${fechaStr}_${horaKey}`] || 0;
                return {
                    slotId: t.id, nombre: t.nombre, horaInicio: t.hora_inicio,
                    horaFin: t.hora_fin, capacidad: t.capacidad, reservado,
                    libre: bloqueado ? 0 : Math.max(0, t.capacidad - reservado), bloqueado
                };
            });

            const estado = diaCerradoCompleto ? 'cerrado'
                : slots.some(s => s.bloqueado) ? 'parcial' : 'abierto';

            result.push({ fecha: fechaStr, estado, slots, cierres: diaCierres, totalLibre: slots.reduce((s, x) => s + x.libre, 0) });
            cursor.setDate(cursor.getDate() + 1);
        }

        res.json(result);
    } catch (e) {
        console.error('Calendar error:', e.message);
        res.status(500).json({ error: e.message });
    }
});

app.post('/api/cierres', async (req, res) => {
    try {
        const { fecha, turno, motivo } = req.body;
        if (!fecha) return res.status(400).json({ error: 'fecha requerida' });

        const { data, error } = await supabase
            .from('cierres_gym')
            .insert({
                fecha,
                turno: turno || null,
                hora_inicio: null,
                hora_fin: null,
                motivo: motivo || '',
                fecha_creacion: new Date().toISOString()
            })
            .select()
            .single();

        if (error) return res.status(400).json({ error: error.message });

        try {
            const { data: usersData } = await supabase
                .from('users')
                .select('id')
                .neq('rol', 'admin');
            if (usersData && usersData.length > 0) {
                const turnoMsg = turno ? ` (turno ${turno})` : '';
                const motivoMsg = motivo ? ` por: ${motivo}` : '';
                await supabase.from('notificaciones_historial').insert(
                    usersData.map(u => ({
                        id_usuario_notif: u.id,
                        titulo: 'Gimnasio cerrado',
                        cuerpo: `El gimnasio estara cerrado el ${fecha}${turnoMsg}${motivoMsg}`,
                        tipo: 'cierre_gimnasio', entregada: false, abierta: false,
                        datos: { fecha, turno: turno || 'completo', motivo: motivo || '' }
                    }))
                );
            }
        } catch (notifError) {
            console.warn('Notificacion cierre fallo:', notifError.message);
        }

        res.json({ ok: true, data });
    } catch (e) {
        console.error('Cierre error:', e.message);
        res.status(500).json({ error: e.message });
    }
});

app.delete('/api/cierres/:id', async (req, res) => {
    try {
        const { error } = await supabase.from('cierres_gym').delete().eq('id', req.params.id);
        if (error) return res.status(400).json({ error: error.message });
        res.json({ ok: true });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Servir archivos estáticos desde la carpeta actual
console.log(`📂 Sirviendo archivos estáticos desde: ${__dirname}`);
app.use(express.static(path.join(__dirname)));

// Redirigir raíz al login
app.get('/', (req, res) => {
    console.log('🔄 Redireccionando / a /login.html');
    res.redirect('/login.html');
});

// Catch-all para otras rutas - sirve login.html como SPA
app.get('*', (req, res) => {
    console.log(`📝 Catch-all: Sirviendo login.html para ruta: ${req.path}`);
    res.sendFile(path.join(__dirname, 'login.html'));
});

// Iniciar servidor - con error handling
const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`\n${'='.repeat(50)}`);
    console.log('✅ JACEK GYM Admin Panel - SERVIDOR INICIADO');
    console.log(`${'='.repeat(50)}`);
    console.log(`🌐 URL: http://localhost:${PORT}`);
    console.log(`📧 Login: http://localhost:${PORT}/login.html`);
    console.log(`👥 Personal: http://localhost:${PORT}/personal.html`);
    console.log(`📋 Dashboard: http://localhost:${PORT}/dashboard.html`);
    console.log(`${'='.repeat(50)}\n`);
});

server.on('error', (err) => {
    console.error('❌ Error del servidor:', err);
    process.exit(1);
});

process.on('SIGTERM', () => {
    console.log('📛 SIGTERM recibido - cerrando servidor');
    server.close(() => process.exit(0));
});
