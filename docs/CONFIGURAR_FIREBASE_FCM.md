# 📱 Configuración de Notificaciones Push con Supabase

## Arquitectura

Las notificaciones se implementan usando:
- **Supabase Realtime** - Escuchar cambios en tiempo real
- **flutter_local_notifications** - Mostrar notificaciones en el dispositivo
- **Supabase Edge Functions** - Procesar y enviar notificaciones desde el admin

## 🔧 Configuración Requerida

### 1. Habilitar Realtime en Supabase

1. En la consola de Supabase → Proyecto JACEK GYM
2. Ir a **Realtime** → **Publication**
3. Click en tabla `notificaciones_historial`
4. Marcar: `INSERT`, `UPDATE`, `DELETE`
5. Guardar cambios

### 2. Verificar Tablas en BD

Las siguientes tablas deben existir (creadas en migration):
- `notificaciones_historial` - Registro de todas las notificaciones
- `notif_configuracion` - Preferencias del usuario
- `notif_suscripciones_topic` - Suscripciones a tópicos

Si no existen, ejecutar:
```sql
-- Migration: 20260224000001_add_notifications.sql
```

### 3. Permisos en Flutter

**Android (`android/app/src/main/AndroidManifest.xml`):**
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

**iOS (`ios/Runner/Info.plist`):**
```xml
<key>UIUserInterfaceStyle</key>
<string>Dark</string>
```

## 🚀 Uso en la App

### Inicializar notificaciones:

```dart
import 'package:gym_app/services/servicio_notificaciones.dart';

// En main() o cuando usuario inicia sesión
final notificaciones = ServicioNotificaciones();
await notificaciones.inicializar();
```

### Mostrar notificación manual:

```dart
await notificaciones.mostrarNotificacion(
  titulo: 'Reserva Confirmada',
  cuerpo: 'Tu reserva ha sido confirmada para mañana',
  tipo: 'reserva_confirmada',
);
```

### Escuchar notificaciones en tiempo real:

El servicio automáticamente escucha cambios en la tabla `notificaciones_historial` usando Supabase Realtime.

## 💻 Envío desde Panel Admin

### Usar API de notificaciones:

```javascript
// Archivo: admin-panel/js/notificaciones.js

// Enviar a usuario específico
await enviarNotificacionAUsuario(
  'usuario_id_aqui',
  '✅ Reserva Confirmada',
  'Tu reserva ha sido confirmada',
  'reserva_confirmada'
);

// Enviar broadcast a todos
await enviarNotificacionBroadcast(
  ['user1', 'user2', 'user3'],
  '📢 Anuncio Importante',
  'El gimnasio estará cerrado mañana',
  'anuncio'
);

// Enviar a admins
await enviarNotificacionATopic(
  'admins',
  '⚠️ Alerta de Equipamiento',
  'Trotadora #1 necesita mantenimiento',
  'alerta_equipamiento'
);
```

## 📊 Flujo de Notificaciones

```
┌─────────────────────┐
│   Panel Admin       │
│   (JS API)          │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Supabase REST     │
│   API               │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ notificaciones_      │
│ historial (INSERT)  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Supabase Realtime  │
│  (Broadcast)        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Flutter App        │
│  (Escucha cambios)  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Local Notification │
│  (Mostrada)         │
└─────────────────────┘
```

## 🧪 Testing

### Desde consola del navegador:

```javascript
// Insertar notificación de prueba
const { data, error } = await supabase
  .from('notificaciones_historial')
  .insert({
    usuario_id: 'usuario_id_aqui',
    titulo: 'Test',
    cuerpo: 'Esta es una notificación de prueba',
    tipo: 'test',
    entregada: true,
    abierta: false
  });

console.log('Notificación insertada:', data);
```

### Desde Flutter:

```dart
// Dar permiso para notificaciones
await requestNotificationPermission();

// Ver notificaciones del usuario
final notifs = await ServicioNotificaciones()
    .obtenerNotificaciones();
print('Notificaciones: $notifs');
```

## ❓ Solución de Problemas

### La app no recibe notificaciones:
- Verificar que Realtime esté habilitado en Supabase
- Revisar que RLS policies permitan leer `notificaciones_historial`
- Asegurarse que el usuario esté autenticado

### Error "Permission denied" en Realtime:
- Verificar RLS policies en tabla `notificaciones_historial`
- Asegurar que usuario puede hacer SELECT en su propio registro

### Notificaciones no se muestran (UIzándose):
- Verificar permisos en Android/iOS
- Revisar que canales estén creados correctamente
- Comprobar que el dispositivo no tiene notificaciones muteadas

## 📝 Estructura de Datos

### notificaciones_historial:
```sql
{
  id: UUID,
  usuario_id: UUID,
  titulo: TEXT,
  cuerpo: TEXT,
  tipo: VARCHAR(50),  -- reserva_confirmada, recordatorio, alerta, etc
  datos: JSONB,       -- Datos adicionales
  entregada: BOOLEAN,
  abierta: BOOLEAN,
  fecha_apertura: TIMESTAMP,
  created_at: TIMESTAMP,
  updated_at: TIMESTAMP
}
```

### notif_configuracion:
```sql
{
  id: UUID,
  usuario_id: UUID (UNIQUE),
  reservas: BOOLEAN,          -- Notificaciones de reservas
  recordatorios: BOOLEAN,     -- Recordatorios de citas
  equipamiento: BOOLEAN,      -- Alertas de equipamiento
  cambios_horario: BOOLEAN,   -- Cambios de horarios
  marketing: BOOLEAN,         -- Ofertas y promociones
  created_at: TIMESTAMP,
  updated_at: TIMESTAMP
}
```

## 📚 Referencias

- [Supabase Realtime Documentation](https://supabase.com/docs/guides/realtime)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Supabase RLS Policies](https://supabase.com/docs/guides/auth/row-level-security)
- [Android Notifications](https://developer.android.com/develop/ui/views/notifications)
- [iOS Local Notifications](https://developer.apple.com/documentation/usernotifications)

## ✅ Status

- ✅ Supabase Realtime configurado
- ✅ flutter_local_notifications instalado
- ✅ Tablas de notificaciones creadas
- ✅ RLS policies implementadas
- ✅ API de notificaciones en panel admin
- ⏳ Edge Functions para recordatorios automáticos (próximo)

