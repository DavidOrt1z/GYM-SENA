-- =====================================================
-- MIGRACION: Corregir vinculo users <-> auth y RLS en esquema espanol
-- Fecha: 2026-04-07
-- =====================================================

-- Backfill de vinculo entre auth.users y public.users por correo
UPDATE public.users u
SET id_autenticacion = au.id,
    fecha_actualizacion = NOW()
FROM auth.users au
WHERE u.id_autenticacion IS NULL
  AND lower(trim(u.correo_electronico)) = lower(trim(au.email));

-- Asegurar unicidad del vinculo con Auth
CREATE UNIQUE INDEX IF NOT EXISTS users_id_autenticacion_unique
  ON public.users (id_autenticacion)
  WHERE id_autenticacion IS NOT NULL;

-- Funciones helper alineadas al esquema en espanol
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.users
    WHERE id_autenticacion = auth.uid()
      AND rol = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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

-- Politicas de users para esquema con id_autenticacion
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  TO authenticated
  USING (id_autenticacion = auth.uid() OR id = auth.uid())
  WITH CHECK (id_autenticacion = auth.uid() OR id = auth.uid());

DROP POLICY IF EXISTS "Allow user creation during signup" ON public.users;
CREATE POLICY "Allow user creation during signup"
  ON public.users FOR INSERT
  TO authenticated
  WITH CHECK (id_autenticacion = auth.uid() OR id = auth.uid());

-- Permitir reclamar perfil preexistente creado por admin (id_autenticacion nulo)
DROP POLICY IF EXISTS "Users can claim profile by email" ON public.users;
CREATE POLICY "Users can claim profile by email"
  ON public.users FOR UPDATE
  TO authenticated
  USING (
    id_autenticacion IS NULL
    AND lower(correo_electronico) = lower(coalesce((auth.jwt() ->> 'email'), ''))
  )
  WITH CHECK (
    id_autenticacion = auth.uid()
    AND lower(correo_electronico) = lower(coalesce((auth.jwt() ->> 'email'), ''))
  );
