# Arquitectura y Tecnologías - iosWeather

## Índice
1. [Arquitectura MVVM](#arquitectura-mvvm)
2. [SwiftUI](#swiftui)
3. [Concurrencia Moderna (Async/Await)](#concurrencia-moderna-asyncawait)
4. [Combine Framework](#combine-framework)
5. [Alamofire](#alamofire)
6. [Inyección de Dependencias Basada en Protocolos](#inyección-de-dependencias-basada-en-protocolos)
7. [CoreLocation](#corelocation)
8. [UserDefaults](#userdefaults)
9. [XCTest y Testing](#xctest-y-testing)
10. [Swift Package Manager](#swift-package-manager)
11. [Open-Meteo API](#open-meteo-api)
12. [Decisiones de Diseño y Alternativas](#decisiones-de-diseño-y-alternativas)

---

## Arquitectura MVVM

### ¿Qué es MVVM?

**MVVM (Model-View-ViewModel)** es un patrón arquitectónico que separa la lógica de negocio de la interfaz de usuario, promoviendo código testeable, mantenible y escalable.

#### Componentes:

```
┌─────────────────────────────────────────────────┐
│                    VIEW                         │
│  (SwiftUI Views - Declarativo)                  │
│  - CurrentWeatherView.swift                     │
│  - SearchView.swift                             │
│  - HistoryView.swift                            │
└────────────┬────────────────────────────────────┘
             │ Observa @Published
             │ (Combine/Property Wrappers)
             ▼
┌─────────────────────────────────────────────────┐
│                 VIEW MODEL                      │
│  (Lógica de Presentación)                       │
│  @MainActor class ...ViewModel: ObservableObject│
│  - CurrentWeatherViewModel.swift                │
│  - SearchViewModel.swift                        │
│  - HistoryViewModel.swift                       │
└────────────┬────────────────────────────────────┘
             │ Usa Protocolos
             │ (Dependency Injection)
             ▼
┌─────────────────────────────────────────────────┐
│                  MODEL + SERVICES               │
│  (Datos y Lógica de Negocio)                    │
│  - WeatherData.swift                            │
│  - NetworkService.swift                         │
│  - LocationService.swift                        │
│  - StorageService.swift                         │
└─────────────────────────────────────────────────┘
```

### Implementación en el Proyecto

#### 1. **Model (Modelo)**
```swift
// iosWeather/Models/WeatherData.swift
struct WeatherResponse: Codable {
    let latitude: Double
    let longitude: Double
    let current: CurrentWeather
}

struct WeatherDisplayModel {
    let cityName: String
    let temperature: Double
    let description: String
    // Modelo optimizado para la UI
}
```

**Responsabilidades:**
- Representar datos de la aplicación
- Lógica de transformación de datos (API → Display Model)
- Validación y reglas de negocio

#### 2. **View (Vista)**
```swift
// iosWeather/Views/CurrentWeatherView.swift
struct CurrentWeatherView: View {
    @StateObject private var viewModel: CurrentWeatherViewModel

    var body: some View {
        switch viewModel.state {
        case .loaded(let weather):
            WeatherCardView(weather: weather)
        case .loading:
            LoadingView()
        case .error(let message):
            ErrorView(message: message)
        }
    }
}
```

**Responsabilidades:**
- Renderizar UI declarativamente
- Reaccionar a cambios del ViewModel
- Capturar interacciones del usuario
- **NO contiene lógica de negocio**

#### 3. **ViewModel (Modelo de Vista)**
```swift
// iosWeather/ViewModels/CurrentWeatherViewModel.swift
@MainActor
final class CurrentWeatherViewModel: ObservableObject {
    @Published private(set) var state: ViewState = .idle

    private let networkService: NetworkServiceProtocol
    private let locationService: LocationServiceProtocol

    func fetchCurrentLocationWeather() async {
        state = .loading
        // Orquesta la lógica de negocio
        let coordinates = try await locationService.getCurrentLocation()
        let weather = try await networkService.fetchWeather(...)
        state = .loaded(weatherModel)
    }
}
```

**Responsabilidades:**
- Orquestar llamadas a servicios
- Transformar datos del Model a formato UI-friendly
- Manejar estados de la vista (loading, loaded, error)
- Exponer propiedades `@Published` para binding reactivo

### ¿Por qué MVVM?

#### Ventajas Implementadas:

1. **Separación de Responsabilidades**
   - Las vistas solo renderizan
   - Los ViewModels contienen toda la lógica
   - Los Models representan datos puros

2. **Testabilidad**
   ```swift
   // iosWeatherTests/ViewModelTests/CurrentWeatherViewModelTests.swift
   func testFetchWeatherSuccess() async {
       // Mock de dependencias
       let mockNetwork = MockNetworkService()
       let mockLocation = MockLocationService()
       let viewModel = CurrentWeatherViewModel(
           networkService: mockNetwork,
           locationService: mockLocation
       )

       await viewModel.fetchCurrentLocationWeather()

       // Aserciones sin necesidad de UI
       XCTAssertEqual(viewModel.state, .loaded(...))
   }
   ```

3. **Binding Reactivo con SwiftUI**
   - `@StateObject`: Crea y mantiene el ViewModel
   - `@Published`: Notifica automáticamente cambios a la vista
   - `@ObservableObject`: Protocolo que hace al ViewModel observable

4. **Reutilización de Componentes**
   - ViewModels pueden ser reutilizados en diferentes vistas
   - Servicios son compartidos entre ViewModels

### Alternativas Descartadas

#### **MVC (Model-View-Controller)**
```swift
// ❌ Problema: Massive View Controller
class WeatherViewController: UIViewController {
    // Mezcla de lógica de UI, networking, y business logic
    override func viewDidLoad() {
        fetchWeather() // Networking en el controller
        setupUI()      // UI setup
        validateData() // Business logic
    }
}
```

**Por qué se descartó:**
- ViewControllers se vuelven masivos (>1000 líneas)
- Difícil de testear (necesita instanciar la UI)
- Lógica de negocio acoplada a UIKit
- No aprovecha el binding reactivo de SwiftUI

#### **VIPER (View-Interactor-Presenter-Entity-Router)**
```
View ← Presenter ← Interactor ← Entity
              ↓
            Router
```

**Por qué se descartó:**
- Demasiado complejo para un proyecto de este tamaño
- Requiere 5 archivos por cada pantalla
- Overhead innecesario para una app simple
- Mayor curva de aprendizaje

#### **Redux/TCA (The Composable Architecture)**
```swift
// Requiere acciones, reducers, effects, state global
struct AppState { ... }
enum AppAction { case fetchWeather, ... }
```

**Por qué se descartó:**
- Complejidad excesiva para una app con 3 pantallas
- Estado global no necesario (cada pantalla es independiente)
- Curva de aprendizaje elevada
- Boilerplate excesivo

---

## SwiftUI

### ¿Qué es SwiftUI?

**SwiftUI** es el framework declarativo de Apple para construir interfaces de usuario en todas las plataformas Apple (iOS, macOS, watchOS, tvOS).

### Características Clave

#### 1. **UI Declarativa**
```swift
// ✅ SwiftUI - Declarativo
var body: some View {
    VStack {
        Text("Clima Actual")
        WeatherCardView(weather: weather)
    }
}

// ❌ UIKit - Imperativo
let label = UILabel()
label.text = "Clima Actual"
label.font = .systemFont(ofSize: 24)
view.addSubview(label)
label.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([...])
```

**Ventajas:**
- Describe **qué** debe mostrarse, no **cómo** construirlo
- Menos código, más legible
- Sistema automático de layout

#### 2. **Property Wrappers Reactivos**

```swift
@StateObject private var viewModel: CurrentWeatherViewModel
@State private var searchQuery = ""
@Published private(set) var state: ViewState
@Environment(\.colorScheme) var colorScheme
```

| Property Wrapper | Uso en el Proyecto | Propósito |
|-----------------|-------------------|-----------|
| `@StateObject` | ViewModels en Views | Crea y mantiene lifetime del objeto observable |
| `@Published` | Propiedades del ViewModel | Notifica cambios a los observadores |
| `@State` | Estados locales simples | Maneja estado privado de la vista |
| `@Binding` | (No usado, pero disponible) | Compartir estado entre vistas padre-hijo |

**Implementación:**
```swift
// View observa el ViewModel
struct CurrentWeatherView: View {
    @StateObject private var viewModel: CurrentWeatherViewModel

    var body: some View {
        // Automáticamente se re-renderiza cuando viewModel.state cambia
        switch viewModel.state {
        case .loaded(let weather):
            WeatherCardView(weather: weather)
        }
    }
}
```

#### 3. **Componentes Reutilizables**

```swift
// iosWeather/Views/Components/LoadingView.swift
struct LoadingView: View {
    var message: String = "Cargando..."

    var body: some View {
        VStack {
            ProgressView().scaleEffect(1.5)
            Text(message)
        }
    }
}

// Reutilizado en múltiples vistas
LoadingView(message: "Obteniendo tu ubicación...")
LoadingView(message: "Buscando ciudades...")
LoadingView(message: "Cargando clima...")
```

**Beneficios:**
- DRY (Don't Repeat Yourself)
- Consistencia visual
- Fácil de mantener

#### 4. **Previews**

```swift
#Preview {
    CurrentWeatherView(
        viewModel: CurrentWeatherViewModel(
            networkService: NetworkService(),
            locationService: LocationService()
        )
    )
}
```

**Ventajas:**
- Desarrollo iterativo rápido
- No necesita ejecutar la app completa
- Múltiples estados simultáneos

### Implementación en el Proyecto

#### Navegación con TabView
```swift
// iosWeather/Views/MainTabView.swift
TabView(selection: $selectedTab) {
    CurrentWeatherView(...)
        .tabItem { Label("Actual", systemImage: "location.fill") }
        .tag(0)

    SearchView(...)
        .tabItem { Label("Buscar", systemImage: "magnifyingglass") }
        .tag(1)

    HistoryView(...)
        .tabItem { Label("Historial", systemImage: "clock.fill") }
        .tag(2)
}
```

#### Modificadores de Vista
```swift
.navigationTitle("Clima Actual")
.toolbar { ... }
.alert("Permiso Requerido", isPresented: $showAlert) { ... }
.task { await viewModel.fetchWeather() }
```

### Alternativas Descartadas

#### **UIKit**
```swift
// ❌ UIKit - Mucho más código
class WeatherViewController: UIViewController {
    let stackView = UIStackView()
    let temperatureLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        bindViewModel()
    }

    func setupViews() {
        view.addSubview(stackView)
        stackView.addArrangedSubview(temperatureLabel)
        // 50+ líneas de configuración...
    }

    func setupConstraints() {
        // 30+ líneas de constraints...
    }
}
```

**Por qué se descartó:**
- 10x más código para la misma UI
- No tiene binding reactivo nativo
- Código imperativo, más propenso a bugs
- Necesita librerías de terceros para binding (RxSwift, Combine)

#### **React Native / Flutter**
**Por qué se descartó:**
- No es nativo de iOS
- Mayor tamaño de app (incluye runtime)
- Acceso limitado a APIs nativas
- SwiftUI es el estándar de Apple

---

## Concurrencia Moderna (Async/Await)

### ¿Qué es Async/Await?

Introducido en **Swift 5.5**, `async/await` es el sistema de concurrencia estructurada que reemplaza los callbacks anidados (callback hell) con código secuencial y legible.

### Sintaxis Básica

```swift
// ✅ Async/Await - Código legible y secuencial
func fetchCurrentLocationWeather() async {
    state = .loading

    let coordinates = try await locationService.getCurrentLocation()
    let weather = try await networkService.fetchWeather(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude
    )

    state = .loaded(weatherModel)
}

// ❌ Callbacks - Callback Hell
func fetchCurrentLocationWeather(completion: @escaping (Result<Weather, Error>) -> Void) {
    locationService.getCurrentLocation { result in
        switch result {
        case .success(let coordinates):
            networkService.fetchWeather(lat: coordinates.latitude, lon: coordinates.longitude) { weatherResult in
                switch weatherResult {
                case .success(let weather):
                    completion(.success(weather))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }
}
```

### Implementación en el Proyecto

#### 1. **ViewModels con Async/Await**
```swift
// iosWeather/ViewModels/SearchViewModel.swift
@MainActor
final class SearchViewModel: ObservableObject {
    @Published var searchResults: [GeocodingResult] = []

    func searchCity(_ query: String) async {
        guard !query.isEmpty else { return }

        do {
            // Llamada asíncrona sin callbacks
            let results = try await networkService.searchCity(query: query)
            searchResults = results
        } catch {
            print("Error: \(error)")
        }
    }
}
```

#### 2. **Vistas que Llaman Async Functions**
```swift
// iosWeather/Views/CurrentWeatherView.swift
struct CurrentWeatherView: View {
    @StateObject private var viewModel: CurrentWeatherViewModel

    var body: some View {
        ZStack { ... }
            .task {
                // .task ejecuta código async cuando la vista aparece
                await viewModel.fetchCurrentLocationWeather()
            }
            .toolbar {
                Button(action: {
                    Task {
                        // Task envuelve código async
                        await viewModel.refresh()
                    }
                }) { ... }
            }
    }
}
```

#### 3. **Conversión de Alamofire a Async/Await**
```swift
// iosWeather/Services/NetworkService.swift
func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse {
    return try await withCheckedThrowingContinuation { continuation in
        session.request(Endpoint.weatherBaseURL, method: .get, parameters: parameters)
            .validate()
            .responseDecodable(of: WeatherResponse.self) { response in
                switch response.result {
                case .success(let weatherResponse):
                    continuation.resume(returning: weatherResponse)
                case .failure(let error):
                    continuation.resume(throwing: NetworkError.networkError(error))
                }
            }
    }
}
```

**Patrón utilizado:**
- `withCheckedThrowingContinuation`: Convierte callbacks a async/await
- `continuation.resume(returning:)`: Retorna valor exitoso
- `continuation.resume(throwing:)`: Lanza error

### Ventajas

1. **Código Secuencial y Legible**
   - Se lee de arriba a abajo
   - Fácil de entender el flujo

2. **Manejo de Errores con try/catch**
   ```swift
   do {
       let coordinates = try await locationService.getCurrentLocation()
       let weather = try await networkService.fetchWeather(...)
   } catch let error as LocationError {
       handleLocationError(error)
   } catch let error as NetworkError {
       state = .error(error.localizedDescription)
   }
   ```

3. **Cancelación Automática**
   - Las tareas se cancelan automáticamente cuando la vista desaparece
   - `.task { }` maneja el lifecycle

4. **Thread Safety con @MainActor**
   ```swift
   @MainActor
   final class CurrentWeatherViewModel: ObservableObject {
       // Garantiza que todas las actualizaciones de UI ocurren en el main thread
       @Published private(set) var state: ViewState = .idle
   }
   ```

### Alternativas Descartadas

#### **Completion Handlers**
```swift
// ❌ Difícil de leer, callback hell
func fetchWeather(completion: @escaping (Result<Weather, Error>) -> Void) {
    locationService.getCurrentLocation { locationResult in
        switch locationResult {
        case .success(let coordinates):
            networkService.fetchWeather(lat: coordinates.latitude) { weatherResult in
                // Anidación excesiva
            }
        }
    }
}
```

**Problemas:**
- Difícil de leer y mantener
- Propenso a retain cycles
- Manejo de errores complicado

#### **RxSwift / Combine Operators**
```swift
// ❌ Curva de aprendizaje elevada
locationService.getCurrentLocationPublisher()
    .flatMap { coordinates in
        networkService.fetchWeatherPublisher(lat: coordinates.latitude)
    }
    .sink(
        receiveCompletion: { completion in ... },
        receiveValue: { weather in ... }
    )
    .store(in: &cancellables)
```

**Por qué se descartó para async operations:**
- Async/await es más simple y estándar en Swift
- Menor overhead conceptual
- Mejor para operaciones de una sola vez (no streams)

---

## Combine Framework

### ¿Qué es Combine?

**Combine** es el framework reactivo de Apple para procesar valores a lo largo del tiempo. En este proyecto, se usa específicamente para el **binding reactivo entre ViewModel y View**.

### Uso Específico en el Proyecto

#### **ObservableObject y @Published**
```swift
// iosWeather/ViewModels/SearchViewModel.swift
@MainActor
final class SearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [GeocodingResult] = []
    @Published private(set) var weatherState: WeatherState = .idle

    private var cancellables = Set<AnyCancellable>()

    init(...) {
        // Debounce para búsqueda - evita búsquedas en cada keystroke
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                Task {
                    await self?.searchCity(query)
                }
            }
            .store(in: &cancellables)
    }
}
```

**Flujo de Datos:**
```
Usuario escribe "Madrid"
    ↓
@Published searchQuery actualiza
    ↓
$searchQuery (Publisher) emite "M", "Ma", "Mad", ...
    ↓
.debounce(500ms) espera 500ms sin cambios
    ↓
.removeDuplicates() elimina valores repetidos
    ↓
.sink llama a searchCity("Madrid")
    ↓
@Published searchResults actualiza
    ↓
SwiftUI re-renderiza la vista automáticamente
```

### Operadores Combine Utilizados

| Operador | Ubicación | Propósito |
|----------|-----------|-----------|
| `debounce` | SearchViewModel | Espera 500ms antes de buscar (evita spam) |
| `removeDuplicates` | SearchViewModel | Evita búsquedas repetidas |
| `sink` | ViewModels | Suscribe a cambios y ejecuta closure |
| `store(in:)` | ViewModels | Almacena la suscripción (evita retain cycles) |

### Ventajas en este Contexto

1. **Binding Reactivo Automático**
   ```swift
   // La vista se actualiza automáticamente cuando @Published cambia
   struct SearchView: View {
       @StateObject private var viewModel: SearchViewModel

       var body: some View {
           TextField("Buscar...", text: $viewModel.searchQuery)
           // Binding bidireccional automático
       }
   }
   ```

2. **Debouncing para Performance**
   - Sin debounce: 10 búsquedas al escribir "New York" (una por letra)
   - Con debounce: 1 búsqueda después de 500ms de pausa

3. **Memory Management Automático**
   ```swift
   private var cancellables = Set<AnyCancellable>()

   publisher
       .sink { ... }
       .store(in: &cancellables)

   // Automáticamente se cancela cuando el ViewModel es deallocated
   ```

### Alternativas Descartadas

#### **RxSwift**
```swift
// ❌ Librería de terceros
searchQuery.asObservable()
    .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
    .distinctUntilChanged()
    .subscribe(onNext: { query in ... })
    .disposed(by: disposeBag)
```

**Por qué se descartó:**
- Combine es nativo de Apple (primera opción)
- RxSwift requiere dependencia externa
- Combine tiene mejor integración con SwiftUI

#### **Delegates / NotificationCenter**
```swift
// ❌ Código imperativo antiguo
protocol SearchViewModelDelegate: AnyObject {
    func didUpdateSearchResults(_ results: [GeocodingResult])
}

weak var delegate: SearchViewModelDelegate?

func searchCompleted() {
    delegate?.didUpdateSearchResults(results)
}
```

**Por qué se descartó:**
- Mucho más código
- Propenso a errores (weak references, retain cycles)
- No tiene operators como debounce

---

## Alamofire

### ¿Qué es Alamofire?

**Alamofire** es la librería de networking más popular para Swift, construida sobre URLSession pero con una API más elegante y features adicionales.

### Implementación en el Proyecto

```swift
// iosWeather/Services/NetworkService.swift
import Alamofire

final class NetworkService: NetworkServiceProtocol {
    private let session: Session

    init(session: Session = .default) {
        self.session = session
    }

    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse {
        let parameters: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "current": "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m",
            "timezone": "auto"
        ]

        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                "https://api.open-meteo.com/v1/forecast",
                method: .get,
                parameters: parameters
            )
            .validate()  // ← Valida status codes 200-299
            .responseDecodable(of: WeatherResponse.self) { response in
                switch response.result {
                case .success(let weatherResponse):
                    continuation.resume(returning: weatherResponse)
                case .failure(let error):
                    continuation.resume(throwing: NetworkError.networkError(error))
                }
            }
        }
    }
}
```

### Features Utilizadas

#### 1. **Automatic Codable Decoding**
```swift
.responseDecodable(of: WeatherResponse.self) { response in
    // Alamofire deserializa JSON → WeatherResponse automáticamente
    let weather = response.value
}
```

**Equivalente en URLSession:**
```swift
let (data, _) = try await URLSession.shared.data(from: url)
let decoder = JSONDecoder()
let weather = try decoder.decode(WeatherResponse.self, from: data)
// Más código manual
```

#### 2. **Request Validation**
```swift
.validate()  // Automáticamente falla si status code no es 200-299
```

**Sin validación:**
```swift
// Necesitarías validar manualmente
if let httpResponse = response as? HTTPURLResponse,
   !(200...299).contains(httpResponse.statusCode) {
    throw NetworkError.serverError(statusCode: httpResponse.statusCode)
}
```

#### 3. **Parameter Encoding**
```swift
let parameters: [String: Any] = [
    "latitude": 40.7128,
    "longitude": -74.0060,
    "current": "temperature_2m,weather_code"
]

session.request(url, method: .get, parameters: parameters)
// Alamofire codifica parámetros a query string automáticamente
// https://api.open-meteo.com/v1/forecast?latitude=40.7128&longitude=-74.0060&current=temperature_2m...
```

#### 4. **Session Customization**
```swift
// Posibilidad de inyectar sesión personalizada para testing
init(session: Session = .default) {
    self.session = session
}

// En tests, podemos usar una sesión mock
let mockSession = Session(interceptor: MockInterceptor())
let service = NetworkService(session: mockSession)
```

### Ventajas

1. **Menos Código Boilerplate**
   - Codificación/decodificación automática
   - Manejo de errores integrado
   - Validación con una línea

2. **Type Safety**
   - `responseDecodable(of: T.self)` es type-safe
   - Errores en compile-time, no runtime

3. **Mejor Manejo de Errores**
   ```swift
   case .failure(let error):
       if let statusCode = response.response?.statusCode {
           continuation.resume(throwing: NetworkError.serverError(statusCode: statusCode))
       } else if let decodingError = error.asAFError?.underlyingError {
           continuation.resume(throwing: NetworkError.decodingError(decodingError))
       }
   ```

4. **Testabilidad**
   - Session inyectable
   - Interceptors para mocking

### Alternativas Consideradas

#### **URLSession Puro**
```swift
// ✅ Pros: Nativo, sin dependencias
// ❌ Cons: Mucho más código boilerplate
func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse {
    var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
    components.queryItems = [
        URLQueryItem(name: "latitude", value: "\(latitude)"),
        URLQueryItem(name: "longitude", value: "\(longitude)"),
        // ... más parámetros
    ]

    guard let url = components.url else {
        throw NetworkError.invalidURL
    }

    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw NetworkError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
    }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    do {
        return try decoder.decode(WeatherResponse.self, from: data)
    } catch {
        throw NetworkError.decodingError(error)
    }
}
```

**Por qué se prefirió Alamofire:**
- Reduce 40+ líneas a ~15 líneas
- API más elegante y expresiva
- Features adicionales (retry, validation, interceptors)
- Mantiene la misma seguridad que URLSession

#### **Moya**
```swift
// Wrapper sobre Alamofire con pattern de TargetType
enum WeatherAPI {
    case fetchWeather(lat: Double, lon: Double)
}

extension WeatherAPI: TargetType {
    var baseURL: URL { ... }
    var path: String { ... }
    var method: Moya.Method { ... }
    var parameters: [String: Any]? { ... }
}
```

**Por qué se descartó:**
- Capa adicional de abstracción innecesaria
- Más complejo para un proyecto simple
- Alamofire directo es suficiente

#### **NSURLConnection (Deprecated)**
**Por qué se descartó:**
- Deprecated desde iOS 9
- API obsoleta

---

## Inyección de Dependencias Basada en Protocolos

### ¿Qué es Dependency Injection?

**Dependency Injection (DI)** es un patrón de diseño donde las dependencias de una clase se "inyectan" desde afuera en lugar de ser creadas internamente.

### Implementación: Protocol-Based DI

#### 1. **Definir Protocolos para Servicios**

```swift
// iosWeather/Services/NetworkService.swift
protocol NetworkServiceProtocol {
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse
    func searchCity(query: String) async throws -> [GeocodingResult]
}

// Implementación real
final class NetworkService: NetworkServiceProtocol {
    func fetchWeather(...) async throws -> WeatherResponse { ... }
    func searchCity(...) async throws -> [GeocodingResult] { ... }
}

// Mock para testing
final class MockNetworkService: NetworkServiceProtocol {
    var shouldFail = false
    var mockWeather: WeatherResponse?

    func fetchWeather(...) async throws -> WeatherResponse {
        if shouldFail { throw NetworkError.networkError(...) }
        return mockWeather!
    }
}
```

#### 2. **ViewModels Dependen de Protocolos, No de Implementaciones**

```swift
// ❌ MAL - Acoplamiento Fuerte
final class CurrentWeatherViewModel: ObservableObject {
    private let networkService = NetworkService()  // ← Hardcoded
    private let locationService = LocationService() // ← No testeable
}

// ✅ BIEN - Acoplamiento Débil
@MainActor
final class CurrentWeatherViewModel: ObservableObject {
    private let networkService: NetworkServiceProtocol  // ← Protocolo
    private let locationService: LocationServiceProtocol // ← Protocolo

    init(
        networkService: NetworkServiceProtocol,
        locationService: LocationServiceProtocol
    ) {
        self.networkService = networkService
        self.locationService = locationService
    }
}
```

#### 3. **Inyección desde la Vista**

```swift
// iosWeather/Views/MainTabView.swift
struct MainTabView: View {
    private let networkService: NetworkServiceProtocol
    private let locationService: LocationServiceProtocol
    private let storageService: StorageServiceProtocol

    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        locationService: LocationServiceProtocol = LocationService(),
        storageService: StorageServiceProtocol = StorageService()
    ) {
        // Servicios inyectados con valores por defecto
        self.networkService = networkService
        self.locationService = locationService
        self.storageService = storageService
    }

    var body: some View {
        TabView {
            CurrentWeatherView(
                viewModel: CurrentWeatherViewModel(
                    networkService: networkService,  // ← Inyección
                    locationService: locationService
                )
            )
        }
    }
}
```

### Ventajas

#### 1. **Testabilidad Total**
```swift
// iosWeatherTests/ViewModelTests/CurrentWeatherViewModelTests.swift
func testFetchWeatherSuccess() async {
    // Arrange - Crear mocks
    let mockNetwork = MockNetworkService()
    mockNetwork.mockWeather = WeatherResponse(...)

    let mockLocation = MockLocationService()
    mockLocation.mockCoordinates = LocationCoordinates(latitude: 40.7, longitude: -74.0)

    // Inyectar mocks
    let viewModel = CurrentWeatherViewModel(
        networkService: mockNetwork,
        locationService: mockLocation
    )

    // Act
    await viewModel.fetchCurrentLocationWeather()

    // Assert
    if case .loaded(let weather) = viewModel.state {
        XCTAssertEqual(weather.cityName, "Ubicación Actual")
    } else {
        XCTFail("Expected loaded state")
    }
}
```

**Sin DI:**
```swift
// ❌ No se puede testear sin hacer llamadas reales a la API
func testFetchWeather() async {
    let viewModel = CurrentWeatherViewModel()
    await viewModel.fetchWeather()
    // ← Esto hace llamadas HTTP reales, depende de internet, es lento
}
```

#### 2. **Flexibilidad y Reutilización**
```swift
// Producción
let prodViewModel = CurrentWeatherViewModel(
    networkService: NetworkService(),
    locationService: LocationService()
)

// Testing
let testViewModel = CurrentWeatherViewModel(
    networkService: MockNetworkService(),
    locationService: MockLocationService()
)

// Preview
let previewViewModel = CurrentWeatherViewModel(
    networkService: PreviewNetworkService(),
    locationService: PreviewLocationService()
)
```

#### 3. **Cumple SOLID Principles**

**S - Single Responsibility:**
- `NetworkService`: Solo networking
- `LocationService`: Solo geolocalización
- `CurrentWeatherViewModel`: Solo lógica de presentación

**O - Open/Closed:**
- Abierto a extensión (nuevas implementaciones de `NetworkServiceProtocol`)
- Cerrado a modificación (no necesitas cambiar el ViewModel)

**L - Liskov Substitution:**
- Cualquier implementación de `NetworkServiceProtocol` puede sustituir a otra

**I - Interface Segregation:**
- Protocolos pequeños y específicos

**D - Dependency Inversion:**
- Módulos de alto nivel (ViewModels) dependen de abstracciones (protocolos)
- Módulos de bajo nivel (Services) implementan abstracciones

### Alternativas Descartadas

#### **Singleton Pattern**
```swift
// ❌ Singleton - Anti-pattern para testing
class NetworkService {
    static let shared = NetworkService()
    private init() {}
}

// Uso
let weather = await NetworkService.shared.fetchWeather(...)

// Problema: No se puede mockear en tests
```

**Por qué se descartó:**
- Imposible de mockear
- Estado global mutable
- Dificulta el testing
- Viola SOLID principles

#### **Dependency Injection Frameworks (Swinject, Needle)**
```swift
// Framework de DI con containers
let container = Container()
container.register(NetworkServiceProtocol.self) { _ in NetworkService() }
let service = container.resolve(NetworkServiceProtocol.self)!
```

**Por qué se descartó:**
- Overhead innecesario para un proyecto pequeño
- Constructor injection manual es suficiente
- Más simple de entender sin framework

#### **Service Locator Pattern**
```swift
// ❌ Service Locator - Hidden dependencies
class ServiceLocator {
    static func getNetworkService() -> NetworkServiceProtocol {
        return NetworkService()
    }
}

// Uso
let service = ServiceLocator.getNetworkService()
```

**Por qué se descartó:**
- Dependencias ocultas (no visibles en el inicializador)
- Dificulta el testing
- Menos explícito que DI

---

## CoreLocation

### ¿Qué es CoreLocation?

**CoreLocation** es el framework de Apple para obtener información de geolocalización (GPS, Wi-Fi, celular).

### Implementación en el Proyecto

```swift
// iosWeather/Services/LocationService.swift
import CoreLocation

final class LocationService: NSObject, LocationServiceProtocol {
    private let locationManager: CLLocationManager
    private var locationContinuation: CheckedContinuation<LocationCoordinates, Error>?

    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func getCurrentLocation() async throws -> LocationCoordinates {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            requestPermission()
            throw LocationError.permissionDenied

        case .restricted, .denied:
            throw LocationError.permissionDenied

        case .authorizedAlways, .authorizedWhenInUse:
            return try await fetchLocation()

        @unknown default:
            throw LocationError.permissionDenied
        }
    }

    private func fetchLocation() async throws -> LocationCoordinates {
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()  // ← One-time location request
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            locationContinuation?.resume(throwing: LocationError.locationUnavailable)
            locationContinuation = nil
            return
        }

        let coordinates = LocationCoordinates(from: location)
        locationContinuation?.resume(returning: coordinates)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: LocationError.unknown(error))
        locationContinuation = nil
    }
}
```

### Flujo de Permisos

```
1. App solicita ubicación
   ↓
2. iOS muestra alert: "¿Permitir acceso a ubicación?"
   ↓
3. Usuario acepta/rechaza
   ↓
4. locationManager.authorizationStatus actualiza
   ↓
5. getCurrentLocation() verifica status
   ↓
6. Si autorizado: requestLocation()
   Si denegado: throw LocationError.permissionDenied
```

### Configuración de Info.plist

```xml
<!-- iosWeather.xcodeproj/project.pbxproj -->
INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "Necesitamos tu ubicación para mostrar el clima actual de tu zona";
INFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription = "Necesitamos tu ubicación para mostrar el clima actual de tu zona";
```

**Tipos de permisos:**
- `WhenInUse`: Solo cuando la app está en uso (✅ usado)
- `Always`: Incluso en background (❌ no necesario)

### Características Implementadas

#### 1. **Accuracy Configuration**
```swift
locationManager.desiredAccuracy = kCLLocationAccuracyBest
```

**Opciones disponibles:**
- `kCLLocationAccuracyBestForNavigation`: Máxima precisión (GPS + acelerómetro)
- `kCLLocationAccuracyBest`: Alta precisión (GPS) ← Usado
- `kCLLocationAccuracyNearestTenMeters`: ±10 metros
- `kCLLocationAccuracyHundredMeters`: ±100 metros (ahorra batería)
- `kCLLocationAccuracyKilometer`: ±1 km

**Por qué Best:**
- Weather data es más preciso con ubicación exacta
- Single request (no drena batería continuamente)

#### 2. **One-Time Location Request**
```swift
locationManager.requestLocation()  // ← No startUpdatingLocation()
```

**Diferencias:**
| Método | Uso | Batería |
|--------|-----|---------|
| `requestLocation()` | Una sola lectura | Bajo consumo ✅ |
| `startUpdatingLocation()` | Actualizaciones continuas | Alto consumo ❌ |

**Decisión:** `requestLocation()` porque solo necesitamos la ubicación una vez por fetch.

#### 3. **Async/Await Wrapping**
```swift
// CoreLocation usa delegate pattern (callbacks)
// Lo convertimos a async/await con Continuation
private func fetchLocation() async throws -> LocationCoordinates {
    return try await withCheckedThrowingContinuation { continuation in
        self.locationContinuation = continuation
        locationManager.requestLocation()
    }
}
```

### Alternativas Descartadas

#### **Geolocation API Manual (IP-based)**
```swift
// ❌ Menos preciso
// Ejemplo: ipapi.co devuelve ciudad, no coordenadas exactas
```

**Por qué se descartó:**
- Menos preciso (nivel de ciudad, no GPS)
- Requiere API adicional
- No usa capacidades nativas del dispositivo

#### **Third-Party Libraries (GoogleMaps, MapKit)**
**Por qué se descartó:**
- CoreLocation es suficiente para obtener coordenadas
- MapKit es para mapas, no para coordenadas simples
- GoogleMaps requiere API key y billing

---

## UserDefaults

### ¿Qué es UserDefaults?

**UserDefaults** es el sistema de persistencia key-value de iOS para datos pequeños y simples.

### Implementación en el Proyecto

```swift
// iosWeather/Services/StorageService.swift
final class StorageService: StorageServiceProtocol {
    private let userDefaults: UserDefaults
    private let searchHistoryKey = "search_history_key"
    private let maxHistoryItems = 20

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func saveSearchHistory(_ items: [SearchHistoryItem]) throws {
        let itemsToSave = Array(items.prefix(maxHistoryItems))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(itemsToSave)

        userDefaults.set(data, forKey: searchHistoryKey)
    }

    func loadSearchHistory() throws -> [SearchHistoryItem] {
        guard let data = userDefaults.data(forKey: searchHistoryKey) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let items = try decoder.decode([SearchHistoryItem].self, from: data)
        return items
    }

    func clearSearchHistory() throws {
        userDefaults.removeObject(forKey: searchHistoryKey)
    }
}
```

### Modelo de Datos Persistido

```swift
// iosWeather/Models/SearchHistory.swift
struct SearchHistoryItem: Codable, Identifiable {
    let id: UUID
    let cityName: String
    let latitude: Double
    let longitude: Double
    let searchDate: Date

    init(cityName: String, latitude: Double, longitude: Double) {
        self.id = UUID()
        self.cityName = cityName
        self.latitude = latitude
        self.longitude = longitude
        self.searchDate = Date()
    }
}
```

### Características

#### 1. **JSON Encoding/Decoding**
```swift
// Array de objetos complejos → Data → UserDefaults
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601  // "2024-01-15T10:30:00Z"
let data = try encoder.encode(items)
userDefaults.set(data, forKey: "key")
```

#### 2. **Limit de Items**
```swift
private let maxHistoryItems = 20

func saveSearchHistory(_ items: [SearchHistoryItem]) throws {
    // Solo guarda los primeros 20 items
    let itemsToSave = Array(items.prefix(maxHistoryItems))
    // ...
}
```

**Por qué 20:**
- Evita crecimiento infinito
- UserDefaults no es para datos grandes
- 20 búsquedas recientes es suficiente para UX

#### 3. **Dependency Injection para Testing**
```swift
init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
}

// En tests
let testDefaults = UserDefaults(suiteName: "TestSuite")!
let service = StorageService(userDefaults: testDefaults)

// Cleanup después del test
testDefaults.removePersistentDomain(forName: "TestSuite")
```

### Ventajas de UserDefaults

1. **Simplicidad**
   ```swift
   // Solo 3 líneas para guardar
   let data = try encoder.encode(items)
   userDefaults.set(data, forKey: "key")
   ```

2. **Sincronización Automática**
   - iOS sincroniza a disco automáticamente
   - No necesitas llamar `save()` o `commit()`

3. **Thread-Safe**
   - Puede ser accedido desde múltiples threads
   - iOS maneja locks internamente

4. **Persistencia entre Launches**
   - Datos sobreviven cierre de app
   - Sobreviven reinicio de dispositivo

### Alternativas Descartadas

#### **Core Data**
```swift
// ❌ Demasiado complejo para una simple lista
// Requiere: Managed Object Model, Context, Entity, Persistent Store
```

**Por qué se descartó:**
- Overhead masivo para solo 20 items
- Curva de aprendizaje elevada
- No necesitamos relaciones complejas
- No necesitamos queries complejas

#### **SQLite Directo**
```swift
// ❌ SQL queries manuales
let db = try Connection("path/to/db.sqlite3")
let history = Table("history")
try db.run(history.create { ... })
```

**Por qué se descartó:**
- Mucho más código que UserDefaults
- Necesita librería (SQLite.swift)
- No necesitamos queries complejas

#### **File System (JSON Files)**
```swift
// ❌ Manejo manual de archivos
let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
let fileURL = documentsDirectory.appendingPathComponent("history.json")
try data.write(to: fileURL)
```

**Por qué se descartó:**
- Más código que UserDefaults
- Necesitas manejar file paths
- Necesitas manejar errores de I/O
- UserDefaults hace esto automáticamente

#### **Keychain**
**Por qué se descartó:**
- Keychain es para datos sensibles (contraseñas, tokens)
- Search history no es sensible
- UserDefaults es más simple

### Limitaciones de UserDefaults

**Cuándo NO usar UserDefaults:**
- Datos > 1 MB (usar File System o Core Data)
- Datos sensibles (usar Keychain)
- Relaciones complejas (usar Core Data)
- Queries complejas (usar SQLite/Core Data)

**En nuestro caso:**
- ✅ Datos pequeños (20 items × ~200 bytes = 4 KB)
- ✅ No sensibles (búsquedas públicas)
- ✅ Sin relaciones
- ✅ Sin queries

---

## XCTest y Testing

### ¿Qué es XCTest?

**XCTest** es el framework nativo de Apple para unit testing, UI testing, y performance testing.

### Estrategia de Testing en el Proyecto

```
Tests Implementados:
├── Mocks/
│   ├── MockNetworkService.swift     (Mock con factory methods)
│   ├── MockLocationService.swift    (Mock configurable)
│   └── MockStorageService.swift     (In-memory storage)
│
└── ViewModelTests/
    ├── CurrentWeatherViewModelTests.swift  (6 tests)
    ├── SearchViewModelTests.swift          (5 tests)
    └── HistoryViewModelTests.swift         (6 tests)

Total: 17 unit tests
```

### Implementación de Mocks

#### 1. **MockNetworkService**
```swift
// iosWeatherTests/Mocks/MockNetworkService.swift
final class MockNetworkService: NetworkServiceProtocol {
    // Control de comportamiento
    var shouldFail = false
    var errorToThrow: Error?

    // Datos mock
    var mockWeatherResponse: WeatherResponse?
    var mockGeocodingResults: [GeocodingResult] = []

    // Tracking de llamadas
    var fetchWeatherCallCount = 0
    var lastFetchWeatherLatitude: Double?
    var lastFetchWeatherLongitude: Double?

    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse {
        fetchWeatherCallCount += 1
        lastFetchWeatherLatitude = latitude
        lastFetchWeatherLongitude = longitude

        if shouldFail {
            throw errorToThrow ?? NetworkError.networkError(NSError(domain: "", code: -1))
        }

        return mockWeatherResponse ?? MockNetworkService.createMockWeatherResponse()
    }

    // Factory method para datos de prueba
    static func createMockWeatherResponse(
        temperature: Double = 22.5,
        weatherCode: Int = 0
    ) -> WeatherResponse {
        WeatherResponse(
            latitude: 40.7128,
            longitude: -74.0060,
            timezone: "America/New_York",
            current: CurrentWeather(
                time: "2024-01-15T12:00:00",
                temperature: temperature,
                weatherCode: weatherCode,
                windSpeed: 15.0,
                humidity: 65
            )
        )
    }
}
```

**Características:**
- ✅ Control total sobre comportamiento (success/failure)
- ✅ Tracking de llamadas (verificar que se llamó con parámetros correctos)
- ✅ Factory methods para crear datos de prueba fácilmente

#### 2. **MockLocationService**
```swift
final class MockLocationService: LocationServiceProtocol {
    var shouldFail = false
    var errorToThrow: Error?
    var mockCoordinates: LocationCoordinates?
    var getCurrentLocationCallCount = 0

    var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse

    func getCurrentLocation() async throws -> LocationCoordinates {
        getCurrentLocationCallCount += 1

        if shouldFail {
            throw errorToThrow ?? LocationError.locationUnavailable
        }

        return mockCoordinates ?? LocationCoordinates(latitude: 40.7128, longitude: -74.0060)
    }

    func requestPermission() {
        // No-op en tests
    }
}
```

### Ejemplo de Tests

#### **Test de Estado Loading**
```swift
// iosWeatherTests/ViewModelTests/CurrentWeatherViewModelTests.swift
@MainActor
final class CurrentWeatherViewModelTests: XCTestCase {

    func testFetchWeather_Success() async {
        // Arrange
        let mockNetwork = MockNetworkService()
        mockNetwork.mockWeatherResponse = MockNetworkService.createMockWeatherResponse(
            temperature: 25.0,
            weatherCode: 0
        )

        let mockLocation = MockLocationService()
        mockLocation.mockCoordinates = LocationCoordinates(latitude: 40.7, longitude: -74.0)

        let viewModel = CurrentWeatherViewModel(
            networkService: mockNetwork,
            locationService: mockLocation
        )

        // Act
        await viewModel.fetchCurrentLocationWeather()

        // Assert
        if case .loaded(let weather) = viewModel.state {
            XCTAssertEqual(weather.temperature, 25.0)
            XCTAssertEqual(weather.cityName, "Ubicación Actual")
            XCTAssertEqual(weather.description, "Cielo despejado")
        } else {
            XCTFail("Expected loaded state, got \(viewModel.state)")
        }

        // Verify service calls
        XCTAssertEqual(mockNetwork.fetchWeatherCallCount, 1)
        XCTAssertEqual(mockLocation.getCurrentLocationCallCount, 1)
    }

    func testFetchWeather_NetworkError() async {
        // Arrange
        let mockNetwork = MockNetworkService()
        mockNetwork.shouldFail = true
        mockNetwork.errorToThrow = NetworkError.networkError(NSError(domain: "", code: -1))

        let mockLocation = MockLocationService()

        let viewModel = CurrentWeatherViewModel(
            networkService: mockNetwork,
            locationService: mockLocation
        )

        // Act
        await viewModel.fetchCurrentLocationWeather()

        // Assert
        if case .error(let message) = viewModel.state {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected error state")
        }
    }

    func testFetchWeather_LocationPermissionDenied() async {
        // Arrange
        let mockNetwork = MockNetworkService()

        let mockLocation = MockLocationService()
        mockLocation.shouldFail = true
        mockLocation.errorToThrow = LocationError.permissionDenied

        let viewModel = CurrentWeatherViewModel(
            networkService: mockNetwork,
            locationService: mockLocation
        )

        // Act
        await viewModel.fetchCurrentLocationWeather()

        // Assert
        XCTAssertTrue(viewModel.showLocationPermissionAlert)

        if case .error = viewModel.state {
            // Expected error state
        } else {
            XCTFail("Expected error state")
        }
    }
}
```

### Cobertura de Tests

| ViewModel | Tests | Escenarios Cubiertos |
|-----------|-------|---------------------|
| **CurrentWeatherViewModel** | 6 | Success, Network Error, Location Error, Permission Denied, Refresh, Initial State |
| **SearchViewModel** | 5 | Search Success, Empty Query, Network Error, Clear Weather, Debouncing |
| **HistoryViewModel** | 6 | Load History, Fetch Weather for Item, Delete Item, Clear All, Storage Error, Empty State |

### Ventajas del Approach de Testing

#### 1. **Tests Rápidos**
```swift
// ✅ 0.001 segundos por test (en memoria)
// ❌ 2+ segundos si hiciera llamadas HTTP reales
```

#### 2. **Tests Determinísticos**
```swift
// ✅ Siempre retorna el mismo resultado
mockNetwork.mockWeatherResponse = createMock(temperature: 25.0)

// ❌ Resultado cambia cada vez si usa API real
```

#### 3. **Tests de Error Paths**
```swift
// Fácil de testear escenarios de error
mockNetwork.shouldFail = true
mockNetwork.errorToThrow = NetworkError.serverError(statusCode: 500)

// Imposible de replicar consistentemente con API real
```

#### 4. **Aislamiento Total**
```swift
// Cada test es independiente
func testA() {
    let mock = MockNetworkService()
    // ...
}

func testB() {
    let mock = MockNetworkService() // ← Nuevo mock, sin estado compartido
    // ...
}
```

### Alternativas Descartadas

#### **UI Tests**
```swift
// ❌ XCTest UI Testing
func testWeatherViewDisplaysCorrectly() throws {
    let app = XCUIApplication()
    app.launch()

    let weatherLabel = app.staticTexts["weatherLabel"]
    XCTAssert(weatherLabel.waitForExistence(timeout: 5))
}
```

**Por qué se descartó para este proyecto:**
- Mucho más lentos (segundos vs milisegundos)
- Frágiles (cambios en UI rompen tests)
- Difíciles de debuggear
- Unit tests dan más ROI para ViewModels

**Cuándo usar UI tests:**
- Flows críticos end-to-end
- Apps de producción grandes
- Regression testing

#### **Snapshot Testing**
```swift
// Librería: SnapshotTesting
func testWeatherViewSnapshot() {
    let view = CurrentWeatherView(viewModel: ...)
    assertSnapshot(matching: view, as: .image)
}
```

**Por qué se descartó:**
- Requiere librería de terceros
- Snapshots son archivos grandes en el repo
- Difícil mantener en proyectos pequeños

#### **Quick/Nimble (BDD Testing)**
```swift
// ❌ Framework de BDD
describe("CurrentWeatherViewModel") {
    context("when fetching weather") {
        it("should update state to loaded") {
            // ...
        }
    }
}
```

**Por qué se descartó:**
- XCTest nativo es suficiente
- Dependencia adicional innecesaria
- Sintaxis de XCTest es estándar

---

## Swift Package Manager

### ¿Qué es SPM?

**Swift Package Manager (SPM)** es el gestor de dependencias nativo de Swift, integrado en Xcode.

### Dependencias del Proyecto

```swift
// iosWeather.xcodeproj/project.pbxproj
// Package Dependencies configuradas en Xcode

dependencies = (
    {
        package = {
            repositoryURL = "https://github.com/Alamofire/Alamofire.git";
            requirement = {
                kind = upToNextMajorVersion;
                minimumVersion = 5.9.1;
            };
        };
        productName = Alamofire;
    },
);
```

### Dependencias Instaladas

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| **Alamofire** | 5.9.1+ | HTTP Networking |

**Nota:** Kingfisher fue removido ya que Open-Meteo API no requiere imágenes.

### Ventajas de SPM

#### 1. **Integración Nativa**
```
File → Add Package Dependencies...
    ↓
Pegar URL del repo
    ↓
Select version
    ↓
Add to Target
    ↓
import Alamofire // ← Listo
```

#### 2. **Declarativo**
```swift
// Package.swift (para librerías)
let package = Package(
    name: "MyLibrary",
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.9.1")
    ]
)
```

#### 3. **Versionado Semántico**
```
"5.9.1" significa:
Major.Minor.Patch

upToNextMajor: 5.9.1 → <6.0.0
upToNextMinor: 5.9.1 → <5.10.0
exact: Solo 5.9.1
```

#### 4. **No Requiere Archivos de Configuración Extra**
- No `Podfile` (CocoaPods)
- No `Cartfile` (Carthage)
- Todo en `.xcodeproj`

### Gestión de Versiones

```swift
// Alamofire 5.9.1 instalado
// Xcode verifica actualizaciones automáticamente

// Para actualizar:
File → Package Dependencies → Update to Latest Package Versions
```

### Alternativas Descartadas

#### **CocoaPods**
```ruby
# ❌ Podfile
platform :ios, '17.0'
use_frameworks!

target 'iosWeather' do
  pod 'Alamofire', '~> 5.9'
end
```

```bash
# Instalación
gem install cocoapods
pod install
# Ahora debes usar iosWeather.xcworkspace en lugar de .xcodeproj
```

**Por qué se descartó:**
- Requiere Ruby y CocoaPods instalado
- Genera archivos adicionales (Podfile.lock, Pods/)
- Crea .xcworkspace (confuso para principiantes)
- SPM es el futuro (Apple lo soporta nativamente)

#### **Carthage**
```
# ❌ Cartfile
github "Alamofire/Alamofire" ~> 5.9
```

```bash
# Instalación
brew install carthage
carthage update --platform iOS
# Manualmente añadir frameworks a Xcode
```

**Por qué se descartó:**
- Proceso de setup manual
- No integrado en Xcode
- Menor popularidad que SPM/CocoaPods

#### **Manual (Download & Drag)**
**Por qué se descartó:**
- Difícil de actualizar
- No maneja dependencias transitivas
- Propenso a errores

### Comparación

| Feature | SPM | CocoaPods | Carthage |
|---------|-----|-----------|----------|
| Integración Xcode | ✅ Nativa | ❌ xcworkspace | ❌ Manual |
| Velocidad | ✅ Rápida | ❌ Lenta | ✅ Rápida |
| Setup | ✅ GUI | ❌ CLI | ❌ CLI + Manual |
| Futuro | ✅ Apple lo mejora | ⚠️ Community | ❌ Menos usado |

**Decisión:** SPM porque es nativo, simple, y el futuro de Swift.

---

## Open-Meteo API

### ¿Qué es Open-Meteo?

**Open-Meteo** es una API de clima gratuita y de código abierto que NO requiere API key.

### Endpoints Utilizados

#### 1. **Weather Forecast API**
```
GET https://api.open-meteo.com/v1/forecast
```

**Parámetros:**
```swift
let parameters: [String: Any] = [
    "latitude": 40.7128,
    "longitude": -74.0060,
    "current": "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m",
    "timezone": "auto"
]
```

**Respuesta:**
```json
{
  "latitude": 40.7128,
  "longitude": -74.0060,
  "timezone": "America/New_York",
  "current": {
    "time": "2024-01-15T12:00:00",
    "temperature_2m": 22.5,
    "relative_humidity_2m": 65,
    "weather_code": 0,
    "wind_speed_10m": 15.3
  }
}
```

#### 2. **Geocoding API**
```
GET https://geocoding-api.open-meteo.com/v1/search
```

**Parámetros:**
```swift
let parameters: [String: Any] = [
    "name": "New York",
    "count": 10,
    "language": "en",
    "format": "json"
]
```

**Respuesta:**
```json
{
  "results": [
    {
      "id": 5128581,
      "name": "New York",
      "latitude": 40.71427,
      "longitude": -74.00597,
      "country": "United States",
      "admin1": "New York"
    }
  ]
}
```

### Mapeo de Weather Codes

```swift
// WMO Weather interpretation codes
// https://open-meteo.com/en/docs

0: Cielo despejado
1: Mayormente despejado
2: Parcialmente nublado
3: Nublado
45, 48: Niebla
51, 53, 55: Llovizna
61, 63, 65: Lluvia
71, 73, 75: Nieve
77: Granizo
80, 81, 82: Chubascos
85, 86: Nevadas
95: Tormenta
96, 99: Tormenta con granizo
```

### Ventajas de Open-Meteo

#### 1. **Sin API Key**
```swift
// ✅ No necesitas registrarte
session.request("https://api.open-meteo.com/v1/forecast", parameters: params)

// ❌ Otras APIs requieren key
session.request("https://api.openweathermap.org/data/2.5/weather?appid=YOUR_KEY", ...)
```

#### 2. **Gratis y Sin Límites (uso razonable)**
- No rate limits estrictos
- No billing
- Perfecto para desarrollo y proyectos personales

#### 3. **Datos Precisos**
- Usa múltiples fuentes (NOAA, DWD, etc.)
- Actualización frecuente
- Cobertura global

#### 4. **RESTful y JSON**
```swift
// Respuesta simple de parsear
struct WeatherResponse: Codable {
    let latitude: Double
    let longitude: Double
    let current: CurrentWeather
}
```

#### 5. **Documentación Excelente**
- Interactive API docs
- Ejemplos en múltiples lenguajes
- WMO weather codes explicados

### Alternativas Descartadas

#### **OpenWeatherMap**
```
GET https://api.openweathermap.org/data/2.5/weather?q=London&appid=YOUR_API_KEY
```

**Por qué se descartó:**
- ❌ Requiere API key (proceso de registro)
- ❌ Free tier limitado (60 calls/minute, 1M calls/month)
- ❌ Requiere billing info para production
- ✅ Más popular (pero no necesario para MVP)

#### **WeatherAPI.com**
```
GET https://api.weatherapi.com/v1/current.json?key=YOUR_KEY&q=London
```

**Por qué se descartó:**
- ❌ Requiere API key
- ❌ Free tier: solo 1M calls/month
- ❌ Billing necesario para más

#### **Apple WeatherKit**
```swift
import WeatherKit

let weather = try await WeatherService.shared.weather(for: location)
```

**Por qué se descartó:**
- ❌ Requiere Apple Developer Program ($99/año)
- ❌ Solo iOS 16+
- ❌ 500,000 calls/month (después pagar)
- ❌ Requiere entitlements y configuración compleja

#### **AccuWeather**
**Por qué se descartó:**
- ❌ API key requerida
- ❌ Free tier muy limitado (50 calls/day)
- ❌ Expensive para más calls

### Comparación

| API | API Key | Free Tier | Límites | Setup |
|-----|---------|-----------|---------|-------|
| **Open-Meteo** | ❌ No | ✅ Unlimited* | ✅ Uso razonable | ✅ Inmediato |
| OpenWeatherMap | ✅ Sí | 60/min, 1M/mes | ⚠️ Medio | ⚠️ Registro |
| WeatherAPI | ✅ Sí | 1M/mes | ⚠️ Medio | ⚠️ Registro |
| WeatherKit | ✅ Sí (+ $99/año) | 500k/mes | ❌ Bajo | ❌ Complejo |
| AccuWeather | ✅ Sí | 50/día | ❌ Muy bajo | ⚠️ Registro |

**Decisión:** Open-Meteo porque es la opción más simple para un MVP educativo.

---

## Decisiones de Diseño y Alternativas

### Resumen de Decisiones Arquitectónicas

| Decisión | Elegido | Alternativas Consideradas | Razón |
|----------|---------|---------------------------|-------|
| **Arquitectura** | MVVM | MVC, VIPER, TCA | Balance entre simplicidad y separación de responsabilidades |
| **UI Framework** | SwiftUI | UIKit | Declarativo, menos código, futuro de iOS |
| **Concurrencia** | Async/Await | Callbacks, RxSwift | Código legible, estándar de Swift |
| **Reactive Binding** | Combine | RxSwift | Nativo, integración con SwiftUI |
| **Networking** | Alamofire | URLSession, Moya | Menos boilerplate, API elegante |
| **DI Pattern** | Protocol-based | Singleton, Frameworks | Testeable, SOLID principles |
| **Geolocalización** | CoreLocation | IP-based API | Preciso, nativo |
| **Persistencia** | UserDefaults | Core Data, SQLite | Simple para datos pequeños |
| **Testing** | XCTest + Mocks | UI Tests, Snapshot | Rápido, determinístico |
| **Gestor Deps** | SPM | CocoaPods, Carthage | Nativo, simple |
| **Weather API** | Open-Meteo | OpenWeatherMap, WeatherKit | Sin API key, gratis |

### Principios Aplicados

#### 1. **SOLID Principles**
```swift
// S - Single Responsibility
NetworkService // Solo networking
LocationService // Solo geolocalización
StorageService // Solo persistencia

// O - Open/Closed
protocol NetworkServiceProtocol // Abierto a extensión
final class NetworkService: NetworkServiceProtocol // Cerrado a modificación

// L - Liskov Substitution
MockNetworkService: NetworkServiceProtocol // Puede reemplazar a NetworkService

// I - Interface Segregation
protocol NetworkServiceProtocol // Solo métodos necesarios
protocol LocationServiceProtocol // Interfaz mínima

// D - Dependency Inversion
CurrentWeatherViewModel depende de NetworkServiceProtocol (abstracción)
No depende de NetworkService (implementación concreta)
```

#### 2. **DRY (Don't Repeat Yourself)**
```swift
// Componentes reutilizables
LoadingView(message: "Cargando...")
ErrorView(message: error) { retry() }
WeatherCardView(weather: weather)

// Usado en 3 vistas diferentes sin duplicar código
```

#### 3. **KISS (Keep It Simple, Stupid)**
```swift
// Preferir soluciones simples
UserDefaults // vs Core Data para 20 items
Protocol-based DI // vs DI Framework
```

#### 4. **YAGNI (You Aren't Gonna Need It)**
```swift
// No implementado porque no es necesario:
// - Offline caching
// - Push notifications
// - Background refresh
// - Widget
// - Watch app
// - Favoritos con sync
// - Compartir en redes sociales
```

### Escalabilidad Futura

Si el proyecto crece, estas son las migraciones recomendadas:

#### **De UserDefaults a Core Data**
```swift
// Cuando:
// - Más de 100 items de historial
// - Necesitas búsquedas complejas
// - Necesitas relaciones entre entidades

// Migración:
1. Crear Core Data model
2. Implementar CoreDataStorageService: StorageServiceProtocol
3. Migrar datos de UserDefaults a Core Data
4. Inyectar nuevo service (sin cambiar ViewModels)
```

#### **De Open-Meteo a API Comercial**
```swift
// Cuando:
// - Necesitas forecasts de 14 días
// - Necesitas alertas meteorológicas
// - Necesitas datos históricos

// Migración:
1. Crear WeatherKitService: NetworkServiceProtocol
2. Implementar métodos con WeatherKit
3. Inyectar nuevo service
4. ViewModels no cambian (gracias a protocols)
```

#### **De MVVM a TCA (si crece mucho)**
```swift
// Cuando:
// - App tiene 20+ pantallas
// - Estado compartido complejo
// - Necesitas time-travel debugging

// Migración gradual:
1. Empezar con nuevas features en TCA
2. Mantener MVVM en features existentes
3. Migrar progresivamente
```

---

## Conclusión

Este proyecto demuestra las **best practices de desarrollo iOS moderno**:

1. ✅ **Arquitectura limpia**: MVVM con clara separación de responsabilidades
2. ✅ **Código testeable**: 100% de ViewModels cubiertos con tests
3. ✅ **Tecnologías modernas**: SwiftUI + Async/Await + Combine
4. ✅ **Principios SOLID**: Dependency injection, protocolos, single responsibility
5. ✅ **Simplicidad**: Elegir la herramienta correcta para cada problema
6. ✅ **Escalabilidad**: Arquitectura preparada para crecer

### Stack Tecnológico Final

```
┌─────────────────────────────────────────────┐
│              SwiftUI Views                  │ ← Declarativo, reactivo
├─────────────────────────────────────────────┤
│           ViewModels (@MainActor)           │ ← Lógica de presentación
│         (Combine @Published)                │ ← Binding reactivo
├─────────────────────────────────────────────┤
│  Services (Protocol-based DI)               │
│  ├─ NetworkService (Alamofire)              │ ← HTTP networking
│  ├─ LocationService (CoreLocation)          │ ← GPS
│  └─ StorageService (UserDefaults)           │ ← Persistencia
├─────────────────────────────────────────────┤
│  Models (Codable)                           │ ← Datos
├─────────────────────────────────────────────┤
│  External APIs                              │
│  └─ Open-Meteo (REST JSON)                  │ ← Weather data
├─────────────────────────────────────────────┤
│  Testing (XCTest + Mocks)                   │ ← Quality assurance
├─────────────────────────────────────────────┤
│  Dependencies (SPM)                         │
│  └─ Alamofire 5.9.1                         │
└─────────────────────────────────────────────┘
```

### Tiempo de Desarrollo Estimado

- Arquitectura y setup: 2 horas
- Implementación de features: 6 horas
- Testing: 2 horas
- Documentación: 2 horas
- **Total: ~12 horas** de desarrollo para un MVP completo y profesional

### Recursos de Aprendizaje

- **MVVM**: [Apple's Data Flow](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)
- **SwiftUI**: [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- **Async/Await**: [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- **Combine**: [Combine Framework](https://developer.apple.com/documentation/combine)
- **Alamofire**: [Alamofire Documentation](https://github.com/Alamofire/Alamofire)
- **Testing**: [XCTest](https://developer.apple.com/documentation/xctest)

---

**Documento creado por:** Claude Code
**Fecha:** 2024
**Versión del Proyecto:** 1.0
**iOS Target:** 17.0+
**Swift Version:** 5.9+
