-- ==================== NOTIFICACIONES MIGRATION ====================
-- Agregar soporte para notificaciones push en Supabase
-- Fecha: 24 Febrero 2026

-- 1. Agregar columna fcm_token a tabla users
ALTER TABLE "public"."users" 
ADD COLUMN IF NOT EXISTS fcm_token TEXT,
ADD COLUMN IF NOT EXISTS notificaciones_habilitadas BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS ultima_notificacion TIMESTAMP WITH TIME ZONE;

-- Crear índice para consultas rápidas de tokens
CREATE INDEX IF NOT EXISTS idx_users_fcm_token ON "public"."users"(fcm_token);
CREATE INDEX IF NOT EXISTS idx_users_notificaciones_habilitadas ON "public"."users"(notificaciones_habilitadas);

-- 2. Crear tabla de historial de notificaciones
CREATE TABLE IF NOT EXISTS "public"."notificaciones_historial" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES "public"."users"(id) ON DELETE CASCADE,
    titulo TEXT NOT NULL,
    cuerpo TEXT NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    datos JSONB DEFAULT '{}'::jsonb,
    entregada BOOLEAN DEFAULT FALSE,
    abierta BOOLEAN DEFAULT FALSE,
    fecha_apertura TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para historial de notificaciones
CREATE INDEX IF NOT EXISTS idx_notif_usuario_id ON "public"."notificaciones_historial"(usuario_id);
CREATE INDEX IF NOT EXISTS idx_notif_tipo ON "public"."notificaciones_historial"(tipo);
CREATE INDEX IF NOT EXISTS idx_notif_created_at ON "public"."notificaciones_historial"(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notif_entregada ON "public"."notificaciones_historial"(entregada);

-- 3. Crear tabla de suscripciones a topics
CREATE TABLE IF NOT EXISTS "public"."notif_suscripciones_topic" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES "public"."users"(id) ON DELETE CASCADE,
    topic VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(usuario_id, topic)
);

-- Índices para suscripciones
CREATE INDEX IF NOT EXISTS idx_topic_suscr_usuario ON "public"."notif_suscripciones_topic"(usuario_id);
CREATE INDEX IF NOT EXISTS idx_topic_suscr_topic ON "public"."notif_suscripciones_topic"(topic);

-- 4. Crear tabla de configuración de notificaciones por usuario
CREATE TABLE IF NOT EXISTS "public"."notif_configuracion" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL UNIQUE REFERENCES "public"."users"(id) ON DELETE CASCADE,
    reservas BOOLEAN DEFAULT TRUE,
    recordatorios BOOLEAN DEFAULT TRUE,
    equipamiento BOOLEAN DEFAULT TRUE,
    cambios_horario BOOLEAN DEFAULT TRUE,
    marketing BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice para configuración
CREATE INDEX IF NOT EXISTS idx_config_usuario_id ON "public"."notif_configuracion"(usuario_id);

-- 5. Habilitar RLS en nuevas tablas
ALTER TABLE "public"."notificaciones_historial" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."notif_suscripciones_topic" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."notif_configuracion" ENABLE ROW LEVEL SECURITY;

-- 6. Crear políticas RLS para historial
CREATE POLICY "Usuarios ven su propio historial"
ON "public"."notificaciones_historial"
FOR SELECT
USING (auth.uid() = usuario_id OR is_admin());

CREATE POLICY "Sistema puede insertar historial"
ON "public"."notificaciones_historial"
FOR INSERT
WITH CHECK (TRUE);

CREATE POLICY "Usuarios actualizan su historial"
ON "public"."notificaciones_historial"
FOR UPDATE
USING (auth.uid() = usuario_id OR is_admin())
WITH CHECK (auth.uid() = usuario_id OR is_admin());

-- 7. Crear políticas RLS para suscripciones
CREATE POLICY "Usuarios ven sus suscripciones"
ON "public"."notif_suscripciones_topic"
FOR SELECT
USING (auth.uid() = usuario_id OR is_admin());

CREATE POLICY "Usuarios pueden suscribirse"
ON "public"."notif_suscripciones_topic"
FOR INSERT
WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "Usuarios pueden desuscribirse"
ON "public"."notif_suscripciones_topic"
FOR DELETE
USING (auth.uid() = usuario_id);

-- 8. Crear políticas RLS para configuración
CREATE POLICY "Usuarios ven su configuración"
ON "public"."notif_configuracion"
FOR SELECT
USING (auth.uid() = usuario_id OR is_admin());

CREATE POLICY "Usuarios actualizan su configuración"
ON "public"."notif_configuracion"
FOR UPDATE
USING (auth.uid() = usuario_id);

CREATE POLICY "Usuarios crean su configuración"
ON "public"."notif_configuracion"
FOR INSERT
WITH CHECK (auth.uid() = usuario_id);

-- 9. Crear trigger para actualizar updated_at en usuarios
CREATE OR REPLACE FUNCTION actualizar_timestamp_usuarios()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_timestamp_usuarios
BEFORE UPDATE ON "public"."users"
FOR EACH ROW
EXECUTE FUNCTION actualizar_timestamp_usuarios();

-- 10. Crear función para obtener estadísticas de notificaciones
CREATE OR REPLACE FUNCTION obtener_estadisticas_notificaciones()
RETURNS TABLE (
    total_enviadas BIGINT,
    hoy BIGINT,
    entregadas BIGINT,
    fallidas BIGINT
) AS $$
BEGIN
    RETURN QUERY SELECT
        COUNT(*)::BIGINT as total_enviadas,
        COUNT(*) FILTER (WHERE DATE(created_at) = CURRENT_DATE)::BIGINT as hoy,
        COUNT(*) FILTER (WHERE entregada = TRUE)::BIGINT as entregadas,
        COUNT(*) FILTER (WHERE entregada = FALSE)::BIGINT as fallidas
    FROM "public"."notificaciones_historial";
END;
$$ LANGUAGE plpgsql;

-- Conceder permisos a usuarios autenticados
GRANT USAGE ON SCHEMA public TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON "public"."notificaciones_historial" TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON "public"."notif_suscripciones_topic" TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE ON "public"."notif_configuracion" TO authenticated, anon;
