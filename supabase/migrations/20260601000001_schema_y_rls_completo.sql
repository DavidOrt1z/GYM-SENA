-- =====================================================
-- MIGRACIÓN COMPLETA - SISTEMA JACEK GYM
-- Fecha: 2026-05-10
-- Descripción: Esquema completo con RLS (esquema real en español)
-- =====================================================

-- =====================================================
-- PARTE 1: ESQUEMA DE TABLAS
-- =====================================================

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- TABLA: users (Usuarios del sistema)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_autenticacion UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre VARCHAR(255),
    apellido VARCHAR(255),
    correo_electronico VARCHAR(255) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    rol VARCHAR(50) NOT NULL DEFAULT 'member' CHECK (rol IN ('member', 'admin', 'instructor', 'administrative')),
    estado VARCHAR(50) NOT NULL DEFAULT 'active' CHECK (estado IN ('active', 'inactive', 'pending', 'bloqueado')),
    edad INTEGER,
    altura_cm DECIMAL(5,2),
    peso_kg DECIMAL(5,2),
    unidades VARCHAR(20) DEFAULT 'metric' CHECK (unidades IN ('metric', 'imperial')),
    idioma VARCHAR(5) DEFAULT 'es' CHECK (idioma IN ('es', 'en')),
    notificaciones_activas BOOLEAN DEFAULT true,
    url_avatar TEXT,
    Id_tipo_documento INTEGER REFERENCES public.tipo_documentos(id),
    numero_documento VARCHAR(50),
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ultima_notificacion TIMESTAMP WITH TIME ZONE,
    token_fcm TEXT
);

-- =====================================================
-- TABLA: tipo_documentos (Tipos de documento)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.tipo_documentos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

