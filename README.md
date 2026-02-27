# 🏋️ SISTEMA DE GESTIÓN DE GIMNASIO - GYM SENA

Sistema completo de gestión para gimnasios que incluye una aplicación móvil Flutter para usuarios y un panel web de administración, con backend en Supabase (PostgreSQL).

---

## 📋 Características Principales

### 📱 App Móvil (Flutter)
- ✅ Autenticación de usuarios (registro, login, recuperación)
- 📅 Sistema de reservas de horarios
- 📊 Seguimiento de progreso (peso, medidas)
- 👤 Perfil de usuario personalizado
- 🎫 Generación de códigos QR para acceso
- 🔔 Notificaciones
- 🌙 Temas claro/oscuro
- 🌐 Multiidioma (ES/EN)

### 🖥️ Panel Administrador (Web)
- 📊 Dashboard con métricas en tiempo real
- 👥 Gestión de usuarios y roles
- 📅 Gestión de horarios y reservas
- 👨‍💼 Gestión de personal
- 🔧 Control de equipamiento
- 📈 Reportes y análisis
- 💬 Sistema de soporte
- 🔔 Envío de notificaciones

---

## 🚀 Tecnologías

| Componente | Tecnología |
|------------|------------|
| **Backend** | Supabase (PostgreSQL, Auth, Storage) |
| **App Móvil** | Flutter (Android/iOS) |
| **Panel Web** | HTML5, CSS3, JavaScript (Vanilla) |
| **Autenticación** | Supabase Auth |
| **Base de Datos** | PostgreSQL con RLS |
| **Almacenamiento** | Supabase Storage |
| **Real-time** | Supabase Realtime |

---

## 📁 Estructura del Proyecto

```
GYM SENA/
├── 📁 docs/                           # Documentación completa
│   ├── PROYECTO_GYM_SENA.md          # Plan de fases detallado
│   └── ...
│
├── 📁 supabase/                       # Backend Supabase
│   ├── migrations/                    # Migraciones SQL
│   │   ├── 20251218000001_initial_schema.sql
│   │   └── 20251218000002_rls_policies.sql
│   ├── functions/                     # Edge Functions (futuro)
│   ├── seed/                          # Datos de prueba
│   │   └── test_data.sql
│   ├── config.toml                    # Configuración local
│   ├── .env.example                   # Ejemplo de variables
│   └── README.md                      # Guía de Supabase
│
├── 📁 gym_app/                        # App Flutter
│   ├── lib/
│   │   ├── models/                    # Modelos de datos
│   │   ├── services/                  # Servicios (Supabase)
│   │   ├── providers/                 # Gestión de estado
│   │   ├── screens/                   # Pantallas UI
│   │   │   ├── auth/                  # Login, Registro
│   │   │   ├── home/                  # Pantalla principal
│   │   │   ├── reservations/          # Reservas
│   │   │   ├── progress/              # Progreso personal
│   │   │   ├── profile/               # Perfil usuario
│   │   │   └── settings/              # Configuración
│   │   ├── widgets/                   # Componentes reutilizables
│   │   └── utils/                     # Utilidades
│   ├── assets/                        # Recursos (imágenes, iconos)
│   ├── pubspec.yaml                   # Dependencias Flutter
│   └── .env                           # Variables de entorno
│
├── 📁 admin-panel/                    # Panel Web Admin
│   ├── css/                           # Estilos
│   ├── js/                            # Lógica JavaScript
│   │   ├── config.js                  # Config Supabase
│   │   ├── auth.js                    # Autenticación
│   │   ├── dashboard.js               # Dashboard
│   │   └── ...
│   ├── assets/                        # Recursos web
│   ├── login.html                     # Página de login
│   ├── index.html                     # Dashboard principal
│   └── ...
│
├── .gitignore                         # Archivos ignorados
└── README.md                          # Este archivo
```

---

## 🛠️ Instalación y Configuración

### Prerrequisitos

- **Flutter SDK** >= 3.0.0
- **Node.js** >= 16.x
- **Supabase CLI** (para desarrollo local)
- **Docker** (opcional, para Supabase local)
- **Git**

### 1. Clonar el Repositorio

```bash
git clone https://github.com/tu-usuario/gym-sena.git
cd gym-sena
```

### 2. Configurar Supabase

#### Opción A: Supabase Cloud (Recomendado)

