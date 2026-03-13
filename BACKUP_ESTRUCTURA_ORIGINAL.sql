-- ============================================================================
-- BACKUP DE LA ESTRUCTURA ORIGINAL DE LA BASE DE DATOS
-- Generado: 5 de marzo de 2026
-- ============================================================================

-- TABLAS ACTUALES:

-- 1. TABLE: public.users (Usuarios del sistema - miembros, admins, instructores)
-- Columnas:
--   - id (uuid, PK)
--   - auth_id (uuid, FK → auth.users.id)
--   - full_name (varchar)
--   - email (varchar, UNIQUE)
--   - phone (varchar, nullable)
--   - age (int, nullable)
--   - height_cm (numeric, nullable)
--   - weight_kg (numeric, nullable)
--   - role (varchar, CHECK: member|admin|instructor|administrative)
--   - status (varchar, CHECK: active|inactive|pending)
--   - units (varchar, CHECK: metric|imperial)
--   - language (varchar, CHECK: es|en)
--   - notif_enabled (boolean)
--   - avatar_url (text, nullable)
--   - last_name (varchar, nullable)
--   - fcm_token (text, nullable)
--   - notificaciones_habilitadas (boolean)
--   - ultima_notificacion (timestamptz, nullable)
--   - created_at (timestamptz)
--   - updated_at (timestamptz)
-- RLS: ENABLED
-- Filas: 2

-- 2. TABLE: public.weight_logs (Registro histórico de peso de usuarios)
-- Columnas:
--   - id (uuid, PK)
--   - user_id (uuid, FK → users.id)
--   - weight_kg (numeric)
--   - date (timestamptz, nullable)
--   - created_at (timestamptz)
-- RLS: ENABLED
-- Filas: 0

-- 3. TABLE: public.slots (Horarios disponibles para reservar)
-- Columnas:
--   - id (uuid, PK)
--   - date (date)
--   - start_time (time)
--   - end_time (time)
--   - capacity (int, default=20)
--   - reserved_count (int, default=0)
--   - created_at (timestamptz)
--   - updated_at (timestamptz)
-- RLS: ENABLED
-- Filas: 0

-- 4. TABLE: public.reservations (Reservas de usuarios)
-- Columnas:
--   - id (uuid, PK)
--   - user_id (uuid, FK → users.id)
--   - slot_id (uuid, FK → slots.id)
--   - qr_token (varchar, UNIQUE)
--   - status (varchar, CHECK: active|cancelled|completed)
--   - created_at (timestamptz)
--   - updated_at (timestamptz)
-- RLS: ENABLED
-- Filas: 0

-- 5. TABLE: public.staff (Personal del gimnasio)
-- Columnas:
--   - id (uuid, PK)
--   - full_name (varchar)
--   - role (varchar)
--   - email (varchar, UNIQUE)
--   - phone (varchar, nullable)
--   - status (varchar, CHECK: active|inactive)
--   - created_at (timestamptz)
--   - updated_at (timestamptz)
-- RLS: ENABLED
-- Filas: 0

-- 6. TABLE: public.notifications (Notificaciones del sistema)
-- Columnas:
--   - id (uuid, PK)
--   - title (varchar)
--   - body (text)
--   - target_user_id (uuid, FK → users.id, nullable)
--   - target (varchar, default='all')
--   - created_at (timestamptz)
-- RLS: ENABLED
-- Filas: 0

-- 7. TABLE: public.support_tickets (Tickets de soporte técnico)
-- Columnas:
--   - id (uuid, PK)
--   - user_id (uuid, FK → users.id)
--   - message (text)
--   - status (varchar, CHECK: open|closed)
--   - created_at (timestamptz)
--   - updated_at (timestamptz)
-- RLS: ENABLED
-- Filas: 0

-- 8. TABLE: public.feedback
-- Columnas:
--   - id (uuid, PK)
--   - user_id (uuid, FK → auth.users.id)
--   - email (varchar, nullable)
--   - message (text)
--   - created_at (timestamptz)
--   - updated_at (timestamptz)
-- RLS: ENABLED
-- Filas: 1