-- =====================================================
-- TABLA: personal (Personal del gimnasio)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.personal (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre_completo VARCHAR(255) NOT NULL,
    rol VARCHAR(100) NOT NULL,
    correo_electronico VARCHAR(255) UNIQUE NOT NULL,
    teléfono VARCHAR(20),
    estado VARCHAR(50) NOT NULL DEFAULT 'active' CHECK (estado IN ('active', 'inactive')),
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TABLA: franjas_horarias (Horarios disponibles)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.franjas_horarias (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fecha DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    capacidad INTEGER NOT NULL DEFAULT 20,
    cantidad_reservada INTEGER NOT NULL DEFAULT 0,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_capacity CHECK (cantidad_reservada <= capacidad),
    CONSTRAINT valid_time CHECK (hora_inicio < hora_fin)
);

-- =====================================================
-- TABLA: reservas (Reservas)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.reservas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID REFERENCES public.users(id) ON DELETE CASCADE,
    id_franja_horaria UUID REFERENCES public.franjas_horarias(id) ON DELETE CASCADE,
    estado VARCHAR(50) NOT NULL DEFAULT 'active' CHECK (estado IN ('active', 'cancelled', 'completed')),
    token_qr VARCHAR(255) UNIQUE NOT NULL,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TABLA: comentarios (Comentarios/Feedback)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.comentarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID REFERENCES public.users(id) ON DELETE CASCADE,
    correo_electronico VARCHAR(255),
    mensaje TEXT NOT NULL,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TABLA: registros_peso (Registro de peso)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.registros_peso (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID REFERENCES public.users(id) ON DELETE CASCADE,
    fecha TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    peso_kg DECIMAL(5,2) NOT NULL,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TABLA: regiones (Regionales SENA)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.regiones (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

-- =====================================================
-- TABLA: centros_formacion (Centros de formación SENA)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.centros_formacion (
    codigo_centro SERIAL PRIMARY KEY,
    regional_id INTEGER REFERENCES public.regiones(id),
    nombre_centro VARCHAR(255) NOT NULL
);

-- =====================================================
-- TABLA: notificaciones (Notificaciones)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.notificaciones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    título VARCHAR(255) NOT NULL,
    cuerpo TEXT NOT NULL,
    destino VARCHAR(50) NOT NULL DEFAULT 'all',
    id_usuario_destino UUID REFERENCES public.users(id) ON DELETE CASCADE,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TABLA: notificaciones_historial (Historial de notificaciones)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.notificaciones_historial (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario_notif UUID REFERENCES public.users(id) ON DELETE CASCADE,
    titulo TEXT,
    cuerpo TEXT,
    tipo VARCHAR(50),
    datos JSONB,
    entregada BOOLEAN DEFAULT false,
    abierta BOOLEAN DEFAULT false,
    fecha_apertura TIMESTAMP WITH TIME ZONE,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TABLA: notif_configuracion (Configuración de notificaciones)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.notif_configuracion (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID REFERENCES public.users(id) ON DELETE CASCADE,
    reservas BOOLEAN DEFAULT true,
    recordatorios BOOLEAN DEFAULT true,
    cambios_horario BOOLEAN DEFAULT true,
    marketing BOOLEAN DEFAULT false,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TABLA: notif_suscripciones_topic (Suscripciones a topics)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.notif_suscripciones_topic (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID REFERENCES public.users(id) ON DELETE CASCADE,
    tema VARCHAR(100) NOT NULL,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TABLA: tipoejercicio (Tipos de ejercicio)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.tipoejercicio (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

-- =====================================================
-- TABLA: ejercicios (Ejercicios)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.ejercicios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    idtipoejercicio INTEGER REFERENCES public.tipoejercicio(id),
    link TEXT
);

-- =====================================================
-- TABLA: tickets_soporte (Tickets de soporte)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.tickets_soporte (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID REFERENCES public.users(id) ON DELETE CASCADE,
    mensaje TEXT NOT NULL,
    estado VARCHAR(50) NOT NULL DEFAULT 'open' CHECK (estado IN ('open', 'closed')),
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- ÍNDICES para optimizar consultas
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(correo_electronico);
CREATE INDEX IF NOT EXISTS idx_users_auth ON public.users(id_autenticacion);
CREATE INDEX IF NOT EXISTS idx_users_rol ON public.users(rol);
CREATE INDEX IF NOT EXISTS idx_users_estado ON public.users(estado);
CREATE INDEX IF NOT EXISTS idx_franjas_fecha ON public.franjas_horarias(fecha);
CREATE INDEX IF NOT EXISTS idx_reservas_usuario ON public.reservas(id_usuario);
CREATE INDEX IF NOT EXISTS idx_reservas_franja ON public.reservas(id_franja_horaria);
CREATE INDEX IF NOT EXISTS idx_reservas_estado ON public.reservas(estado);
CREATE INDEX IF NOT EXISTS idx_registros_usuario ON public.registros_peso(id_usuario);
CREATE INDEX IF NOT EXISTS idx_notif_usuario_destino ON public.notificaciones(id_usuario_destino);

-- =====================================================
-- TRIGGERS para fecha_actualizacion
-- =====================================================
CREATE OR REPLACE FUNCTION actualizar_timestamp_usuarios()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp_usuarios();

CREATE TRIGGER trigger_personal_updated_at BEFORE UPDATE ON public.personal
    FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp_usuarios();

CREATE TRIGGER trigger_franjas_updated_at BEFORE UPDATE ON public.franjas_horarias
    FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp_usuarios();

CREATE TRIGGER trigger_reservas_updated_at BEFORE UPDATE ON public.reservas
    FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp_usuarios();

CREATE TRIGGER trigger_tickets_updated_at BEFORE UPDATE ON public.tickets_soporte
    FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp_usuarios();

-- =====================================================
-- PARTE 2: FUNCIONES DE SEGURIDAD
-- =====================================================

-- FUNCIÓN: is_admin()
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.users
        WHERE id_autenticacion = auth.uid()
        AND rol = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- FUNCIÓN: get_user_role()
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS VARCHAR AS $$
DECLARE
    user_role VARCHAR;
BEGIN
    SELECT rol INTO user_role
    FROM public.users
    WHERE id_autenticacion = auth.uid();
    RETURN user_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- FUNCIÓN: generar token QR
CREATE OR REPLACE FUNCTION public.generate_qr_token()
RETURNS VARCHAR AS $$
BEGIN
    RETURN 'resv:' || encode(gen_random_bytes(16), 'hex');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- PARTE 3: ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.personal ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.franjas_horarias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reservas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comentarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.registros_peso ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regiones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.centros_formacion ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notificaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notificaciones_historial ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notif_configuracion ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notif_suscripciones_topic ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tipoejercicio ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ejercicios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tickets_soporte ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS: users
-- =====================================================
CREATE POLICY "Users are viewable by authenticated users" ON public.users
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (id_autenticacion = auth.uid() OR id = auth.uid())
    WITH CHECK (id_autenticacion = auth.uid() OR id = auth.uid());

CREATE POLICY "Admins can manage all users" ON public.users
    FOR ALL USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "Allow user creation during signup" ON public.users
    FOR INSERT WITH CHECK (id_autenticacion = auth.uid() OR id = auth.uid());

CREATE POLICY "Users can claim profile by email" ON public.users
    FOR UPDATE USING (id_autenticacion IS NULL AND lower(correo_electronico) = lower(COALESCE(auth.jwt() ->> 'email', '')))
    WITH CHECK (id_autenticacion = auth.uid() AND lower(correo_electronico) = lower(COALESCE(auth.jwt() ->> 'email', '')));

-- =====================================================
-- RLS: personal
-- =====================================================
CREATE POLICY "Staff are viewable by authenticated users" ON public.personal
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can manage staff" ON public.personal
    FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- =====================================================
-- RLS: franjas_horarias
-- =====================================================
CREATE POLICY "Slots are viewable by authenticated users" ON public.franjas_horarias
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can manage slots" ON public.franjas_horarias
    FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- =====================================================
-- RLS: reservas
-- =====================================================
CREATE POLICY "Users can view own reservations" ON public.reservas
    FOR SELECT USING (id_usuario IN (SELECT id FROM users WHERE id_autenticacion = auth.uid()) OR is_admin());

CREATE POLICY "Users can create reservations" ON public.reservas
    FOR INSERT WITH CHECK (id_usuario IN (SELECT id FROM users WHERE id_autenticacion = auth.uid()));

CREATE POLICY "Users can cancel own reservations" ON public.reservas
    FOR UPDATE USING (id_usuario IN (SELECT id FROM users WHERE id_autenticacion = auth.uid()) OR id_usuario = auth.uid() OR is_admin())
    WITH CHECK ((id_usuario IN (SELECT id FROM users WHERE id_autenticacion = auth.uid()) OR id_usuario = auth.uid() OR is_admin()) AND (is_admin() OR estado = 'cancelled'));

CREATE POLICY "Admins can delete reservations" ON public.reservas
    FOR DELETE USING (is_admin());

-- =====================================================
-- RLS: comentarios
-- =====================================================
CREATE POLICY "Users can view their own feedback" ON public.comentarios
    FOR SELECT USING (auth.uid() = id_usuario);

CREATE POLICY "Users can insert their own feedback" ON public.comentarios
    FOR INSERT WITH CHECK (auth.uid() = id_usuario);

-- =====================================================
-- RLS: registros_peso
-- =====================================================
CREATE POLICY "Users can view own weight logs" ON public.registros_peso
    FOR SELECT USING (id_usuario IN (SELECT id FROM users WHERE id_autenticacion = auth.uid()) OR is_admin());

CREATE POLICY "Users can insert own weight logs" ON public.registros_peso
    FOR INSERT WITH CHECK (id_usuario IN (SELECT id FROM users WHERE id_autenticacion = auth.uid()));

CREATE POLICY "Users can update own weight logs" ON public.registros_peso
    FOR UPDATE USING (id_usuario IN (SELECT id FROM users WHERE id_autenticacion = auth.uid()) OR is_admin());

CREATE POLICY "Users can delete own weight logs" ON public.registros_peso
    FOR DELETE USING (id_usuario IN (SELECT id FROM users WHERE id_autenticacion = auth.uid()) OR is_admin());

-- =====================================================
-- RLS: regiones
-- =====================================================
CREATE POLICY "regiones_insert_admin" ON public.regiones
    FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND rol = 'admin'));

CREATE POLICY "regiones_select_auth" ON public.regiones
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "regiones_update_admin" ON public.regiones
    FOR UPDATE USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND rol = 'admin'));

CREATE POLICY "regiones_delete_admin" ON public.regiones
    FOR DELETE USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND rol = 'admin'));

-- =====================================================
-- RLS: centros_formacion
-- =====================================================
CREATE POLICY "centros_insert_admin" ON public.centros_formacion
    FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND rol = 'admin'));

