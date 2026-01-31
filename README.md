# 🧹 PurgeMac

> **Deep Cleaning Uninstaller for macOS**

PurgeMac es un desinstalador profundo para macOS que elimina completamente las aplicaciones junto con todos sus archivos residuales. A diferencia de simplemente arrastrar una app a la papelera, PurgeMac escanea el sistema en busca de cachés, preferencias, logs y otros artefactos que las aplicaciones dejan atrás.

![macOS 14+](https://img.shields.io/badge/macOS-14+-blue.svg)
![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-green.svg)

## ¿Por qué existe PurgeMac?

Cuando eliminas una aplicación en macOS arrastrándola a la papelera, solo se elimina el bundle `.app`. Sin embargo, las aplicaciones almacenan datos en múltiples ubicaciones del sistema:

- **~/Library/Application Support/** - Datos de la aplicación
- **~/Library/Caches/** - Archivos de caché temporales
- **~/Library/Preferences/** - Archivos de configuración (.plist)
- **~/Library/Logs/** - Registros de la aplicación
- **~/Library/Containers/** - Datos de apps sandboxed
- **~/Library/Saved Application State/** - Estado guardado de la UI
- Y más...

**PurgeMac** escanea todas estas ubicaciones y te permite eliminar selectivamente estos archivos residuales, recuperando espacio en disco y manteniendo tu sistema limpio.

---

## ✨ Características

### Implementadas

- 🎯 **Escaneo profundo**: Detecta archivos residuales en 11 categorías diferentes
- ⚡️ **Limpieza Solo de Caché**: Modo rápido para borrar solo archivos temporales (⇧⌘K)
- 🖱️ **Drag & Drop**: Simplemente arrastra una app para escanearla
- � **Historial Reciente**: Acceso rápido a las últimas 10 aplicaciones escaneadas con persistencia
- 🔄 **Re-escaneo Inteligente**: Actualiza el estado de la app actual manteniendo el modo de escaneo (⌘R)
- �📊 **Vista detallada**: Explora los archivos encontrados organizados por categoría
- ✅ **Selección granular**: Elige qué archivos eliminar individualmente o por categoría
- 🗑️ **Eliminación segura**: Mueve a la papelera por defecto
- 🔥 **Eliminación permanente**: Opción para borrar archivos sin pasar por la papelera
- ↩️ **Deshacer limpieza**: Restaura archivos movidos a papelera (30s después de eliminar)
- ℹ️ **Ventana Acerca de**: Información de versión y build
- 🌍 **Multi-idioma**: Soporte completo para Inglés y Español
- 🎨 **Temas visuales**: Claro, Oscuro, Sistema y Glass-Max personalizable
- 💎 **Diseño glass-morphism**: Interfaz moderna con efectos de transparencia configurables
- ⌨️ **Atajos de teclado**: Navegación rápida con shortcuts

### Categorías de Artefactos Detectados

| Categoría | Ubicación | Descripción |
|-----------|-----------|-------------|
| Application | `/Applications/` | El bundle de la aplicación (.app) |
| Application Support | `~/Library/Application Support/` | Datos persistentes de la app |
| Caches | `~/Library/Caches/` | Archivos temporales de caché |
| Preferences | `~/Library/Preferences/` | Archivos .plist de configuración |
| Logs | `~/Library/Logs/` | Registros y diagnósticos |
| Containers | `~/Library/Containers/` | Datos de apps sandboxed |
| Saved Application State | `~/Library/Saved Application State/` | Estado de ventanas guardado |
| HTTPStorages | `~/Library/HTTPStorages/` | Datos de red almacenados |
| WebKit | `~/Library/WebKit/` | Datos de WebKit/WebView |
| Launch Agents | `~/Library/LaunchAgents/` | Servicios en segundo plano |
| Cookies | `~/Library/Cookies/` | Cookies de la aplicación |

---

## 🏗️ Arquitectura del Proyecto

```
purgemac/
├── purgemac/
│   ├── PurgeMacApp.swift          # Entrada principal + Settings
│   ├── ContentView.swift           # Vista raíz
│   │
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── AppArtifact.swift   # Modelo de artefacto encontrado
│   │   │   ├── ScannedApp.swift    # Modelo de aplicación escaneada
│   │   │   ├── RecentAppEntry.swift # Modelo ligero para historial
│   │   │   └── ScanState.swift     # Máquina de estados del escaneo
│   │   │
│   │   ├── Services/
│   │   │   ├── FileSearchService.swift   # Servicio de búsqueda (actor)
│   │   │   ├── DeletorService.swift      # Servicio de eliminación (actor)
│   │   │   ├── HistoryService.swift      # Servicio de historial (actor)
│   │   │   └── PermissionService.swift   # Verificación Full Disk Access
│   │   │
│   │   ├── Localization/
│   │   │   └── LocalizationManager.swift # Sistema i18n (EN/ES)
│   │   │
│   │   └── Theme/
│   │       ├── ThemeManager.swift        # Gestión de temas
│   │       └── GlassModifiers.swift      # Efectos glass-morphism
│   │
│   ├── Features/
│   │   └── Scanner/
│   │       └── ScannerViewModel.swift    # ViewModel principal (MVVM)
│   │
│   └── UI/
│       ├── Atoms/          # Componentes atómicos (botones, iconos)
│       ├── Molecules/      # Componentes compuestos (cards, rows)
│       ├── Organisms/      # Componentes complejos (listas, paneles)
│       └── Screens/        # Pantallas completas
│           ├── HomeView.swift      # Pantalla de inicio + drop zone
│           ├── DetailView.swift    # Vista de artefactos encontrados
│           ├── RecentAppsSheet.swift # Historial de apps recientes
│           ├── AboutView.swift     # Ventana Acerca de
│           ├── SuccessView.swift   # Pantalla de éxito con confetti
│           └── ErrorView.swift     # Manejo de errores
```

### Patrones de Diseño

- **MVVM**: ViewModel centralizado (`ScannerViewModel`) con estado observable
- **Atomic Design**: Componentes UI organizados en Atoms → Molecules → Organisms → Screens
- **Actor Pattern**: Servicios usando Swift Actors para concurrencia segura
- **State Machine**: Estados del escaneo bien definidos (`ScanState`)
- **Singleton Pattern**: Servicios compartidos (FileSearchService, DeletorService, HistoryService)

---

## 🔧 Requisitos

- **macOS 14.0+** (Sonoma o posterior)
- **Xcode 15.0+**
- **Swift 6**
- **Full Disk Access** (requerido para escanear todas las ubicaciones)

### Configuración de Full Disk Access

PurgeMac necesita permisos de "Acceso completo al disco" para poder escanear las ubicaciones protegidas del sistema:

1. Abre **Ajustes del Sistema**
2. Ve a **Privacidad y seguridad** → **Acceso completo al disco**
3. Activa el interruptor para **PurgeMac**
4. Reinicia la app si se solicita

---

## 🚧 Roadmap / Funcionalidades Pendientes

*No hay funcionalidades pendientes en este momento.*

---

## 🎨 Sistema de Temas

PurgeMac incluye un sistema de temas completo con cuatro opciones:

| Tema | Descripción |
|------|-------------|
| **Claro** | Modo claro tradicional |
| **Oscuro** | Modo oscuro |
| **Sistema** | Sigue la preferencia del sistema |
| **Glass-Max** | Modo oscuro con máxima transparencia |

### Niveles de Transparencia

El nivel de transparencia del efecto glass se puede ajustar:
- Mínimo (30%)
- Bajo (50%)
- Medio (70%) - *Por defecto*
- Alto (85%)
- Máximo (95%)

---

## 🌍 Internacionalización

El sistema de localización soporta:
- 🇺🇸 **Inglés** (en)
- 🇪🇸 **Español** (es)
- 🔄 **Sistema** (detecta automáticamente)

Las traducciones se gestionan en `LocalizationManager.swift` y `Localizable.xcstrings`.

---

##  Privacidad y Seguridad

- **Sin telemetría**: La aplicación no recopila ni envía datos
- **Operación local**: Todo el procesamiento ocurre localmente
- **Transparencia**: Muestra exactamente qué archivos serán eliminados antes de actuar
- **Papelera por defecto**: Los archivos se mueven a la papelera primero, permitiendo recuperación

---

## 🛠️ Desarrollo

### Build
```bash
xcodebuild -scheme PurgeMac -configuration Release
```

---

<p align="center">
  <strong>PurgeMac</strong> - Mantén tu Mac limpia 🍎
  <br>
  <em>Proyecto personal desarrollado por @cgutieco</em>
</p>
