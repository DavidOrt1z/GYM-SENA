-- =====================================================
-- MIGRACIÓN: Agregar columna cedula a tabla users
-- Fecha: 2026-05-05
-- Descripción: Añade columna cedula con restricción UNIQUE
-- =====================================================

-- Añadir columna cedula si no existe
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'cedula'
    ) THEN
        ALTER TABLE public.users ADD COLUMN cedula VARCHAR(50) UNIQUE;
        CREATE INDEX idx_users_cedula ON public.users(cedula);
        COMMENT ON COLUMN public.users.cedula IS 'Número de cédula de identidad del usuario (único)';
        RAISE NOTICE 'Columna cedula añadida correctamente con restricción UNIQUE';
    ELSE
        -- Si ya existe, asegurarse que tenga la restricción UNIQUE
        BEGIN
            ALTER TABLE public.users ADD CONSTRAINT uk_users_cedula UNIQUE (cedula);
            RAISE NOTICE 'Restricción UNIQUE añadida a cedula';
        EXCEPTION WHEN duplicate_object THEN
            RAISE NOTICE 'Restricción UNIQUE ya existe en cedula';
        END;
    END IF;
END $$;
