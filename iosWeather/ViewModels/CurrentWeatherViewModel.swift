//
//  CurrentWeatherViewModel.swift
//  iosWeather
//
//  Created by Juan Carlos Suarez Marin
//

import Foundation
import Combine

// MARK: - View State

enum ViewState: Equatable {
    case idle
    case loading
    case loaded(WeatherDisplayModel)
    case error(String)

    static func == (lhs: ViewState, rhs: ViewState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case (.loaded(let lhsModel), .loaded(let rhsModel)):
            return lhsModel.cityName == rhsModel.cityName
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

// MARK: - Current Weather ViewModel

/// ViewModel for current weather based on GPS location
@MainActor
final class CurrentWeatherViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var state: ViewState = .idle
    @Published var showLocationPermissionAlert = false

    // MARK: - Dependencies

    private let networkService: NetworkServiceProtocol
    private let locationService: LocationServiceProtocol

    // MARK: - Initialization

    init(
        networkService: NetworkServiceProtocol,
        locationService: LocationServiceProtocol
    ) {
        self.networkService = networkService
        self.locationService = locationService
    }

    // MARK: - Public Methods

    /// Fetch weather for current GPS location
    func fetchCurrentLocationWeather() async {
        state = .loading

        do {
            // Get current location
            let coordinates = try await locationService.getCurrentLocation()

            // Fetch weather data
            let weatherResponse = try await networkService.fetchWeather(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )

            // Try to get city name via reverse geocoding (simplified - just use "Ubicación Actual")
            let cityName = "Ubicación Actual"
            let displayModel = WeatherDisplayModel(from: weatherResponse, cityName: cityName)

            state = .loaded(displayModel)

        } catch let error as LocationError {
            handleLocationError(error)
        } catch let error as NetworkError {
            state = .error(error.localizedDescription)
        } catch {
            state = .error("Ocurrió un error inesperado")
        }
    }

    /// Refresh weather data
    func refresh() async {
        await fetchCurrentLocationWeather()
    }

    // MARK: - Private Methods

    private func handleLocationError(_ error: LocationError) {
        switch error {
        case .permissionDenied:
            showLocationPermissionAlert = true
            state = .error(error.localizedDescription)
        case .locationUnavailable, .unknown:
            state = .error(error.localizedDescription)
        }
    }
}
