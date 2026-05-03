# 🚀 Configuración de Supabase - JACEK GYM

## 📁 Estructura de Archivos

```
supabase/
├── migrations/              # Migraciones de base de datos
│   ├── 20251218000001_initial_schema.sql
│   └── 20251218000002_rls_policies.sql
├── functions/              # Edge Functions (futuro)
├── seed/                   # Datos de prueba
│   └── test_data.sql
├── config.toml            # Configuración local
├── .env.example          # Ejemplo de variables de entorno
└── README.md            # Este archivo
```

---

## 🔧 Instalación y Configuración

### 1. Instalar Supabase CLI

**Windows (PowerShell):**
```powershell
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

**macOS/Linux:**
```bash
brew install supabase/tap/supabase
```

**npm (Todas las plataformas):**
```bash
npm install -g supabase
```

### 2. Verificar Instalación
```bash
supabase --version
```

---

## 🌐 Opción 1: Usar Supabase Cloud (Recomendado para Producción)

### Paso 1: Crear Proyecto en Supabase Cloud

1. Ve a [https://supabase.com](https://supabase.com)
2. Haz clic en "Start your project"
3. Crea una cuenta o inicia sesión
4. Clic en "New Project"
5. Completa los datos:
   - **Name:** JACEK GYM
   - **Database Password:** (Guarda esta contraseña de forma segura)
   - **Region:** South America (São Paulo) - `sa-east-1`
6. Espera 2-3 minutos mientras se crea el proyecto

### Paso 2: Obtener Credenciales

1. En el dashboard de tu proyecto, ve a **Settings** → **API**
2. Copia los siguientes valores:
   - **Project URL** (ej: `https://abcdefgh.supabase.co`)
   - **anon/public key**
   - **service_role key** (¡NUNCA expongas esta clave en el cliente!)

### Paso 3: Configurar Variables de Entorno

1. Copia el archivo `.env.example` a `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edita `.env` con tus credenciales:
   ```env
   SUPABASE_URL=https://tu-proyecto.supabase.co
   SUPABASE_ANON_KEY=tu-anon-key-aqui
   SUPABASE_SERVICE_ROLE_KEY=tu-service-role-key-aqui
   ```

### Paso 4: Ejecutar Migraciones

```bash
# Iniciar sesión en Supabase
supabase login

# Vincular proyecto local con el proyecto en la nube
supabase link --project-ref tu-project-id

# Ejecutar migraciones
supabase db push
```

### Paso 5: Cargar Datos de Prueba

```bash
# Ejecutar desde la raíz del proyecto
supabase db reset --db-url "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"
```

O manualmente desde el SQL Editor en Supabase Dashboard:
1. Ve a **SQL Editor**
2. Copia y pega el contenido de `seed/test_data.sql`
3. Ejecuta

---

## 💻 Opción 2: Desarrollo Local con Supabase

### Requisitos Previos
- Docker Desktop instalado y ejecutándose
- Supabase CLI instalado

### Paso 1: Iniciar Supabase Local

```bash
# Desde la carpeta raíz del proyecto
cd "d:\Documentos\JACEK GYM"

# Iniciar Supabase localmente
supabase start
```

**Esto iniciará:**
- PostgreSQL Database en `postgresql://postgres:postgres@localhost:54322/postgres`
- API Gateway en `http://localhost:54321`
- Studio (UI) en `http://localhost:54323`
- Inbucket (Email testing) en `http://localhost:54324`

### Paso 2: Acceder a Supabase Studio

Abre tu navegador en: `http://localhost:54323`

**Credenciales locales:**
- Studio URL: `http://localhost:54323`
- API URL: `http://localhost:54321`
- Database: `postgresql://postgres:postgres@localhost:54322/postgres`

### Paso 3: Aplicar Migraciones

Las migraciones se aplican automáticamente al iniciar. Si necesitas reaplicarlas:

```bash
supabase db reset
```

### Paso 4: Detener Supabase Local

```bash
supabase stop
```

---

## 📊 Estructura de Base de Datos

### Tablas Principales

| Tabla | Descripción |
|-------|-------------|
| `users` | Usuarios del sistema (miembros, admins, instructores) |
| `weight_logs` | Registro histórico de peso |
| `slots` | Horarios disponibles para reservar |
| `reservations` | Reservas de usuarios |
| `staff` | Personal del gimnasio |
| `equipment` | Equipamiento del gimnasio |
| `notifications` | Notificaciones del sistema |
| `support_tickets` | Tickets de soporte |

### Diagrama de Relaciones