CREATE POLICY "centros_select_auth" ON public.centros_formacion
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "centros_update_admin" ON public.centros_formacion
    FOR UPDATE USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND rol = 'admin'));

CREATE POLICY "centros_delete_admin" ON public.centros_formacion
    FOR DELETE USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND rol = 'admin'));

-- =====================================================
-- RLS: notificaciones
-- =====================================================
CREATE POLICY "Users can view notifications" ON public.notificaciones
    FOR SELECT USING ((destino = 'all') OR (id_usuario_destino IN (SELECT id FROM users WHERE id_autenticacion = auth.uid())) OR is_admin());

CREATE POLICY "Admins can manage notifications" ON public.notificaciones
    FOR ALL USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "notificaciones_insert_sistema" ON public.notificaciones
    FOR INSERT WITH CHECK (true);

-- =====================================================
-- RLS: notificaciones_historial
-- =====================================================
CREATE POLICY "Sistema puede insertar historial" ON public.notificaciones_historial
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Usuarios actualizan su historial" ON public.notificaciones_historial
    FOR UPDATE USING (auth.uid() = id_usuario_notif OR is_admin())
    WITH CHECK (auth.uid() = id_usuario_notif OR is_admin());

CREATE POLICY "Usuarios ven su propio historial" ON public.notificaciones_historial
    FOR SELECT USING (auth.uid() = id_usuario_notif OR is_admin());

