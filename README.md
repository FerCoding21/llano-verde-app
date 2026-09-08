# Llano Verde — Sistema de Gestión de Alquileres

Aplicación multiplataforma desarrollada con **Flutter + Supabase** para digitalizar y automatizar las operaciones de [Alquileres de Equipo Llano Verde](mailto:ventas@syesolucionessrl.com), empresa costarricense dedicada al alquiler de equipos para construcción.

> Proyecto de Práctica Empresarial Supervisada (PES) — Universidad Latina de Costa Rica, Ingeniería de Software, 2026.

---

## Plataformas

| Android | Windows Web |
|---------|-------------|
| ✅ | ✅ | ✅ |

---

## Funcionalidades

### Inventario
- Registro de equipos con número de activo, nombre, descripción y estado
- Galería de fotografías por equipo con selección de foto principal (portada)
- Filtrado por estado (disponible / alquilado / mantenimiento) y búsqueda por nombre
- Actualización automática de estado al crear o finalizar una boleta

### Proformas
- Generación de presupuestos personalizados en **colones (₡) o dólares ($)**
- Cálculo automático de subtotal, IVA (13%) y total
- Exportación a **PDF** con logo, fotografía del equipo y desglose completo
- Envío automatizado al correo del cliente vía **Resend**

### Boletas
- Formulario completo de alquiler con datos del cliente, equipos, fechas y costos
- Campo de número de orden de compra (requerido por clientes corporativos)
- Captura de fotografías al momento de la entrega
- Exportación a **PDF** con fotografía principal de cada equipo
- Envío automatizado al correo del cliente

### Verificación
- Lista de boletas activas con indicador visual de urgencia por días restantes
- Extensión de fecha de retiro sin cancelar la boleta
- Finalización de boleta con liberación automática de equipos
- Alertas locales programadas para fechas de retiro próximas

---

## Stack tecnológico

| Capa | Tecnología |
|------|-----------|
| UI / Multiplataforma | Flutter 3.44.0 · Dart 3.12.0 |
| Estado | Flutter Riverpod 2.x |
| Navegación | go_router |
| Base de datos | Supabase (PostgreSQL) |
| Autenticación | Supabase Auth |
| Almacenamiento de imágenes | Supabase Storage |
| Generación de PDF | pdf + printing |
| Envío de correos | Resend API |
| Notificaciones locales | flutter_local_notifications |
| Caché de imágenes | cached_network_image |

---

## Arquitectura

El proyecto sigue una **arquitectura por capas**:

```
lib/
├── core/
│   └── utils/          # Generadores de PDF, servicio de email, notificaciones
├── data/
│   ├── repositories/   # Acceso a datos (Supabase)
│   ├── providers/      # Estado global con Riverpod
│   └── supabase/       # Configuración del cliente
├── domain/
│   └── models/         # Entidades del negocio
└── presentation/
    └── screens/        # Pantallas de la aplicación
```

---

## Esquema de base de datos

```
inventario          → equipos de la empresa
inventario_imagenes → galería de fotos por equipo
proforma            → cabecera de presupuesto
proforma_equipo     → equipos incluidos en cada proforma
boleta              → contrato de alquiler formalizado
boleta_equipo       → equipos alquilados en cada boleta
boleta_imagen       → fotos tomadas al momento de entrega
```

---

## Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.44.0
- Cuenta en [Supabase](https://supabase.com) con el esquema aplicado
- Cuenta en [Resend](https://resend.com) con dominio verificado
- Android SDK (para build Android) o Visual Studio con C++ workload (para build Windows)

---

## Configuración del entorno

Crea el archivo `.env` en la raíz del proyecto con las siguientes variables:

```env
SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
RESEND_API_KEY=re_xxxxxxxxxxxx
RESEND_FROM_EMAIL=ventas@tudominio.com
```

> **Importante:** El archivo `.env` está incluido en `.gitignore`. Nunca lo publiques en el repositorio.

---

## Instalación

```bash
# 1. Clonar el repositorio
git clone https://github.com/tu-usuario/llano_verde.git
cd llano_verde

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar en modo desarrollo
flutter run
```

---

## Build de producción

### Android (APK)

```bash
flutter build apk --release
# Salida: build/app/outputs/flutter-apk/app-release.apk
```

### Windows

```bash
flutter build windows --release
# Salida: build/windows/x64/runner/Release/
```

> Para distribuir en Windows, comprimir **toda** la carpeta `Release/` en un ZIP. El ejecutable no funciona de forma independiente.

```powershell
Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath "LlanoVerde.zip"
```

---

## Base de datos — Consecutivos iniciales

Al desplegar en producción, ajustar los consecutivos de boletas y proformas para que continúen la numeración existente de la empresa:

```sql
-- Siguiente boleta: 1288
SELECT setval(pg_get_serial_sequence('boleta', 'boleta_id'), 1287);

-- Siguiente proforma: 1505
SELECT setval(pg_get_serial_sequence('proforma', 'proforma_id'), 1504);
```

---

## Autor

**Fernando Jesús Vargas Ramírez**  
Estudiante de Ingeniería de Software — Universidad Latina de Costa Rica  
fernando.vargas5@ulatina.net

---

## Licencia

Proyecto de uso privado desarrollado para S Y E Soluciones SRL. Todos los derechos reservados.
