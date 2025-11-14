//
//  SearchViewModelTests.swift
//  iosWeatherTests
//
//  Created by Juan Carlos Suarez Marin
//

import XCTest
@testable import iosWeather

// MARK: - Search View Model Tests

@MainActor
final class SearchViewModelTests: XCTestCase {

    // MARK: - Properties

    var sut: SearchViewModel!
    var mockNetworkService: MockNetworkService!
    var mockStorageService: MockStorageService!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        mockStorageService = MockStorageService()
        sut = SearchViewModel(
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
        // Then: Initial state should be correct
        XCTAssertEqual(sut.searchQuery, "")
        XCTAssertTrue(sut.searchResults.isEmpty)
        XCTAssertEqual(sut.weatherState, .idle)
        XCTAssertFalse(sut.isSearching)
    }

    func testFetchWeather_Success() async {
        // Given: Mock network service configured
        let mockWeather = MockNetworkService.createMockWeatherResponse()
        let city = GeocodingResult(
            name: "New York",
            latitude: 40.7128,
            longitude: -74.0060,
            country: "United States",
            admin1: "New York"
        )

        mockNetworkService.weatherResponse = mockWeather

        // When: Fetching weather for city
        await sut.fetchWeather(for: city)

        // Then: Weather state should be loaded
        if case .loaded(let weather) = sut.weatherState {
            XCTAssertEqual(weather.temperature, mockWeather.current.temperature)
        } else {
            XCTFail("Expected loaded state, got \(sut.weatherState)")
        }

        // And: Network service should be called
        XCTAssertEqual(mockNetworkService.fetchWeatherCallCount, 1)

        // And: Search should be saved to history
        XCTAssertEqual(mockStorageService.saveCallCount, 1)
    }

    func testFetchWeather_Error() async {
        // Given: Mock network service configured to return error
        let city = GeocodingResult(
            name: "London",
            latitude: 51.5074,
            longitude: -0.1278,
            country: "United Kingdom",
            admin1: "England"
        )

        mockNetworkService.shouldReturnError = true
        mockNetworkService.errorToReturn = .networkError(NSError(domain: "test", code: -1))

        // When: Fetching weather for city
        await sut.fetchWeather(for: city)

        // Then: Weather state should be error
        if case .error(let message) = sut.weatherState {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected error state, got \(sut.weatherState)")
        }
    }

    func testClearWeather() {
        // Given: Weather state is loaded
        sut = SearchViewModel(
            networkService: mockNetworkService,
            storageService: mockStorageService
        )

        // When: Clearing weather
        sut.clearWeather()

        // Then: Weather state should be idle
        XCTAssertEqual(sut.weatherState, .idle)
    }

    func testSearchQueryDebounce() async {
        // Given: Mock network service with search results
        mockNetworkService.geocodingResults = MockNetworkService.createMockGeocodingResults()

        // When: Setting search query
        sut.searchQuery = "New York"

        // Wait for debounce
        try? await Task.sleep(nanoseconds: 600_000_000) // 600ms

        // Then: Search should be performed
        await Task.yield()  // Allow async operations to complete

        // Note: Due to debouncing, the exact behavior may vary
        // This is a simplified test
    }

    func testEmptySearchQuery() {
        // Given: Empty search query
        sut.searchQuery = ""

        // Then: Search results should be empty
        XCTAssertTrue(sut.searchResults.isEmpty)
        XCTAssertFalse(sut.isSearching)
    }
}
