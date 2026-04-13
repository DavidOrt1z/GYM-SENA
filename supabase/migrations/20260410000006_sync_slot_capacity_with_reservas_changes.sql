CREATE OR REPLACE FUNCTION public.sync_franja_cantidad_reservada_from_reservas()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_slot_id uuid;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_slot_id := OLD.id_franja_horaria;

    UPDATE public.franjas_horarias fh
    SET
      cantidad_reservada = (
        SELECT COUNT(*)::int
        FROM public.reservas r
        WHERE r.id_franja_horaria = v_slot_id
          AND r.estado = 'active'
      ),
      fecha_actualizacion = now()
    WHERE fh.id = v_slot_id;

    RETURN OLD;
  END IF;

  v_slot_id := NEW.id_franja_horaria;

  UPDATE public.franjas_horarias fh
  SET
    cantidad_reservada = (
      SELECT COUNT(*)::int
      FROM public.reservas r
      WHERE r.id_franja_horaria = v_slot_id
        AND r.estado = 'active'
    ),
    fecha_actualizacion = now()
  WHERE fh.id = v_slot_id;

  IF TG_OP = 'UPDATE' AND OLD.id_franja_horaria IS DISTINCT FROM NEW.id_franja_horaria THEN
    UPDATE public.franjas_horarias fh
    SET
      cantidad_reservada = (
        SELECT COUNT(*)::int
        FROM public.reservas r
        WHERE r.id_franja_horaria = OLD.id_franja_horaria
          AND r.estado = 'active'
      ),
      fecha_actualizacion = now()
    WHERE fh.id = OLD.id_franja_horaria;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_franja_cantidad_reservada ON public.reservas;

CREATE TRIGGER trg_sync_franja_cantidad_reservada
AFTER INSERT OR UPDATE OR DELETE ON public.reservas
FOR EACH ROW
EXECUTE FUNCTION public.sync_franja_cantidad_reservada_from_reservas();

-- Backfill inicial para dejar consistentes los contadores actuales
UPDATE public.franjas_horarias fh
SET
  cantidad_reservada = COALESCE(src.total, 0),
  fecha_actualizacion = now()
FROM (
  SELECT id_franja_horaria, COUNT(*)::int AS total
  FROM public.reservas
  WHERE estado = 'active'
  GROUP BY id_franja_horaria
) src
WHERE fh.id = src.id_franja_horaria;

UPDATE public.franjas_horarias fh
SET
  cantidad_reservada = 0,
  fecha_actualizacion = now()
WHERE NOT EXISTS (
  SELECT 1
  FROM public.reservas r
  WHERE r.id_franja_horaria = fh.id
    AND r.estado = 'active'
);
