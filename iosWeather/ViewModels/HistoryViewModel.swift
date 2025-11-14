//
//  HistoryViewModel.swift
//  iosWeather
//
//  Created by Juan Carlos Suarez Marin
//

import Foundation
import Combine

// MARK: - History View Model

/// ViewModel for search history management
@MainActor
final class HistoryViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var historyItems: [SearchHistoryItem] = []
    @Published private(set) var weatherState: ViewState = .idle

    // MARK: - Dependencies

    private let networkService: NetworkServiceProtocol
    private let storageService: StorageServiceProtocol

    // MARK: - Initialization

    init(
        networkService: NetworkServiceProtocol,
        storageService: StorageServiceProtocol
    ) {
        self.networkService = networkService
        self.storageService = storageService

        loadHistory()
    }

    // MARK: - Public Methods

    /// Load search history from storage
    func loadHistory() {
        do {
            historyItems = try storageService.loadSearchHistory()
        } catch {
            print("Failed to load history: \(error)")
            historyItems = []
        }
    }

    /// Fetch weather for a history item
    func fetchWeather(for item: SearchHistoryItem) async {
        weatherState = .loading

        do {
            let weatherResponse = try await networkService.fetchWeather(
                latitude: item.coordinates.latitude,
                longitude: item.coordinates.longitude
            )

            let displayModel = WeatherDisplayModel(from: weatherResponse, cityName: item.cityName)
            weatherState = .loaded(displayModel)

        } catch let error as NetworkError {
            weatherState = .error(error.localizedDescription)
        } catch {
            weatherState = .error("An unexpected error occurred")
        }
    }

    /// Delete a history item
    func deleteItem(_ item: SearchHistoryItem) {
        historyItems.removeAll { $0.id == item.id }
        saveHistory()
    }

    /// Clear all history
    func clearAllHistory() {
        historyItems = []
        do {
            try storageService.clearSearchHistory()
        } catch {
            print("Failed to clear history: \(error)")
        }
    }

    /// Clear weather state
    func clearWeather() {
        weatherState = .idle
    }

    // MARK: - Private Methods

    private func saveHistory() {
        do {
            try storageService.saveSearchHistory(historyItems)
        } catch {
            print("Failed to save history: \(error)")
        }
    }
}
