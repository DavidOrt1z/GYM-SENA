-- Normaliza valores legacy para mantener consistencia en panel admin
UPDATE public.users
SET rol = CASE
  WHEN lower(trim(rol)) IN ('user', 'usuario', 'miembro') THEN 'member'
  WHEN lower(trim(rol)) = 'administrador' THEN 'admin'
  ELSE rol
END
WHERE rol IS NOT NULL;

UPDATE public.users
SET estado = CASE
  WHEN lower(trim(estado)) IN ('activo', 'activa') THEN 'active'
  WHEN lower(trim(estado)) IN ('inactivo', 'inactiva') THEN 'inactive'
  WHEN lower(trim(estado)) = 'suspendido' THEN 'suspended'
  WHEN lower(trim(estado)) = 'bloqueado' THEN 'blocked'
  ELSE estado
END
WHERE estado IS NOT NULL;
