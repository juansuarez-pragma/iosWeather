//
//  StorageService.swift
//  iosWeather
//
//  Created by Juan Carlos Suarez Marin
//

import Foundation

// MARK: - Storage Error

enum StorageError: LocalizedError {
    case encodingError
    case decodingError
    case writeError
    case readError

    var errorDescription: String? {
        switch self {
        case .encodingError:
            return "Error al codificar datos"
        case .decodingError:
            return "Error al decodificar datos"
        case .writeError:
            return "Error al escribir datos"
        case .readError:
            return "Error al leer datos"
        }
    }
}

// MARK: - Storage Service Protocol

/// Protocol for local persistence - enables dependency injection and testing
protocol StorageServiceProtocol {
    func saveSearchHistory(_ items: [SearchHistoryItem]) throws
    func loadSearchHistory() throws -> [SearchHistoryItem]
    func clearSearchHistory() throws
}

// MARK: - Storage Service Implementation

/// Manages local data persistence using UserDefaults
final class StorageService: StorageServiceProtocol {

    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let searchHistoryKey = "search_history_key"
    private let maxHistoryItems = 20

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Search History

    /// Save search history to persistent storage
    /// - Parameter items: Array of search history items
    func saveSearchHistory(_ items: [SearchHistoryItem]) throws {
        // Limit to max items
        let itemsToSave = Array(items.prefix(maxHistoryItems))

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(itemsToSave)
            userDefaults.set(data, forKey: searchHistoryKey)
        } catch {
            throw StorageError.encodingError
        }
    }

    /// Load search history from persistent storage
    /// - Returns: Array of search history items
    func loadSearchHistory() throws -> [SearchHistoryItem] {
        guard let data = userDefaults.data(forKey: searchHistoryKey) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let items = try decoder.decode([SearchHistoryItem].self, from: data)
            return items
        } catch {
            throw StorageError.decodingError
        }
    }

    /// Clear all search history
    func clearSearchHistory() throws {
        userDefaults.removeObject(forKey: searchHistoryKey)
    }
}
