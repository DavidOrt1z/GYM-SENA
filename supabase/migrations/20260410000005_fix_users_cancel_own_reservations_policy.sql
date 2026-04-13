DROP POLICY IF EXISTS "Users can cancel own reservations" ON public.reservas;

CREATE POLICY "Users can cancel own reservations"
ON public.reservas
FOR UPDATE
TO public
USING (
  (
    id_usuario IN (
      SELECT u.id
      FROM public.users u
      WHERE u.id_autenticacion = auth.uid()
    )
    OR id_usuario = auth.uid()
    OR is_admin()
  )
)
WITH CHECK (
  (
    (
      id_usuario IN (
        SELECT u.id
        FROM public.users u
        WHERE u.id_autenticacion = auth.uid()
      )
      OR id_usuario = auth.uid()
      OR is_admin()
    )
    AND (is_admin() OR estado = 'cancelled')
  )
);
