-- =====================================================
-- MIGRACION: Asegurar lectura de reservas para panel admin (anon)
-- Fecha: 2026-04-10
-- =====================================================

GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT ON TABLE public.reservas TO anon;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'reservas'
      AND policyname = 'Admin panel can read all reservations'
  ) THEN
    CREATE POLICY "Admin panel can read all reservations"
      ON public.reservas FOR SELECT
      TO anon
      USING (true);
  END IF;
END
$$;
