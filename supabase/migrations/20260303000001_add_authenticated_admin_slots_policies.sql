-- =====================================================
-- POLÍTICAS RLS PARA ROL AUTHENTICATED (admins)
-- Fecha: 2026-03-03
-- Descripción: Permite a usuarios admin autenticados gestionar
--              horarios (slots) y personal (staff) desde la app Flutter
--              o cualquier cliente que use Supabase Auth.
-- =====================================================

-- ------- TABLA: slots -------
CREATE POLICY "Authenticated admins can insert slots"
    ON public.slots FOR INSERT
    TO authenticated
    WITH CHECK (public.is_admin());

CREATE POLICY "Authenticated admins can update slots"
    ON public.slots FOR UPDATE
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

CREATE POLICY "Authenticated admins can delete slots"
    ON public.slots FOR DELETE
    TO authenticated
    USING (public.is_admin());

-- ------- TABLA: staff -------
CREATE POLICY "Authenticated admins can insert staff"
    ON public.staff FOR INSERT
    TO authenticated
    WITH CHECK (public.is_admin());

CREATE POLICY "Authenticated admins can update staff"
    ON public.staff FOR UPDATE
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

CREATE POLICY "Authenticated admins can delete staff"
    ON public.staff FOR DELETE
    TO authenticated
    USING (public.is_admin());
