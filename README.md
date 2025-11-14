# iOSWeather ☀️

A production-ready iOS weather application MVP demonstrating Senior-level iOS development practices with SwiftUI, MVVM architecture, and comprehensive testing.

## Features

- **Current Weather**: Real-time weather based on GPS location using CoreLocation
- **City Search**: Search any city worldwide with autocomplete suggestions
- **Search History**: Automatic saving and management of search history
- **Clean Architecture**: MVVM pattern with protocol-based dependency injection
- **Comprehensive Testing**: Unit tests for all ViewModels with mock implementations

## Screenshots

The app includes three main tabs:
1. **Current**: Shows weather for your current GPS location
2. **Search**: Search for any city and view its weather
3. **History**: Access your previous searches

## Technology Stack

- **iOS 15.0+**
- **SwiftUI** - Declarative UI framework
- **Swift** - Modern concurrency with async/await
- **Combine** - Reactive programming for UI bindings
- **Alamofire** - Elegant HTTP networking
- **Kingfisher** - Asynchronous image downloading and caching
- **XCTest** - Unit testing framework

## Architecture

### MVVM Pattern

```
┌─────────────────────────────────────────────┐
│              View Layer (SwiftUI)           │
│  CurrentWeatherView │ SearchView │ History  │
└───────────────┬─────────────────────────────┘
                │ @Published
┌───────────────▼─────────────────────────────┐
│           ViewModel Layer                   │
│  CurrentWeatherVM │ SearchVM │ HistoryVM    │
└───────────────┬─────────────────────────────┘
                │ Protocol Injection
┌───────────────▼─────────────────────────────┐
│           Service Layer                     │
│  NetworkService │ LocationService │ Storage │
└───────────────┬─────────────────────────────┘
                │
┌───────────────▼─────────────────────────────┐
│        External Dependencies                │
│  Open-Meteo API │ CoreLocation │ UserDefaults│
└─────────────────────────────────────────────┘
```

### Key Principles

- **Separation of Concerns**: Each layer has a single responsibility
- **Dependency Injection**: Protocol-based DI for testability
- **Reactive UI**: SwiftUI views react to ViewModel state changes
- **Error Handling**: Comprehensive error handling at all layers
- **Async/Await**: Modern Swift concurrency throughout

## Setup Instructions

### Prerequisites

- macOS Ventura 13.0+ (for Xcode 15)
- Xcode 15.0+
- iOS Simulator or physical device running iOS 15.0+

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd iosWeather
   ```

2. **Open the project in Xcode**
   ```bash
   open iosWeather.xcodeproj
   ```

3. **Add Swift Package Dependencies**

   The project requires two SPM packages. In Xcode:

   **a) Add Alamofire:**
   - File → Add Package Dependencies
   - Enter URL: `https://github.com/Alamofire/Alamofire.git`
   - Dependency Rule: Up to Next Major Version 5.0.0
   - Add to target: `iosWeather`

   **b) Add Kingfisher:**
   - File → Add Package Dependencies
   - Enter URL: `https://github.com/onevcat/Kingfisher.git`
   - Dependency Rule: Up to Next Major Version 7.0.0
   - Add to target: `iosWeather`

4. **Build and Run**
   - Select a simulator (e.g., iPhone 15)
   - Press `Cmd+R` or click the Run button
   - Grant location permissions when prompted

## Project Structure

```
iosWeather/
├── Models/                         # Data models
│   ├── WeatherData.swift           # Weather API response models
│   ├── Location.swift              # Location and geocoding models
│   └── SearchHistory.swift         # Search history persistence model
│
├── Services/                       # Business logic layer
│   ├── NetworkService.swift        # Alamofire-based API client
│   ├── LocationService.swift       # CoreLocation wrapper
│   └── StorageService.swift        # UserDefaults persistence
│
├── ViewModels/                     # MVVM ViewModels
│   ├── CurrentWeatherViewModel.swift
│   ├── SearchViewModel.swift
│   └── HistoryViewModel.swift
│
├── Views/                          # SwiftUI views
│   ├── MainTabView.swift           # Tab navigation
│   ├── CurrentWeatherView.swift
│   ├── SearchView.swift
│   ├── HistoryView.swift
│   └── Components/                 # Reusable UI components
│       ├── WeatherCardView.swift
│       └── LoadingView.swift
│
└── iosWeatherApp.swift             # App entry point

iosWeatherTests/
├── Mocks/                          # Mock implementations
│   ├── MockNetworkService.swift
│   ├── MockLocationService.swift
│   └── MockStorageService.swift
│
└── ViewModelTests/                 # Unit tests
    ├── CurrentWeatherViewModelTests.swift
    ├── SearchViewModelTests.swift
    └── HistoryViewModelTests.swift
```

## API

This app uses **Open-Meteo API**, a free weather API that doesn't require an API key:

- **Weather API**: https://api.open-meteo.com/v1/forecast
- **Geocoding API**: https://geocoding-api.open-meteo.com/v1/search

### Why Open-Meteo?

- ✅ Completely free
- ✅ No API key required
- ✅ No rate limits for basic usage
- ✅ High-quality data
- ✅ JSON responses

## Testing

### Run All Tests

```bash
xcodebuild test -project iosWeather.xcodeproj \
  -scheme iosWeather \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Run Specific Test Suite

```bash
xcodebuild test -project iosWeather.xcodeproj \
  -scheme iosWeather \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:iosWeatherTests/CurrentWeatherViewModelTests
```

### Test Coverage

- **CurrentWeatherViewModel**: 6 test cases
- **SearchViewModel**: 5 test cases
- **HistoryViewModel**: 6 test cases

All tests use mock implementations for isolated unit testing.

## Development

### Adding a New Feature

1. Create model in `Models/` (if needed)
2. Update service protocol in `Services/`
3. Implement in concrete service class
4. Create ViewModel in `ViewModels/`
5. Build SwiftUI view in `Views/`
6. Create mock in `iosWeatherTests/Mocks/`
7. Write unit tests in `iosWeatherTests/ViewModelTests/`

### Code Style Guidelines

- Use `async/await` for asynchronous code
- All ViewModels must be marked `@MainActor`
- Use protocol-based dependency injection
- Follow MVVM pattern strictly
- Write tests for all ViewModels

## Troubleshooting

### Location Not Working

1. Check Info.plist has location usage descriptions
2. Reset location permissions: Settings → Privacy → Location Services
3. Reset simulator: Device → Erase All Content and Settings

### Build Errors After Cloning

1. Clean build folder: `Cmd+Shift+K`
2. Reset package caches: File → Packages → Reset Package Caches
3. Resolve packages: File → Packages → Resolve Package Versions

### Tests Failing

1. Ensure tests are marked `@MainActor`
2. Verify all async operations use `await`
3. Check mock configurations in test `setUp()`

## Future Enhancements

This MVP can be extended with:

- **Daily/Hourly Forecasts**: 7-day and 24-hour forecasts
- **Weather Alerts**: Push notifications for severe weather
- **Widgets**: Home screen and lock screen widgets
- **Dark Mode**: Custom theming support
- **Offline Mode**: Cache weather data for offline viewing
- **Clean Architecture**: Extract Use Cases for better separation
- **Coordinator Pattern**: Advanced navigation management
- **Snapshot Tests**: UI regression testing

## License

This project is created for educational and portfolio purposes.

## Author

Juan Carlos Suarez Marin

---

**Note**: This is a production-quality MVP demonstrating best practices for iOS development including clean architecture, dependency injection, reactive programming, and comprehensive testing.
