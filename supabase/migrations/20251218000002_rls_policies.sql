-- =====================================================
-- ROW LEVEL SECURITY (RLS) - JACEK GYM
-- Fecha: 2025-12-18
-- Descripción: Políticas de seguridad a nivel de fila
-- =====================================================

-- Activar RLS en todas las tablas
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weight_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.users
        WHERE auth_id = auth.uid()
        AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS VARCHAR AS $$
DECLARE
    user_role VARCHAR;
BEGIN
    SELECT role INTO user_role
    FROM public.users
    WHERE auth_id = auth.uid();
    RETURN user_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- POLÍTICAS: users
-- =====================================================
-- Cualquier usuario autenticado puede ver usuarios
CREATE POLICY "Users are viewable by authenticated users"
    ON public.users FOR SELECT
    USING (auth.role() = 'authenticated');

-- Los usuarios pueden actualizar su propio perfil
CREATE POLICY "Users can update own profile"
    ON public.users FOR UPDATE
    USING (auth_id = auth.uid())
    WITH CHECK (auth_id = auth.uid());

-- Los admins pueden insertar, actualizar y eliminar cualquier usuario
CREATE POLICY "Admins can manage all users"
    ON public.users FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- Permitir inserción durante registro
CREATE POLICY "Allow user creation during signup"
    ON public.users FOR INSERT
    WITH CHECK (auth_id = auth.uid());

-- =====================================================
-- POLÍTICAS: weight_logs
-- =====================================================
CREATE POLICY "Users can view own weight logs"
    ON public.weight_logs FOR SELECT
    USING (
        user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid())
        OR public.is_admin()
    );

CREATE POLICY "Users can insert own weight logs"
    ON public.weight_logs FOR INSERT
    WITH CHECK (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can update own weight logs"
    ON public.weight_logs FOR UPDATE
    USING (
        user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid())
        OR public.is_admin()
    );

CREATE POLICY "Users can delete own weight logs"
    ON public.weight_logs FOR DELETE
    USING (
        user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid())
        OR public.is_admin()
    );

-- =====================================================
-- POLÍTICAS: slots
-- =====================================================
CREATE POLICY "Slots are viewable by authenticated users"
    ON public.slots FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can manage slots"
    ON public.slots FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- =====================================================
-- POLÍTICAS: reservations
-- =====================================================
CREATE POLICY "Users can view own reservations"
    ON public.reservations FOR SELECT
    USING (
        user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid())
        OR public.is_admin()
    );

CREATE POLICY "Users can create reservations"
    ON public.reservations FOR INSERT
    WITH CHECK (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can cancel own reservations"
    ON public.reservations FOR UPDATE
    USING (
        (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()) AND status = 'cancelled')
        OR public.is_admin()
    )
    WITH CHECK (
        (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()) AND status = 'cancelled')
        OR public.is_admin()
    );

CREATE POLICY "Admins can delete reservations"
    ON public.reservations FOR DELETE
    USING (public.is_admin());

-- =====================================================
-- POLÍTICAS: staff
-- =====================================================
CREATE POLICY "Staff are viewable by authenticated users"
    ON public.staff FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can manage staff"
    ON public.staff FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- =====================================================
-- POLÍTICAS: equipment
-- =====================================================
CREATE POLICY "Equipment is viewable by authenticated users"
    ON public.equipment FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can manage equipment"
    ON public.equipment FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- =====================================================
-- POLÍTICAS: notifications
-- =====================================================
CREATE POLICY "Users can view notifications"
    ON public.notifications FOR SELECT
    USING (
        target = 'all'
        OR target_user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid())
        OR public.is_admin()
    );

CREATE POLICY "Admins can manage notifications"
    ON public.notifications FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- =====================================================
-- POLÍTICAS: support_tickets
-- =====================================================
CREATE POLICY "Users can view own tickets"
    ON public.support_tickets FOR SELECT
    USING (
        user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid())
        OR public.is_admin()
    );

CREATE POLICY "Users can create tickets"
    ON public.support_tickets FOR INSERT
    WITH CHECK (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

CREATE POLICY "Admins can manage tickets"
    ON public.support_tickets FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());
