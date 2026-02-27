-- =====================================================
-- DATOS DE PRUEBA - GYM SENA
-- Fecha: 2025-12-18
-- Descripción: Datos iniciales para testing
-- =====================================================

-- NOTA: Los usuarios deben ser creados primero en Supabase Auth
-- Estos son solo los registros complementarios

-- =====================================================
-- DATOS: staff (Personal)
-- =====================================================
INSERT INTO public.staff (full_name, role, email, phone, status) VALUES
    ('Carlos Rodríguez', 'Instructor Principal', 'carlos.rodriguez@gymsena.com', '+57 300 1234567', 'active'),
    ('María González', 'Entrenadora Personal', 'maria.gonzalez@gymsena.com', '+57 301 2345678', 'active'),
    ('Juan Pérez', 'Recepcionista', 'juan.perez@gymsena.com', '+57 302 3456789', 'active'),
    ('Ana Martínez', 'Nutricionista', 'ana.martinez@gymsena.com', '+57 303 4567890', 'active'),
    ('Pedro Sánchez', 'Instructor de Yoga', 'pedro.sanchez@gymsena.com', '+57 304 5678901', 'active');

-- =====================================================
-- DATOS: equipment (Equipamiento)
-- =====================================================
INSERT INTO public.equipment (name, status) VALUES
    ('Cinta de Correr 1', 'ok'),
    ('Cinta de Correr 2', 'ok'),
    ('Bicicleta Estática 1', 'ok'),
    ('Bicicleta Estática 2', 'maintenance'),
    ('Elíptica 1', 'ok'),
    ('Banco de Pesas 1', 'ok'),
    ('Banco de Pesas 2', 'ok'),
    ('Rack de Sentadillas', 'ok'),
    ('Máquina de Remo', 'ok'),
    ('Set de Mancuernas', 'ok'),
    ('Banco Multipower', 'ok'),
    ('Máquina de Prensa', 'ok'),
    ('Colchonetas (10 unidades)', 'ok'),
    ('Balones Medicinales', 'ok'),
    ('Bandas Elásticas', 'ok');

-- =====================================================
-- DATOS: slots (Horarios) - Solo Lunes a Viernes
-- =====================================================
-- Lunes a Viernes: 6:00-8:00, 8:00-10:00, 10:00-12:00, 14:00-16:00, 16:00-18:00, 18:00-20:00

DO $$
DECLARE
    start_date DATE := CURRENT_DATE;
    day_count INTEGER;
    day_of_week INTEGER;
BEGIN
    FOR day_count IN 0..6 LOOP
        day_of_week := EXTRACT(DOW FROM start_date + day_count);
        
        -- Solo Lunes a Viernes (1-5)
        IF day_of_week BETWEEN 1 AND 5 THEN
            INSERT INTO public.slots (date, start_time, end_time, capacity, reserved_count) VALUES
                (start_date + day_count, '06:00', '08:00', 25, 0),
                (start_date + day_count, '08:00', '10:00', 25, 0),
                (start_date + day_count, '10:00', '12:00', 20, 0),
                (start_date + day_count, '14:00', '16:00', 20, 0),
                (start_date + day_count, '16:00', '18:00', 25, 0),
                (start_date + day_count, '18:00', '20:00', 30, 0);
        END IF;
    END LOOP;
END $$;

-- =====================================================
-- FUNCIÓN: Generar QR Token único
-- =====================================================
CREATE OR REPLACE FUNCTION generate_qr_token()
RETURNS VARCHAR AS $$
BEGIN
    RETURN 'QR-' || UPPER(SUBSTR(MD5(RANDOM()::TEXT), 1, 16));
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- COMENTARIOS
-- =====================================================
COMMENT ON TABLE public.users IS 'Usuarios del sistema (miembros, admins, instructores)';
COMMENT ON TABLE public.weight_logs IS 'Registro histórico de peso de usuarios';
COMMENT ON TABLE public.slots IS 'Horarios disponibles para reservar';
COMMENT ON TABLE public.reservations IS 'Reservas de usuarios';
COMMENT ON TABLE public.staff IS 'Personal del gimnasio';
COMMENT ON TABLE public.equipment IS 'Equipamiento del gimnasio';
COMMENT ON TABLE public.notifications IS 'Notificaciones del sistema';
COMMENT ON TABLE public.support_tickets IS 'Tickets de soporte técnico';