CREATE POLICY "notificaciones_historial_insert_usuarios" ON public.notificaciones_historial
    FOR INSERT WITH CHECK (auth.uid() = id_usuario_notif OR is_admin());

-- =====================================================
-- RLS: notif_configuracion
-- =====================================================
CREATE POLICY "Usuarios crean su configuración" ON public.notif_configuracion
    FOR INSERT WITH CHECK (auth.uid() = id_usuario);

CREATE POLICY "Usuarios ven su configuración" ON public.notif_configuracion
    FOR SELECT USING (auth.uid() = id_usuario OR is_admin());

CREATE POLICY "Usuarios actualizan su configuración" ON public.notif_configuracion
    FOR UPDATE USING (auth.uid() = id_usuario);

-- =====================================================
-- RLS: notif_suscripciones_topic
-- =====================================================
CREATE POLICY "Usuarios pueden suscribirse" ON public.notif_suscripciones_topic
    FOR INSERT WITH CHECK (auth.uid() = id_usuario);

CREATE POLICY "Usuarios ven sus suscripciones" ON public.notif_suscripciones_topic
    FOR SELECT USING (auth.uid() = id_usuario OR is_admin());

CREATE POLICY "Usuarios pueden desuscribirse" ON public.notif_suscripciones_topic
    FOR DELETE USING (auth.uid() = id_usuario);

-- =====================================================
-- RLS: tipoejercicio
-- =====================================================
CREATE POLICY "Allow all users to read tipo_documentos" ON public.tipoejercicio
    FOR SELECT USING (true);

CREATE POLICY "tipoejercicio_admin_all" ON public.tipoejercicio
    FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- =====================================================
-- RLS: ejercicios
-- =====================================================
CREATE POLICY "ejercicios_select_all" ON public.ejercicios
    FOR SELECT USING (true);

CREATE POLICY "ejercicios_admin_all" ON public.ejercicios
    FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- =====================================================
-- RLS: tickets_soporte
-- =====================================================
CREATE POLICY "Users can create tickets" ON public.tickets_soporte
    FOR INSERT WITH CHECK (id_usuario IN (SELECT id FROM users WHERE id_autenticacion = auth.uid()));

CREATE POLICY "Users can view own tickets" ON public.tickets_soporte
    FOR SELECT USING (id_usuario IN (SELECT id FROM users WHERE id_autenticacion = auth.uid()) OR is_admin());

CREATE POLICY "Admins can manage tickets" ON public.tickets_soporte
    FOR ALL USING (is_admin()) WITH CHECK (is_admin());