-- 9. TABLE: public.notificaciones_historial (ya en español)
-- Columnas:
--   - id (uuid, PK)
--   - usuario_id (uuid, FK → users.id)
--   - titulo (text)
--   - cuerpo (text)
--   - tipo (varchar)
--   - datos (jsonb)
--   - entregada (boolean)
--   - abierta (boolean)
--   - fecha_apertura (timestamptz, nullable)
--   - created_at (timestamptz)
--   - updated_at (timestamptz)
-- RLS: ENABLED
-- Filas: 0

-- 10. TABLE: public.notif_suscripciones_topic (ya en español)
-- Columnas:
--   - id (uuid, PK)
--   - usuario_id (uuid, FK → users.id)
--   - topic (varchar)
--   - created_at (timestamptz)
-- RLS: ENABLED
-- Filas: 0

-- 11. TABLE: public.notif_configuracion (ya en español)
-- Columnas:
--   - id (uuid, PK)
--   - usuario_id (uuid, UNIQUE, FK → users.id)
--   - reservas (boolean, default=true)
--   - recordatorios (boolean, default=true)
--   - equipamiento (boolean)
--   - entrenamientos (boolean)
--   - eventos (boolean)
--   - actualizaciones (boolean)
--   - created_at (timestamptz)
--   - updated_at (timestamptz)
-- RLS: ENABLED
-- Filas: 0

-- ============================================================================
-- MIGRACIONES APLICADAS:
-- ============================================================================
-- 1. 20251218000001 - initial_schema
-- 2. 20251218000002 - rls_policies
-- 3. 20260227213509 - add_admin_panel_rls_policies
-- 4. 20260227213750 - add_last_name_to_users
-- 5. 20260227213906 - add_notifications

-- ============================================================================
-- MIGRACIÓN APLICADA: 5 de marzo de 2026
-- Estado: ✅ EXITOSA
-- ============================================================================

-- CAMBIOS REALIZADOS:

-- TABLAS RENOMBRADAS:
--   weight_logs → registros_peso
--   slots → franjas_horarias
--   reservations → reservas
--   notifications → notificaciones
--   support_tickets → tickets_soporte
--   feedback → comentarios

-- COLUMNAS RENOMBRADAS EN users:
--   full_name → nombre_completo
--   email → correo_electronico
--   phone → teléfono
--   age → edad
--   height_cm → altura_cm
--   weight_kg → peso_kg
--   auth_id → id_autenticacion
--   role → rol
--   status → estado
--   units → unidades
--   language → idioma
--   notif_enabled → notificaciones_activas
--   avatar_url → url_avatar
--   last_name → apellido
--   fcm_token → token_fcm

-- COLUMNAS RENOMBRADAS EN registros_peso:
--   user_id → id_usuario
--   weight_kg → peso_kg
--   date → fecha

-- COLUMNAS RENOMBRADAS EN franjas_horarias:
--   date → fecha
--   start_time → hora_inicio
--   end_time → hora_fin
--   capacity → capacidad
--   reserved_count → cantidad_reservada

-- COLUMNAS RENOMBRADAS EN reservas:
--   user_id → id_usuario
--   slot_id → id_franja_horaria
--   qr_token → token_qr
--   status → estado

-- COLUMNAS RENOMBRADAS EN personal:
--   full_name → nombre_completo
--   email → correo_electronico
--   phone → teléfono
--   role → rol
--   status → estado

-- COLUMNAS RENOMBRADAS EN notificaciones:
--   title → título
--   body → cuerpo
--   target_user_id → id_usuario_destino
--   target → destino

-- COLUMNAS RENOMBRADAS EN tickets_soporte:
--   user_id → id_usuario
--   message → mensaje
--   status → estado

-- COLUMNAS RENOMBRADAS EN comentarios:
--   user_id → id_usuario
--   email → correo_electronico
--   message → mensaje

-- COLUMNAS RENOMBRADAS EN notif_suscripciones_topic:
--   usuario_id → id_usuario
--   topic → tema

-- COLUMNAS RENOMBRADAS EN notif_configuracion:
--   usuario_id → id_usuario

-- ============================================================================
-- NOTA IMPORTANTE:
-- ============================================================================
-- La base de datos ha sido completamente traducida al español.
-- Asegúrate de actualizar:
-- 1. El código de la aplicación Flutter (referencias en servicios/providers)
-- 2. El código del admin panel (referencias en JavaScript)
-- 3. Las migraciones futuras (usar nombres en español)
-- ============================================================================
