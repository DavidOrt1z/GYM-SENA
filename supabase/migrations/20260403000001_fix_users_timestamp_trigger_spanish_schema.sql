-- =====================================================
-- MIGRACION: Reparar trigger de timestamp en users
-- Fecha: 2026-04-03
-- Descripcion: Compatibilidad con esquema en espanol (fecha_actualizacion)
-- =====================================================

-- Eliminar triggers previos en users para evitar conflictos
DROP TRIGGER IF EXISTS trigger_actualizar_timestamp_usuarios ON public.users;
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;

-- Reemplazar funcion para que soporte ambos esquemas (es/en)
CREATE OR REPLACE FUNCTION public.actualizar_timestamp_usuarios()
RETURNS TRIGGER AS $$
BEGIN
    BEGIN
        NEW.fecha_actualizacion = NOW();
        RETURN NEW;
    EXCEPTION
        WHEN undefined_column THEN
            NULL;
    END;

    BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
    EXCEPTION
        WHEN undefined_column THEN
            RETURN NEW;
    END;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_timestamp_usuarios
BEFORE UPDATE ON public.users
FOR EACH ROW
EXECUTE FUNCTION public.actualizar_timestamp_usuarios();
