# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**iOSWeather** is an iOS weather application MVP built with SwiftUI following Senior-level best practices. The app demonstrates clean architecture, dependency injection, and comprehensive testing.

### Key Features
- Current weather based on GPS location
- City search with autocomplete
- Search history with persistence
- Offline-first architecture with local caching

### Technology Stack
- **UI Framework**: SwiftUI
- **Language**: Swift (async/await, Combine)
- **Architecture**: MVVM with protocol-based dependency injection
- **Weather API**: Open-Meteo API (free, no API key required)
- **Dependencies**: Alamofire (networking), Kingfisher (image caching)
- **Package Manager**: Swift Package Manager (SPM)
- **Testing**: XCTest with mock implementations

## Setup Instructions

### 1. Add Swift Package Dependencies

The project requires two SPM packages. Add them through Xcode:

**Alamofire** (Networking):
1. File → Add Package Dependencies
2. Enter: `https://github.com/Alamofire/Alamofire.git`
3. Version: Up to Next Major 5.0.0
4. Add to target: `iosWeather`

**Kingfisher** (Image Loading):
1. File → Add Package Dependencies
2. Enter: `https://github.com/onevcat/Kingfisher.git`
3. Version: Up to Next Major 7.0.0
4. Add to target: `iosWeather`

### 2. Configure Info.plist

Ensure `Info.plist` contains location permissions (already configured):
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`

### 3. Build and Run

```bash
open iosWeather.xcodeproj
# Then Cmd+R in Xcode
```

Or via command line:
```bash
xcodebuild -project iosWeather.xcodeproj -scheme iosWeather -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## Architecture

### MVVM Pattern

The project follows clean MVVM architecture:

```
View → ViewModel → Service → API/Storage
  ↓         ↓          ↓
SwiftUI  @Published  Protocol
```

**Key Principles**:
- Views are dumb and declarative
- ViewModels contain all business logic
- Services are protocol-based for dependency injection
- All dependencies can be mocked for testing

### Project Structure

```
iosWeather/
├── Models/                     # Data models (Codable)
│   ├── WeatherData.swift       # API response models
│   ├── Location.swift          # Location & geocoding models
│   └── SearchHistory.swift     # Persistence models
│
├── Services/                   # Business logic layer
│   ├── NetworkService.swift    # Alamofire wrapper (protocol-based)
│   ├── LocationService.swift   # CoreLocation wrapper
│   └── StorageService.swift    # UserDefaults persistence
│
├── ViewModels/                 # MVVM ViewModels
│   ├── CurrentWeatherViewModel.swift
│   ├── SearchViewModel.swift
│   └── HistoryViewModel.swift
│
├── Views/                      # SwiftUI views
│   ├── MainTabView.swift       # Tab navigation
│   ├── CurrentWeatherView.swift
│   ├── SearchView.swift
│   ├── HistoryView.swift
│   └── Components/             # Reusable components
│       ├── WeatherCardView.swift
│       └── LoadingView.swift
│
└── iosWeatherApp.swift         # App entry point

iosWeatherTests/
├── Mocks/                      # Protocol implementations for testing
│   ├── MockNetworkService.swift
│   ├── MockLocationService.swift
│   └── MockStorageService.swift
│
└── ViewModelTests/             # Unit tests (XCTest)
    ├── CurrentWeatherViewModelTests.swift
    ├── SearchViewModelTests.swift
    └── HistoryViewModelTests.swift
```

### Dependency Injection

All services use protocol-based DI:

```swift
// Protocol definition
protocol NetworkServiceProtocol {
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse
}

// Production implementation
class NetworkService: NetworkServiceProtocol { ... }

// Mock implementation
class MockNetworkService: NetworkServiceProtocol { ... }

// ViewModel injection
class CurrentWeatherViewModel {
    init(networkService: NetworkServiceProtocol) { ... }
}
```

### State Management

ViewModels use `ViewState` enum for UI state:

```swift
enum ViewState: Equatable {
    case idle
    case loading
    case loaded(WeatherDisplayModel)
    case error(String)
}
```

Views react to state changes via `@Published` properties.

### API Integration

**Open-Meteo API** endpoints:
- Weather: `https://api.open-meteo.com/v1/forecast`
- Geocoding: `https://geocoding-api.open-meteo.com/v1/search`

No API key required. All requests are GET with query parameters.

### Data Persistence

Search history is stored in `UserDefaults` as JSON:
- Max 20 items
- Sorted by date (newest first)
- Duplicates are moved to top

## Testing

### Test Framework

**XCTest** is used for unit tests (not Swift Testing for test files).

### Run Tests

**All tests:**
```bash
xcodebuild test -project iosWeather.xcodeproj -scheme iosWeather -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Specific test file:**
```bash
xcodebuild test -project iosWeather.xcodeproj -scheme iosWeather -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:iosWeatherTests/CurrentWeatherViewModelTests
```

**Single test method:**
```bash
xcodebuild test -project iosWeather.xcodeproj -scheme iosWeather -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:iosWeatherTests/CurrentWeatherViewModelTests/testFetchCurrentLocationWeather_Success
```

### Testing Strategy

- **Unit Tests**: All ViewModels have comprehensive test coverage
- **Mock Services**: Protocol-based mocks for all external dependencies
- **Test Coverage**: Loading states, success cases, error handling

### Writing Tests

Example test structure:

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
        // Given: Mock configured
        mockNetworkService.weatherResponse = MockNetworkService.createMockWeatherResponse()

        // When: Action performed
        await sut.fetchCurrentLocationWeather()

        // Then: Assertions
        XCTAssertEqual(sut.state, .loaded(...))
    }
}
```

## Common Development Tasks

### Adding a New Feature

1. **Create Model** in `Models/` if needed (must be `Codable` for API models)
2. **Update Service** protocol and implementation in `Services/`
3. **Create ViewModel** in `ViewModels/` with `@Published` state
4. **Build View** in `Views/` that observes ViewModel
5. **Create Mock** in `iosWeatherTests/Mocks/`
6. **Write Tests** in `iosWeatherTests/ViewModelTests/`

### Modifying API Integration

All network calls go through `NetworkService.swift`. The service uses Alamofire and converts callbacks to async/await.

To add a new endpoint:
1. Add method to `NetworkServiceProtocol`
2. Implement in `NetworkService` using Alamofire
3. Add mock implementation to `MockNetworkService`

### Adding New Dependencies

Use SPM only. Add through Xcode:
1. File → Add Package Dependencies
2. Enter repository URL
3. Select version rules
4. Add to appropriate targets

## Code Style

- Use `async/await` for asynchronous operations
- Use `Combine` only for reactive UI bindings
- All ViewModels must be `@MainActor`
- Use `private(set)` for published properties
- Protocol names end with `Protocol` suffix
- Mock classes start with `Mock` prefix

## Troubleshooting

### Location Permission Issues
- Ensure `Info.plist` has location usage descriptions
- Check system Settings → Privacy → Location Services
- Reset simulator: Device → Erase All Content and Settings

### SPM Dependencies Not Found
- File → Packages → Reset Package Caches
- File → Packages → Resolve Package Versions
- Clean build folder: Cmd+Shift+K

### Tests Failing
- Ensure tests are run on main actor: `@MainActor`
- Check mock configurations in `setUp()`
- Verify async operations use `await`
