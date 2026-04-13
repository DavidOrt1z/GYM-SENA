-- =====================================================
-- MIGRACION: Asegurar columnas de metricas de perfil
-- Fecha: 2026-04-10
-- =====================================================

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS unidades VARCHAR(20) DEFAULT 'metric',
  ADD COLUMN IF NOT EXISTS peso_kg NUMERIC,
  ADD COLUMN IF NOT EXISTS altura_cm NUMERIC;

ALTER TABLE public.users
  ALTER COLUMN unidades SET DEFAULT 'metric';

UPDATE public.users
SET unidades = 'metric'
WHERE unidades IS NULL;