1. Crear cuenta en [supabase.com](https://supabase.com)
2. Crear nuevo proyecto "gym-sena"
3. Copiar credenciales (URL, anon key, service key)
4. Aplicar migraciones:

```bash
cd supabase
supabase login
supabase link --project-ref tu-project-id
supabase db push
```

#### Opción B: Supabase Local

```bash
# Asegúrate de tener Docker ejecutándose
cd supabase
supabase start
```

**Ver guía completa:** [supabase/README.md](supabase/README.md)

### 3. Configurar App Flutter

```bash
cd gym_app

# Copiar archivo de variables de entorno
cp .env.example .env

# Editar .env con tus credenciales de Supabase
# SUPABASE_URL=tu-url
# SUPABASE_ANON_KEY=tu-anon-key

# Instalar dependencias
flutter pub get

# Ejecutar en emulador/dispositivo
flutter run
```

### 4. Configurar Panel Admin

```bash
cd admin-panel

# Editar js/config.js con tus credenciales de Supabase
# Abrir index.html en un navegador o usar un servidor local

# Opción 1: Servidor simple con Python
python -m http.server 8000

# Opción 2: Servidor con Node.js
npx http-server -p 8000
```

Acceder a: `http://localhost:8000`

---

## 📊 Base de Datos

### Tablas Principales

| Tabla | Descripción | Relaciones |
|-------|-------------|------------|
| `users` | Usuarios del sistema | → weight_logs, reservations |
| `weight_logs` | Registro de peso | ← users |
| `slots` | Horarios disponibles | → reservations |
| `reservations` | Reservas de usuarios | ← users, slots |
| `staff` | Personal del gimnasio | - |
| `equipment` | Equipamiento | - |
| `notifications` | Notificaciones | ← users (opcional) |
| `support_tickets` | Tickets de soporte | ← users |

### Seguridad: Row Level Security (RLS)

Todas las tablas tienen políticas RLS activas que garantizan:
- Los usuarios solo acceden a sus propios datos
- Los admins tienen acceso completo
- Las operaciones están auditadas
- Los datos están protegidos a nivel de base de datos

---

## 👥 Roles del Sistema

| Rol | Acceso App | Acceso Panel | Permisos |
|-----|-----------|--------------|----------|
| **member** | ✅ Completo | ❌ No | Reservas, perfil, progreso |
| **instructor** | ✅ Completo | ⚠️ Limitado | Ver reservas, gestionar clases |
| **administrative** | ✅ Completo | ⚠️ Limitado | Ver reportes básicos |
| **admin** | ✅ Completo | ✅ Completo | Gestión total del sistema |

---

## 🚦 Estado del Proyecto

### Fase 1: Infraestructura Supabase ✅ 30%
- [x] Instalación de Supabase CLI
- [x] Migraciones de base de datos creadas
- [x] Políticas RLS implementadas
- [x] Scripts de datos de prueba
- [ ] Proyecto en la nube configurado
- [ ] Datos de prueba cargados

### Fase 2: App Móvil - Autenticación ⏳ 0%
- [ ] Proyecto Flutter creado
- [ ] Supabase SDK integrado
- [ ] Pantallas de autenticación
- [ ] Gestión de estado con Provider
- [ ] Perfil de usuario

### Fase 3: Panel Admin - Base ⏳ 0%
- [ ] Estructura HTML/CSS/JS
- [ ] Dashboard principal
- [ ] Sistema de autenticación
- [ ] Métricas en tiempo real

### Fase 4: Sistema de Reservas ⏳ 0%
- [ ] App: Ver y reservar horarios
- [ ] App: Mis reservas con QR
- [ ] Admin: Gestión de slots
- [ ] Admin: Gestión de reservas

### Fase 5: Progreso y Gestión ⏳ 0%
- [ ] App: Seguimiento de peso
- [ ] Admin: Gestión de usuarios
- [ ] Admin: Gestión de personal
- [ ] Exportación de datos

### Fase 6: Configuraciones y Pulido ⏳ 0%
- [ ] Configuraciones de la app
- [ ] Sistema de notificaciones
- [ ] Reportes y análisis
- [ ] Testing completo

**Ver plan detallado:** [docs/PROYECTO_GYM_SENA.md](docs/PROYECTO_GYM_SENA.md)

---

## 📱 Capturas de Pantalla

_Próximamente..._

---

## 🧪 Testing

```bash
# Tests Flutter
cd gym_app
flutter test

# Tests de integración
flutter drive --target=test_driver/app.dart
```

---

## 🚀 Despliegue

### App Móvil

**Android:**
```bash
flutter build apk --release
# APK en: build/app/outputs/flutter-apk/app-release.apk
```

**iOS:**
```bash
flutter build ios --release
# Requiere certificado de Apple Developer
```

### Panel Web

Desplegar en cualquier hosting estático:
- Vercel
- Netlify
- GitHub Pages
- Supabase Hosting (futuro)

---

## 📚 Documentación Adicional

- [Plan de Fases](docs/PROYECTO_GYM_SENA.md) - Plan detallado de desarrollo
- [Guía Supabase](supabase/README.md) - Configuración completa de Supabase
- [Manual de Usuario](docs/MANUAL_USUARIO.md) - Guía para usuarios finales (futuro)
- [Manual de Admin](docs/MANUAL_ADMIN.md) - Guía para administradores (futuro)

---

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

---

## 📄 Licencia

Este proyecto es parte del programa SENA y está bajo licencia educativa.

---

## 👨‍💻 Autor

Desarrollado como proyecto formativo para el SENA - Servicio Nacional de Aprendizaje

---

## 📞 Soporte

Para preguntas o problemas:
- Revisar la [documentación](docs/)
- Consultar [Supabase Docs](https://supabase.com/docs)
- Consultar [Flutter Docs](https://docs.flutter.dev)

---

**🏋️ GYM SENA - Sistema de Gestión Integral para Gimnasios**

*Última actualización: 18 de Diciembre de 2025*
