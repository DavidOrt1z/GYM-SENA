 -- ============================================
-- VALIDACION DE INGRESO POR QR
-- ============================================

-- 1) Añadir columnas faltantes a reservations
ALTER TABLE reservations
ADD COLUMN IF NOT EXISTS checked_in BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS checked_in_at TIMESTAMP;

-- 2) Crear función RPC validar_ingreso_qr
CREATE OR REPLACE FUNCTION validar_ingreso_qr(p_token_qr TEXT)
RETURNS JSON AS $$
DECLARE
  v_reserva RECORD;
  v_ahora TIMESTAMP := NOW();
BEGIN
  -- Buscar reserva por token
  SELECT * INTO v_reserva
  FROM reservations
  WHERE token_qr = p_token_qr;

  -- Validar existencia
  IF NOT FOUND THEN
    RETURN json_build_object('ok', false, 'error', 'QR no válido');
  END IF;

  -- Validar que no esté cancelada
  IF v_reserva.status = 'cancelled' THEN
    RETURN json_build_object('ok', false, 'error', 'Reserva cancelada');
  END IF;

  -- Validar franja horaria (30 min antes y después)
  IF v_ahora < v_reserva.start_time - INTERVAL '30 minutes'
  OR v_ahora > v_reserva.end_time + INTERVAL '30 minutes' THEN
    RETURN json_build_object('ok', false, 'error', 'Fuera del horario permitido');
  END IF;

  -- Validar que no haya sido usado antes
  IF v_reserva.checked_in = TRUE THEN
    RETURN json_build_object('ok', false, 'error', 'QR ya fue usado anteriormente');
  END IF;

  -- Marcar check-in
  UPDATE reservations
  SET checked_in = TRUE,
      checked_in_at = v_ahora,
      status = 'completed'
  WHERE token_qr = p_token_qr;

  RETURN json_build_object(
    'ok', true,
    'mensaje', 'Ingreso registrado correctamente',
    'usuario_id', v_reserva.user_id,
    'reserva_id', v_reserva.id,
    'horario', v_reserva.start_time
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3) Dar permisos de ejecución
GRANT EXECUTE ON FUNCTION validar_ingreso_qr(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION validar_ingreso_qr(TEXT) TO anon;
