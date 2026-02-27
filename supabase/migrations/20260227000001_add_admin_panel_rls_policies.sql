-- =====================================================
-- POLÍTICAS ADICIONALES PARA EL PANEL ADMIN
-- Fecha: 2026-02-27
-- Descripción: Permite al panel admin (usando anon key sin sesión Supabase Auth)
--              gestionar usuarios y recursos del gimnasio.
--              El panel tiene su propio sistema de autenticación.
-- =====================================================

-- ------- TABLA: users -------
-- El panel admin necesita leer, crear, actualizar y eliminar usuarios

CREATE POLICY "Admin panel can read all users"
    ON public.users FOR SELECT
    TO anon
    USING (true);

CREATE POLICY "Admin panel can insert users"
    ON public.users FOR INSERT
    TO anon
    WITH CHECK (true);

CREATE POLICY "Admin panel can update users"
    ON public.users FOR UPDATE
    TO anon
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Admin panel can delete users"
    ON public.users FOR DELETE
    TO anon
    USING (true);

-- ------- TABLA: reservations -------
CREATE POLICY "Admin panel can read all reservations"
    ON public.reservations FOR SELECT
    TO anon
    USING (true);

CREATE POLICY "Admin panel can update reservations"
    ON public.reservations FOR UPDATE
    TO anon
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Admin panel can delete reservations"
    ON public.reservations FOR DELETE
    TO anon
    USING (true);

-- ------- TABLA: slots -------
CREATE POLICY "Admin panel can read all slots"
    ON public.slots FOR SELECT
    TO anon
    USING (true);

CREATE POLICY "Admin panel can manage slots"
    ON public.slots FOR ALL
    TO anon
    USING (true)
    WITH CHECK (true);

-- ------- TABLA: staff -------
CREATE POLICY "Admin panel can read all staff"
    ON public.staff FOR SELECT
    TO anon
    USING (true);

CREATE POLICY "Admin panel can manage staff"
    ON public.staff FOR ALL
    TO anon
    USING (true)
    WITH CHECK (true);
