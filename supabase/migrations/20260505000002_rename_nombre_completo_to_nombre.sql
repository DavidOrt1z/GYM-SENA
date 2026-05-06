-- =====================================================
-- MIGRACIÓN: Renombrar nombre_completo a nombre
-- Fecha: 2026-05-05
-- Descripción: Renombra full_name a nombre para separar nombre y apellido
-- =====================================================

-- Renombrar columna nombre_completo a nombre
ALTER TABLE public.users 
RENAME COLUMN nombre_completo TO nombre;

-- Actualizar comentario
COMMENT ON COLUMN public.users.nombre IS 'Nombre del usuario (sin apellido)';
