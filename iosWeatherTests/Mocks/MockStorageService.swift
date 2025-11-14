//
//  MockStorageService.swift
//  iosWeatherTests
//
//  Created by Juan Carlos Suarez Marin
//

import Foundation
@testable import iosWeather

// MARK: - Mock Storage Service

/// Mock implementation of StorageServiceProtocol for testing
final class MockStorageService: StorageServiceProtocol {

    // MARK: - Properties

    var shouldReturnError = false
    var errorToReturn: StorageError = .readError
    private var storage: [SearchHistoryItem] = []

    // Call tracking
    var saveCallCount = 0
    var loadCallCount = 0
    var clearCallCount = 0

    // MARK: - StorageServiceProtocol

    func saveSearchHistory(_ items: [SearchHistoryItem]) throws {
        saveCallCount += 1

        if shouldReturnError {
            throw errorToReturn
        }

        storage = items
    }

    func loadSearchHistory() throws -> [SearchHistoryItem] {
        loadCallCount += 1

        if shouldReturnError {
            throw errorToReturn
        }

        return storage
    }

    func clearSearchHistory() throws {
        clearCallCount += 1

        if shouldReturnError {
            throw errorToReturn
        }

        storage = []
    }

    // MARK: - Helper Methods

    func reset() {
        shouldReturnError = false
        errorToReturn = .readError
        storage = []
        saveCallCount = 0
        loadCallCount = 0
        clearCallCount = 0
    }
}
