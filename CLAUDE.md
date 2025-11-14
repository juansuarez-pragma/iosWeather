# CLAUDE.md

Este archivo proporciona orientación a Claude Code (claude.ai/code) al trabajar con código en este repositorio.

## Descripción General del Proyecto

**iOSWeather** es un MVP de aplicación de clima para iOS construido con SwiftUI siguiendo las mejores prácticas de nivel Senior. La aplicación demuestra arquitectura limpia, inyección de dependencias y testing exhaustivo.

### Características Clave
- Clima actual basado en ubicación GPS
- Búsqueda de ciudades con autocompletado
- Historial de búsquedas con persistencia
- Arquitectura offline-first con caché local

### Stack Tecnológico
- **Framework de UI**: SwiftUI
- **Lenguaje**: Swift (async/await, Combine)
- **Arquitectura**: MVVM con inyección de dependencias basada en protocolos
- **API de Clima**: Open-Meteo API (gratuita, sin API key requerida)
- **Dependencias**: Alamofire (networking), Kingfisher (caché de imágenes)
- **Gestor de Paquetes**: Swift Package Manager (SPM)
- **Testing**: XCTest con implementaciones mock

## Instrucciones de Configuración

### 1. Agregar Dependencias de Swift Package

El proyecto requiere dos paquetes SPM. Agrégalos a través de Xcode:

**Alamofire** (Networking):
1. File → Add Package Dependencies
2. Ingresar: `https://github.com/Alamofire/Alamofire.git`
3. Versión: Up to Next Major 5.0.0
4. Agregar al target: `iosWeather`

**Kingfisher** (Carga de Imágenes):
1. File → Add Package Dependencies
2. Ingresar: `https://github.com/onevcat/Kingfisher.git`
3. Versión: Up to Next Major 7.0.0
4. Agregar al target: `iosWeather`

### 2. Configurar Info.plist

Asegurar que `Info.plist` contenga los permisos de ubicación (ya configurado):
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`

### 3. Compilar y Ejecutar

```bash
open iosWeather.xcodeproj
# Luego Cmd+R en Xcode
```

O vía línea de comandos:
```bash
xcodebuild -project iosWeather.xcodeproj -scheme iosWeather -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## Arquitectura

### Patrón MVVM

El proyecto sigue arquitectura MVVM limpia:

```
Vista → ViewModel → Servicio → API/Storage
  ↓         ↓          ↓
SwiftUI  @Published  Protocol
```

**Principios Clave**:
- Las vistas son tontas y declarativas
- Los ViewModels contienen toda la lógica de negocio
- Los servicios están basados en protocolos para inyección de dependencias
- Todas las dependencias pueden ser mockeadas para testing

### Estructura del Proyecto

```
iosWeather/
├── Models/                     # Modelos de datos (Codable)
│   ├── WeatherData.swift       # Modelos de respuesta API
│   ├── Location.swift          # Modelos de ubicación y geocodificación
│   └── SearchHistory.swift     # Modelos de persistencia
│
├── Services/                   # Capa de lógica de negocio
│   ├── NetworkService.swift    # Wrapper de Alamofire (basado en protocolos)
│   ├── LocationService.swift   # Wrapper de CoreLocation
│   └── StorageService.swift    # Persistencia con UserDefaults
│
├── ViewModels/                 # ViewModels MVVM
│   ├── CurrentWeatherViewModel.swift
│   ├── SearchViewModel.swift
│   └── HistoryViewModel.swift
│
├── Views/                      # Vistas SwiftUI
│   ├── MainTabView.swift       # Navegación por tabs
│   ├── CurrentWeatherView.swift
│   ├── SearchView.swift
│   ├── HistoryView.swift
│   └── Components/             # Componentes reutilizables
│       ├── WeatherCardView.swift
│       └── LoadingView.swift
│
└── iosWeatherApp.swift         # Punto de entrada de la app

iosWeatherTests/
├── Mocks/                      # Implementaciones de protocolos para testing
│   ├── MockNetworkService.swift
│   ├── MockLocationService.swift
│   └── MockStorageService.swift
│
└── ViewModelTests/             # Pruebas unitarias (XCTest)
    ├── CurrentWeatherViewModelTests.swift
    ├── SearchViewModelTests.swift
    └── HistoryViewModelTests.swift
```

### Inyección de Dependencias

Todos los servicios usan DI basada en protocolos:

```swift
// Definición de protocolo
protocol NetworkServiceProtocol {
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse
}

// Implementación de producción
class NetworkService: NetworkServiceProtocol { ... }

// Implementación mock
class MockNetworkService: NetworkServiceProtocol { ... }

// Inyección en ViewModel
class CurrentWeatherViewModel {
    init(networkService: NetworkServiceProtocol) { ... }
}
```

