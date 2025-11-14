# iOSWeather ☀️

Una aplicación MVP de clima para iOS lista para producción que demuestra prácticas de desarrollo iOS de nivel Senior con SwiftUI, arquitectura MVVM y testing exhaustivo.

## Características

- **Clima Actual**: Clima en tiempo real basado en ubicación GPS usando CoreLocation
- **Búsqueda de Ciudades**: Busca cualquier ciudad del mundo con sugerencias de autocompletado
- **Historial de Búsquedas**: Guardado y gestión automática del historial de búsquedas
- **Arquitectura Limpia**: Patrón MVVM con inyección de dependencias basada en protocolos
- **Testing Exhaustivo**: Pruebas unitarias para todos los ViewModels con implementaciones mock

## Capturas de Pantalla

La aplicación incluye tres tabs principales:
1. **Actual**: Muestra el clima para tu ubicación GPS actual
2. **Búsqueda**: Busca cualquier ciudad y visualiza su clima
3. **Historial**: Accede a tus búsquedas anteriores

## Stack Tecnológico

- **iOS 15.0+**
- **SwiftUI** - Framework declarativo de UI
- **Swift** - Concurrencia moderna con async/await
- **Combine** - Programación reactiva para bindings de UI
- **Alamofire** - Networking HTTP elegante
- **Kingfisher** - Descarga y caché asíncrono de imágenes
- **XCTest** - Framework de pruebas unitarias

## Arquitectura

### Patrón MVVM

```
┌─────────────────────────────────────────────┐
│         Capa de Vista (SwiftUI)             │
│  CurrentWeatherView │ SearchView │ History  │
└───────────────┬─────────────────────────────┘
                │ @Published
┌───────────────▼─────────────────────────────┐
│           Capa ViewModel                    │
│  CurrentWeatherVM │ SearchVM │ HistoryVM    │
└───────────────┬─────────────────────────────┘
                │ Inyección de Protocolos
┌───────────────▼─────────────────────────────┐
│           Capa de Servicios                 │
│  NetworkService │ LocationService │ Storage │
└───────────────┬─────────────────────────────┘
                │
┌───────────────▼─────────────────────────────┐
│        Dependencias Externas                │
│  Open-Meteo API │ CoreLocation │ UserDefaults│
└─────────────────────────────────────────────┘
```

### Principios Clave

- **Separación de Responsabilidades**: Cada capa tiene una única responsabilidad
- **Inyección de Dependencias**: DI basada en protocolos para testabilidad
- **UI Reactiva**: Las vistas SwiftUI reaccionan a los cambios de estado del ViewModel
- **Manejo de Errores**: Manejo exhaustivo de errores en todas las capas
- **Async/Await**: Concurrencia moderna de Swift en todo el proyecto

## Instrucciones de Configuración

### Prerequisitos

- macOS Ventura 13.0+ (para Xcode 15)
- Xcode 15.0+
- Simulador iOS o dispositivo físico con iOS 15.0+

### Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd iosWeather
   ```

2. **Abrir el proyecto en Xcode**
   ```bash
   open iosWeather.xcodeproj
   ```

3. **Agregar Dependencias de Swift Package**

   El proyecto requiere dos paquetes SPM. En Xcode:

   **a) Agregar Alamofire:**
   - File → Add Package Dependencies
   - Ingresar URL: `https://github.com/Alamofire/Alamofire.git`
   - Regla de Dependencia: Up to Next Major Version 5.0.0
   - Agregar al target: `iosWeather`

   **b) Agregar Kingfisher:**
   - File → Add Package Dependencies
   - Ingresar URL: `https://github.com/onevcat/Kingfisher.git`
   - Regla de Dependencia: Up to Next Major Version 7.0.0
   - Agregar al target: `iosWeather`

4. **Compilar y Ejecutar**
   - Seleccionar un simulador (ej., iPhone 15)
   - Presionar `Cmd+R` o hacer clic en el botón Run
   - Otorgar permisos de ubicación cuando se solicite

## Estructura del Proyecto

