//
//  SearchViewModel.swift
//  iosWeather
//
//  Created by Juan Carlos Suarez Marin
//

import Foundation
import Combine

// MARK: - Search View Model

/// ViewModel for city search and weather display
@MainActor
final class SearchViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var searchQuery: String = ""
    @Published private(set) var searchResults: [GeocodingResult] = []
    @Published private(set) var weatherState: ViewState = .idle
    @Published private(set) var isSearching = false

    // MARK: - Dependencies

    private let networkService: NetworkServiceProtocol
    private let storageService: StorageServiceProtocol

    // MARK: - Private Properties

    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        networkService: NetworkServiceProtocol,
        storageService: StorageServiceProtocol
    ) {
        self.networkService = networkService
        self.storageService = storageService

        // Debounce search query
        setupSearchDebounce()
    }

    // MARK: - Public Methods

    /// Fetch weather for selected city
    func fetchWeather(for city: GeocodingResult) async {
        weatherState = .loading

        do {
            let weatherResponse = try await networkService.fetchWeather(
                latitude: city.latitude,
                longitude: city.longitude
            )

            let displayModel = WeatherDisplayModel(from: weatherResponse, cityName: city.displayName)
            weatherState = .loaded(displayModel)

            // Save to search history
            saveToHistory(city: city)

        } catch let error as NetworkError {
            weatherState = .error(error.localizedDescription)
        } catch {
            weatherState = .error("An unexpected error occurred")
        }
    }

    /// Clear current weather state
    func clearWeather() {
        weatherState = .idle
    }

    // MARK: - Private Methods

    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }

    private func performSearch(query: String) {
        // Cancel previous search
        searchTask?.cancel()

        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true

        searchTask = Task {
            do {
                let results = try await networkService.searchCity(query: query)

                if !Task.isCancelled {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                if !Task.isCancelled {
                    self.searchResults = []
                    self.isSearching = false
                }
            }
        }
    }

    private func saveToHistory(city: GeocodingResult) {
        do {
            var history = try storageService.loadSearchHistory()

            // Check if city already exists in history
            history.removeAll { $0.cityName == city.displayName }

            // Add to beginning
            let newItem = SearchHistoryItem(
                cityName: city.displayName,
                coordinates: LocationCoordinates(latitude: city.latitude, longitude: city.longitude)
            )
            history.insert(newItem, at: 0)

            try storageService.saveSearchHistory(history)
        } catch {
            // Silently fail - not critical
            print("Failed to save search history: \(error)")
        }
    }
}
