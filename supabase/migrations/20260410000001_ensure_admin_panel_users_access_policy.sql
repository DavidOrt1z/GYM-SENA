-- =====================================================
-- MIGRACION: Asegurar acceso de panel admin a public.users
-- Fecha: 2026-04-10
-- =====================================================

GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.users TO anon;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'users'
      AND policyname = 'Admin panel can read all users'
  ) THEN
    CREATE POLICY "Admin panel can read all users"
      ON public.users FOR SELECT
      TO anon
      USING (true);
  END IF;
END
$$;