### Gestión de Estado

Los ViewModels usan el enum `ViewState` para el estado de la UI:

```swift
enum ViewState: Equatable {
    case idle
    case loading
    case loaded(WeatherDisplayModel)
    case error(String)
}
```

Las vistas reaccionan a cambios de estado vía propiedades `@Published`.

### Integración con API

Endpoints de **Open-Meteo API**:
- Clima: `https://api.open-meteo.com/v1/forecast`
- Geocodificación: `https://geocoding-api.open-meteo.com/v1/search`

No requiere API key. Todas las peticiones son GET con parámetros de consulta.

### Persistencia de Datos

El historial de búsquedas se almacena en `UserDefaults` como JSON:
- Máximo 20 items
- Ordenados por fecha (más reciente primero)
- Los duplicados se mueven al inicio

## Testing

### Framework de Testing

Se usa **XCTest** para pruebas unitarias (no Swift Testing para archivos de test).

### Ejecutar Tests

**Todos los tests:**
```bash
xcodebuild test -project iosWeather.xcodeproj -scheme iosWeather -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Archivo de test específico:**
```bash
xcodebuild test -project iosWeather.xcodeproj -scheme iosWeather -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:iosWeatherTests/CurrentWeatherViewModelTests
```

**Método de test individual:**
```bash
xcodebuild test -project iosWeather.xcodeproj -scheme iosWeather -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:iosWeatherTests/CurrentWeatherViewModelTests/testFetchCurrentLocationWeather_Success
```

### Estrategia de Testing

- **Pruebas Unitarias**: Todos los ViewModels tienen cobertura exhaustiva de tests
- **Servicios Mock**: Mocks basados en protocolos para todas las dependencias externas
- **Cobertura de Tests**: Estados de carga, casos de éxito, manejo de errores

### Escribir Tests

Ejemplo de estructura de test:

```swift
@MainActor
final class CurrentWeatherViewModelTests: XCTestCase {
    var sut: CurrentWeatherViewModel!
    var mockNetworkService: MockNetworkService!

    override func setUp() {
        mockNetworkService = MockNetworkService()
        sut = CurrentWeatherViewModel(networkService: mockNetworkService)
    }

    func testFetchWeather_Success() async {
        // Given: Mock configurado
        mockNetworkService.weatherResponse = MockNetworkService.createMockWeatherResponse()

        // When: Acción realizada
        await sut.fetchCurrentLocationWeather()

        // Then: Aserciones
        XCTAssertEqual(sut.state, .loaded(...))
    }
}
```

## Tareas Comunes de Desarrollo

### Agregar una Nueva Característica

1. **Crear Modelo** en `Models/` si es necesario (debe ser `Codable` para modelos de API)
2. **Actualizar Servicio** protocolo e implementación en `Services/`
3. **Crear ViewModel** en `ViewModels/` con estado `@Published`
4. **Construir Vista** en `Views/` que observa el ViewModel
5. **Crear Mock** en `iosWeatherTests/Mocks/`
6. **Escribir Tests** en `iosWeatherTests/ViewModelTests/`

### Modificar Integración con API

Todas las llamadas de red pasan por `NetworkService.swift`. El servicio usa Alamofire y convierte callbacks a async/await.

Para agregar un nuevo endpoint:
1. Agregar método a `NetworkServiceProtocol`
2. Implementar en `NetworkService` usando Alamofire
3. Agregar implementación mock a `MockNetworkService`

### Agregar Nuevas Dependencias

Usar solo SPM. Agregar a través de Xcode:
1. File → Add Package Dependencies
2. Ingresar URL del repositorio
3. Seleccionar reglas de versión
4. Agregar a targets apropiados

## Estilo de Código

- Usar `async/await` para operaciones asíncronas
- Usar `Combine` solo para bindings reactivos de UI
- Todos los ViewModels deben ser `@MainActor`
- Usar `private(set)` para propiedades publicadas
- Los nombres de protocolos terminan con sufijo `Protocol`
- Las clases mock comienzan con prefijo `Mock`

## Solución de Problemas

### Problemas con Permisos de Ubicación
- Asegurar que `Info.plist` tenga descripciones de uso de ubicación
- Revisar Ajustes del sistema → Privacidad → Servicios de Ubicación
- Reiniciar simulador: Device → Erase All Content and Settings

### Dependencias SPM No Encontradas
- File → Packages → Reset Package Caches
- File → Packages → Resolve Package Versions
- Limpiar carpeta de build: Cmd+Shift+K

### Tests Fallando
- Asegurar que los tests se ejecuten en main actor: `@MainActor`
- Revisar configuraciones de mock en `setUp()`
- Verificar que las operaciones async usen `await`