```
iosWeather/
├── Models/                         # Modelos de datos
│   ├── WeatherData.swift           # Modelos de respuesta de API de clima
│   ├── Location.swift              # Modelos de ubicación y geocodificación
│   └── SearchHistory.swift         # Modelo de persistencia del historial
│
├── Services/                       # Capa de lógica de negocio
│   ├── NetworkService.swift        # Cliente API basado en Alamofire
│   ├── LocationService.swift       # Wrapper de CoreLocation
│   └── StorageService.swift        # Persistencia con UserDefaults
│
├── ViewModels/                     # ViewModels MVVM
│   ├── CurrentWeatherViewModel.swift
│   ├── SearchViewModel.swift
│   └── HistoryViewModel.swift
│
├── Views/                          # Vistas SwiftUI
│   ├── MainTabView.swift           # Navegación por tabs
│   ├── CurrentWeatherView.swift
│   ├── SearchView.swift
│   ├── HistoryView.swift
│   └── Components/                 # Componentes UI reutilizables
│       ├── WeatherCardView.swift
│       └── LoadingView.swift
│
└── iosWeatherApp.swift             # Punto de entrada de la app

iosWeatherTests/
├── Mocks/                          # Implementaciones mock
│   ├── MockNetworkService.swift
│   ├── MockLocationService.swift
│   └── MockStorageService.swift
│
└── ViewModelTests/                 # Pruebas unitarias
    ├── CurrentWeatherViewModelTests.swift
    ├── SearchViewModelTests.swift
    └── HistoryViewModelTests.swift
```

## API

Esta aplicación usa **Open-Meteo API**, una API de clima gratuita que no requiere clave API:

- **Weather API**: https://api.open-meteo.com/v1/forecast
- **Geocoding API**: https://geocoding-api.open-meteo.com/v1/search

### ¿Por qué Open-Meteo?

- ✅ Completamente gratuito
- ✅ No requiere clave API
- ✅ Sin límites de tasa para uso básico
- ✅ Datos de alta calidad
- ✅ Respuestas en JSON

## Pruebas

### Ejecutar Todas las Pruebas

```bash
xcodebuild test -project iosWeather.xcodeproj \
  -scheme iosWeather \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Ejecutar Suite de Pruebas Específica

```bash
xcodebuild test -project iosWeather.xcodeproj \
  -scheme iosWeather \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:iosWeatherTests/CurrentWeatherViewModelTests
```

### Cobertura de Pruebas

- **CurrentWeatherViewModel**: 6 casos de prueba
- **SearchViewModel**: 5 casos de prueba
- **HistoryViewModel**: 6 casos de prueba

Todas las pruebas utilizan implementaciones mock para testing unitario aislado.

## Desarrollo

### Agregar una Nueva Característica

1. Crear modelo en `Models/` (si es necesario)
2. Actualizar protocolo de servicio en `Services/`
3. Implementar en clase de servicio concreta
4. Crear ViewModel en `ViewModels/`
5. Construir vista SwiftUI en `Views/`
6. Crear mock en `iosWeatherTests/Mocks/`
7. Escribir pruebas unitarias en `iosWeatherTests/ViewModelTests/`

### Guías de Estilo de Código

- Usar `async/await` para código asíncrono
- Todos los ViewModels deben estar marcados con `@MainActor`
- Usar inyección de dependencias basada en protocolos
- Seguir el patrón MVVM estrictamente
- Escribir pruebas para todos los ViewModels

## Solución de Problemas

### La Ubicación No Funciona

1. Verificar que Info.plist tenga las descripciones de uso de ubicación
2. Reiniciar permisos de ubicación: Ajustes → Privacidad → Servicios de Ubicación
3. Reiniciar simulador: Device → Erase All Content and Settings

### Errores de Compilación Después de Clonar

1. Limpiar carpeta de build: `Cmd+Shift+K`
2. Reiniciar cachés de paquetes: File → Packages → Reset Package Caches
3. Resolver paquetes: File → Packages → Resolve Package Versions

### Pruebas Fallando

1. Asegurar que las pruebas estén marcadas con `@MainActor`
2. Verificar que todas las operaciones async usen `await`
3. Revisar configuraciones de mock en `setUp()` de las pruebas

## Mejoras Futuras

Este MVP puede extenderse con:

- **Pronósticos Diarios/Por Hora**: Pronósticos de 7 días y 24 horas
- **Alertas de Clima**: Notificaciones push para clima severo
- **Widgets**: Widgets para pantalla de inicio y pantalla de bloqueo
- **Modo Oscuro**: Soporte de temas personalizados
- **Modo Offline**: Caché de datos de clima para visualización sin conexión
- **Clean Architecture**: Extraer Use Cases para mejor separación
- **Patrón Coordinator**: Gestión avanzada de navegación
- **Snapshot Tests**: Pruebas de regresión de UI

## Licencia

Este proyecto fue creado con propósitos educativos y de portafolio.

## Autor

Juan Carlos Suarez Marin

---

**Nota**: Este es un MVP de calidad de producción que demuestra las mejores prácticas para desarrollo iOS incluyendo arquitectura limpia, inyección de dependencias, programación reactiva y testing exhaustivo.
