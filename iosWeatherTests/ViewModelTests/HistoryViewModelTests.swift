//
//  HistoryViewModelTests.swift
//  iosWeatherTests
//
//  Created by Juan Carlos Suarez Marin
//

import XCTest
@testable import iosWeather

// MARK: - History View Model Tests

@MainActor
final class HistoryViewModelTests: XCTestCase {

    // MARK: - Properties

    var sut: HistoryViewModel!
    var mockNetworkService: MockNetworkService!
    var mockStorageService: MockStorageService!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        mockStorageService = MockStorageService()
        sut = HistoryViewModel(
            networkService: mockNetworkService,
            storageService: mockStorageService
        )
    }

    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        mockStorageService = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testInitialState() {
        // Given & When: ViewModel is initialized
        // Then: History should be loaded from storage
        XCTAssertEqual(mockStorageService.loadCallCount, 1)
        XCTAssertEqual(sut.weatherState, .idle)
    }

    func testLoadHistory_Success() {
        // Given: Mock storage with history items
        let mockItems = [
            SearchHistoryItem(
                cityName: "New York",
                coordinates: LocationCoordinates(latitude: 40.7128, longitude: -74.0060)
            )
        ]

        try? mockStorageService.saveSearchHistory(mockItems)

        // When: Loading history
        sut.loadHistory()

        // Then: History items should be loaded
        XCTAssertEqual(sut.historyItems.count, mockItems.count)
        XCTAssertEqual(mockStorageService.loadCallCount, 2) // Once in init, once in loadHistory
    }

    func testLoadHistory_Error() {
        // Given: Mock storage configured to return error
        mockStorageService.shouldReturnError = true

        // When: Loading history
        sut.loadHistory()

        // Then: History should be empty (error handled gracefully)
        XCTAssertTrue(sut.historyItems.isEmpty)
    }

    func testFetchWeather_Success() async {
        // Given: Mock network service and history item
        let mockWeather = MockNetworkService.createMockWeatherResponse()
        let historyItem = SearchHistoryItem(
            cityName: "London",
            coordinates: LocationCoordinates(latitude: 51.5074, longitude: -0.1278)
        )

        mockNetworkService.weatherResponse = mockWeather

        // When: Fetching weather for history item
        await sut.fetchWeather(for: historyItem)

        // Then: Weather state should be loaded
        if case .loaded(let weather) = sut.weatherState {
            XCTAssertEqual(weather.temperature, mockWeather.current.temperature)
        } else {
            XCTFail("Expected loaded state, got \(sut.weatherState)")
        }

        XCTAssertEqual(mockNetworkService.fetchWeatherCallCount, 1)
    }

    func testDeleteItem() {
        // Given: History with items
        let item1 = SearchHistoryItem(
            cityName: "New York",
            coordinates: LocationCoordinates(latitude: 40.7128, longitude: -74.0060)
        )
        let item2 = SearchHistoryItem(
            cityName: "London",
            coordinates: LocationCoordinates(latitude: 51.5074, longitude: -0.1278)
        )

        try? mockStorageService.saveSearchHistory([item1, item2])
        sut.loadHistory()

        let initialCount = sut.historyItems.count

        // When: Deleting an item
        if let itemToDelete = sut.historyItems.first {
            sut.deleteItem(itemToDelete)
        }

        // Then: Item should be removed
        XCTAssertEqual(sut.historyItems.count, initialCount - 1)
        XCTAssertGreaterThan(mockStorageService.saveCallCount, 0)
    }

    func testClearAllHistory() {
        // Given: History with items
        let items = [
            SearchHistoryItem(
                cityName: "New York",
                coordinates: LocationCoordinates(latitude: 40.7128, longitude: -74.0060)
            )
        ]

        try? mockStorageService.saveSearchHistory(items)
        sut.loadHistory()

        // When: Clearing all history
        sut.clearAllHistory()

        // Then: History should be empty
        XCTAssertTrue(sut.historyItems.isEmpty)
        XCTAssertEqual(mockStorageService.clearCallCount, 1)
    }

    func testClearWeather() {
        // Given: Weather state is loaded
        // When: Clearing weather
        sut.clearWeather()

        // Then: Weather state should be idle
        XCTAssertEqual(sut.weatherState, .idle)
    }
}