```
auth.users (Supabase Auth)
    ↓
users (Perfil)
    ├── weight_logs (1:N)
    ├── reservations (1:N)
    ├── notifications (1:N - si es específica)
    └── support_tickets (1:N)

slots
    └── reservations (1:N)
```

---

## 🔒 Seguridad: Row Level Security (RLS)

Todas las tablas tienen RLS activado. Las políticas principales son:

### Usuarios (users)
- ✅ Cualquier usuario autenticado puede ver todos los usuarios
- ✅ Los usuarios pueden actualizar su propio perfil
- ✅ Solo admins pueden eliminar usuarios

### Reservas (reservations)
- ✅ Los usuarios solo ven sus propias reservas
- ✅ Los usuarios pueden crear reservas
- ✅ Los usuarios solo pueden cancelar sus propias reservas
- ✅ Admins ven y gestionan todas las reservas

### Horarios (slots)
- ✅ Todos los autenticados pueden ver horarios
- ✅ Solo admins pueden crear/editar/eliminar horarios

---

## 🛠️ Comandos Útiles

### Gestión Local

```bash
# Iniciar Supabase local
supabase start

# Detener Supabase local
supabase stop

# Ver status
supabase status

# Reset database (¡borra todos los datos!)
supabase db reset

# Ver logs
supabase logs
```

### Migraciones

```bash
# Crear nueva migración
supabase migration new nombre_migracion

# Aplicar migraciones
supabase db push

# Ver estado de migraciones
supabase migration list
```

### Base de Datos

```bash
# Conectar a la base de datos local
supabase db connect

# Ejecutar SQL desde archivo
psql -h localhost -p 54322 -U postgres -d postgres -f migrations/file.sql

# Backup de la base de datos
supabase db dump -f backup.sql
```

---

## 📱 Integración con Flutter

### 1. Agregar dependencias en `pubspec.yaml`

```yaml
dependencies:
  supabase_flutter: ^2.0.0
  flutter_dotenv: ^5.1.0
```

### 2. Inicializar Supabase en Flutter

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://tu-proyecto.supabase.co',
    anonKey: 'tu-anon-key',
  );
  
  runApp(MyApp());
}

// Cliente global
final supabase = Supabase.instance.client;
```

### 3. Ejemplo de Uso

```dart
// Autenticación
final response = await supabase.auth.signUp(
  email: 'user@example.com',
  password: 'password123',
);

// Consulta
final data = await supabase
  .from('users')
  .select()
  .eq('role', 'member');

// Inserción
await supabase.from('reservations').insert({
  'user_id': userId,
  'slot_id': slotId,
  'status': 'active',
  'qr_token': 'QR-${DateTime.now().millisecondsSinceEpoch}',
});
```

---

## 🌐 Integración con Web (Panel Admin)

### 1. Instalar Supabase JS

```bash
npm install @supabase/supabase-js
```

### 2. Configurar en JavaScript

```javascript
// config.js
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://tu-proyecto.supabase.co'
const supabaseKey = 'tu-anon-key'

export const supabase = createClient(supabaseUrl, supabaseKey)
```

### 3. Ejemplo de Uso

```javascript
// Autenticación
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'admin@jacekgym.com',
  password: 'admin123'
})

// Consulta en tiempo real
supabase
  .channel('reservations')
  .on('postgres_changes', 
    { event: '*', schema: 'public', table: 'reservations' },
    (payload) => console.log('Change received!', payload)
  )
  .subscribe()
```

---

## 🐛 Troubleshooting

### Error: Docker no está ejecutándose
```bash
# Inicia Docker Desktop primero
# Luego ejecuta: supabase start
```

### Error: Puerto ya en uso
```bash
# Detén Supabase
supabase stop

# Verifica puertos
netstat -ano | findstr "54321"

# Inicia nuevamente
supabase start
```

### Error: Migraciones no se aplican
```bash
# Reset completo
supabase db reset

# O aplica manualmente
supabase db push
```

---

## 📚 Recursos

- [Documentación Oficial Supabase](https://supabase.com/docs)
- [Supabase CLI Reference](https://supabase.com/docs/reference/cli/introduction)
- [Supabase Flutter SDK](https://supabase.com/docs/reference/dart/introduction)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [Realtime Subscriptions](https://supabase.com/docs/guides/realtime)

---

## 🎯 Próximos Pasos

1. ✅ Instalar Supabase CLI
2. ✅ Crear proyecto en Supabase Cloud
3. ✅ Configurar variables de entorno
4. ✅ Aplicar migraciones
5. ✅ Cargar datos de prueba
6. ⏳ Integrar con Flutter App
7. ⏳ Integrar con Panel Admin Web

---

**¿Preguntas o problemas?** Consulta la documentación oficial o revisa los logs con `supabase logs`
