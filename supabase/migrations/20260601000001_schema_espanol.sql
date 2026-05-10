-- =====================================================
-- MIGRACIÓN ACTUALIZADA - SISTEMA JACEK GYM
-- Fecha: 2026-05-10
-- Descripción: Creación de tablas con esquema real (español)
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
-- FUNCIÓN: is_admin()
-- =====================================================
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

-- =====================================================
-- FUNCIÓN: get_user_role()
-- =====================================================
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

-- =====================================================
-- FUNCIÓN: generar token QR
-- =====================================================
CREATE OR REPLACE FUNCTION public.generate_qr_token()
RETURNS VARCHAR AS $$
BEGIN
    RETURN 'resv:' || encode(gen_random_bytes(16), 'hex');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
