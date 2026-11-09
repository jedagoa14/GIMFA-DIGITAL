# GIMFA Digital — Instalación del MVP

## 1. Crear proyecto Supabase independiente

En Supabase crea un proyecto nuevo. Abre **SQL Editor**, pega todo el contenido de `supabase/schema.sql` y ejecútalo. Comprueba la tabla `students` y el bucket privado `student-photos`.

## 2. Crear administrador

En Supabase → Authentication → Users, usa **Add user** para crear una cuenta con correo y contraseña (correo real y contraseña fuerte). Después ejecuta en SQL Editor, reemplazando el correo:

```sql
insert into public.admins(user_id)
select id from auth.users where email = 'ADMIN@INSTITUCION.EDU.CO'
on conflict (user_id) do nothing;
```

No hay formulario público de alta de administradores. Solo usuarios de `public.admins` pueden gestionar estudiantes.

## 3. Desplegar función para fotografías

El bucket es privado. Para mostrar fotos desde el QR sin login, hay que desplegar la función Edge `card-photo` incluida en el proyecto. Desde una terminal con Supabase CLI instalada:

```bash
supabase login
supabase link --project-ref TU_PROJECT_REF
supabase functions deploy card-photo --no-verify-jwt
```

**Nunca coloques `service_role` en `config.js` ni en GitHub.** La función usa credenciales secretas del entorno Supabase y solo firma fotos tras validar el token QR y el estado/autorización del estudiante.

## 4. Configurar frontend

En `config.js`, reemplaza los dos valores de ejemplo por **Project URL** y **Publishable key** de Supabase → Project Settings → API Keys. La clave pública puede usarse en navegador; no utilices claves secretas.

Para pruebas locales abre `index.html` con Live Server. Para producción sube los archivos a un repositorio GitHub y activa Settings → Pages → Deploy from branch → main / (root). La URL debe ser HTTPS.

## 5. Identidad institucional

Copia el logotipo real de la institución a `assets/logo-institucional.png`. No se ha incluido ningún logotipo institucional inventado.

## 6. Registro manual y Excel

Accede como administrador. Registra un estudiante o descarga la plantilla Excel. Columnas: `nombre_completo`, `identificacion`, `rh`, `telefono_acudiente`, `grado`, `anio_lectivo`, `autorizado` (SI/NO). La importación usa el número de documento para actualizar filas existentes. **Las fotografías se cargan individualmente**. Al importar, el campo `autorizado` determina si se puede mostrar la ficha públicamente.

Para obtener un QR: en el listado pulsa **QR**. Se abrirá una página imprimible con el código y enlace. Para revocar una manilla extraviada, pulsa **Revocar QR**; el anterior dejará de funcionar.

## 7. Seguridad y validación

**Advertencia de privacidad:** el QR da acceso sin autenticación a foto, documento, RH y teléfono del acudiente. Esos datos pueden ser copiados o difundidos. Antes de usar con menores, obtén autorización informada y específica de sus representantes y realiza revisión institucional/legal del tratamiento de datos. No subas datos reales a un repositorio público ni compartas el CSV de enlaces.

**Pruebas recomendadas:** registro manual, importación de Excel, edición, carga de fotografía, consulta desde otro celular, revocación de QR, estudiante inactivo, estudiante sin consentimiento, acceso con cuenta no administradora, duplicación de documento y ausencia de listados públicos.

**Limitaciones MVP:** no tiene carga masiva de fotos ni impresión masiva de planchas de QR; la función Edge debe desplegarse por separado; no es un sistema de emergencias médicas y el RH debe verificarse contra la fuente institucional.
