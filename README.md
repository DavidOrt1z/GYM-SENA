# 🏋️ SISTEMA DE GESTIÓN DE GIMNASIO - JACEK GYM

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
- 🎫 Validación de QR para reservas

---

## 🚀 Tecnologías

| Componente | Tecnología |
|------------|------------|
| **Backend** | Supabase (PostgreSQL, Auth, Storage) |
| **App Móvil** | Flutter (Android/iOS) |
| **Panel Web** | HTML5, CSS3, JavaScript (Vanilla) + Node.js/Express |
| **Autenticación** | Supabase Auth |
| **Base de Datos** | PostgreSQL con RLS |
| **Almacenamiento** | Supabase Storage |
| **Real-time** | Supabase Realtime |

---

## 📁 Estructura del Proyecto

```
JACEK GYM/
├── 📁 docs/                           # Documentación completa
│
├── 📁 supabase/                       # Backend Supabase
│   ├── migrations/                    # Migraciones SQL
│   ├── seed/                          # Datos de prueba
│   └── config.toml
│
├── 📁 gym_app/                        # App Flutter
│   ├── lib/
│   │   ├── models/                    # Modelos de datos
│   │   ├── services/                  # Servicios (Supabase)
│   │   ├── providers/                 # Gestión de estado
│   │   ├── screens/                   # Pantallas UI
│   │   ├── widgets/                   # Componentes reutilizables
│   │   └── utils/                     # Utilidades
│   └── assets/
│
├── 📁 admin-panel/                    # Panel Web Admin
│   ├── css/                           # Estilos
│   ├── js/                            # Lógica JavaScript
│   ├── assets/                        # Recursos web
│   ├── server.js                      # Backend Node.js
│   ├── login.html
│   ├── dashboard.html
│   └── ...
│
└── README.md
```

---

## 🛠️ Instalación y Configuración

### Prerrequisitos

- **Flutter SDK** >= 3.0.0
- **Node.js** >= 18.x
- **npm** >= 9.x

### Panel Admin (Web)

```bash
cd admin-panel
npm install
```

Crear `.env` en `admin-panel/`:

```env
SUPABASE_URL=TU_SUPABASE_URL
SUPABASE_ANON_KEY=TU_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=TU_SUPABASE_SERVICE_ROLE_KEY
ADMIN_PANEL_PORT=5500
```

Iniciar:

```bash
npm start
```

Acceder a: `http://localhost:5500`

### App Flutter

```bash
cd gym_app
cp .env.example .env
flutter pub get
flutter run
```

---

## 🔐 Seguridad

- **No subir `.env`** al repositorio
- Las credenciales se sirven desde `/api/config` del backend
- Row Level Security (RLS) activo en todas las tablas
- Políticas RLS por rol (admin/member/instructor)

---

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

---

## 📄 Licencia

Proyecto formativo SENA - Servicio Nacional de Aprendizaje

---

**🏋️ JACEK GYM - Sistema de Gestión Integral para Gimnasios**

*Última actualización: Mayo 2026*
