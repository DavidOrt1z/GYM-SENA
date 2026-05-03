# 🖼️ CONFIGURAR STORAGE EN SUPABASE PARA FOTOS DE PERFIL

## ✅ Paso 1: Crear Bucket en Supabase

1. **Abre el Dashboard de Supabase**
   - URL: https://supabase.com/

2. **Selecciona tu proyecto (zvcsywnmscnjlxvmtkqb)**

3. **Ve a Storage** (en la barra lateral izquierda)

4. **Click en "New bucket"**
   - Nombre: `avatars`
   - Make it public: ✅ Sí (para poder ver las fotos)
   - Click en "Create bucket"

---

## ✅ Paso 2: Configurar Políticas de Acceso

1. **Ve a Storage → avatars**

2. **Click en las tres líneas (menú) → Policies**

3. **Crear política para lectura (SELECT)**
   - Click en "+ New Policy"
   - Nombre: `Allow public read`
   - Operation: SELECT
   - Target role: Public
   - Expression: `true`
   - Click en "Review" → "Save policy"

4. **Crear política para upload (INSERT)**
   - Click en "+ New Policy"
   - Nombre: `Allow authenticated upload`
   - Operation: INSERT
   - Target role: authenticated
   - Expression: `true`
   - Click en "Review" → "Save policy"

5. **Crear política para update (UPDATE)**
   - Click en "+ New Policy"
   - Nombre: `Allow authenticated update`
   - Operation: UPDATE
   - Target role: authenticated
   - Expression: `true`
   - Click en "Review" → "Save policy"

---

## ✅ Paso 3: Verificar el Código

El código ya tiene:
- ✅ Import de `image_picker`
- ✅ Función `_pickAndUploadPhoto()` que:
  - Abre galería
  - Comprime la imagen
  - Sube a Supabase Storage
  - Obtiene URL pública
  - Guarda URL en la BD
  - Muestra la foto en el avatar

---

## ✅ Paso 4: Instalar Dependencias

```powershell
cd "d:\Documentos\JACEK GYM\gym_app"
flutter pub get
```

---

## ✅ Paso 5: Ejecutar la App

```powershell
flutter run
```

---

## 🧪 Probar Funcionalidad

1. **Login a la app**
2. **Ve a la pantalla Perfil (tab Perfil)**
3. **Mira el avatar**
4. **Click en el botón azul con 📷 (cámara)**
5. **Selecciona una foto de tu galería**
6. **Espera a que suba**
7. **¡La foto debería aparecer en el avatar!**

---

## 🐛 Si da error:

### Error: "Storage bucket not found"
- Verificar que el bucket `avatars` existe en Supabase
- Verificar que está en minúsculas

### Error: "Permission denied"
- Verificar que las políticas de acceso están correctas
- Revisar que está autenticado (login funcionando)

### Error: "Image picker not found"
- Ejecutar: `flutter pub get`
- En Android: Agregar permisos en `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
  ```

### Error: "Connection timeout"
- Verificar conexión a internet
- Verificar credenciales de Supabase en `constants.dart`

---

## 📝 Resumen del Flujo

```
Usuario hace click en cámara
        ↓
Se abre el selector de galería (image_picker)
        ↓
Usuario selecciona una foto
        ↓
Se comprime a 512x512
        ↓
Se sube a Supabase Storage (avatars/{userId}/avatar_userId.jpg)
        ↓
Se obtiene la URL pública
        ↓
Se guarda la URL en la BD (users.avatar_url)
        ↓
Se actualiza el avatar en la pantalla
        ↓
Se muestra mensaje de éxito
```

---

*Última actualización: 3 de Enero 2026*
