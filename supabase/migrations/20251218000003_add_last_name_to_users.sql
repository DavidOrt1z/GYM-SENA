-- =====================================================
-- MIGRACIÓN - AGREGAR COLUMNA LAST_NAME A USERS
-- Fecha: 2025-01-03
-- Descripción: Añade el campo last_name para separar nombres y apellidos
-- =====================================================

-- Agregar columna last_name si no existe
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS last_name VARCHAR(255);

-- Agregar columna avatar_url si no existe
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Actualizar updated_at
ALTER TABLE public.users 
ALTER COLUMN updated_at SET DEFAULT NOW();
