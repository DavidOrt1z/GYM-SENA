-- =====================================================
-- ENFORCE: 1 reserva por usuario por dia (no cancelada)
-- Fecha: 2026-04-14
-- =====================================================

CREATE OR REPLACE FUNCTION public.enforce_one_reservation_per_user_per_day()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_slot_date date;
  v_conflict_exists boolean;
BEGIN
  IF NEW.estado IS NULL THEN
    NEW.estado := 'active';
  END IF;

  IF NEW.estado = 'cancelled' THEN
    RETURN NEW;
  END IF;

  SELECT fh.fecha
    INTO v_slot_date
  FROM public.franjas_horarias fh
  WHERE fh.id = NEW.id_franja_horaria;

  IF v_slot_date IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM public.reservas r
    JOIN public.franjas_horarias fh ON fh.id = r.id_franja_horaria
    WHERE r.id_usuario = NEW.id_usuario
      AND r.estado <> 'cancelled'
      AND fh.fecha = v_slot_date
      AND (TG_OP = 'INSERT' OR r.id <> NEW.id)
  ) INTO v_conflict_exists;

  IF v_conflict_exists THEN
    RAISE EXCEPTION USING
      MESSAGE = 'Solo puedes reservar una vez por dia',
      ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_one_reservation_per_user_per_day ON public.reservas;

CREATE TRIGGER trg_enforce_one_reservation_per_user_per_day
BEFORE INSERT OR UPDATE OF id_usuario, id_franja_horaria, estado
ON public.reservas
FOR EACH ROW
EXECUTE FUNCTION public.enforce_one_reservation_per_user_per_day();
