//
//  CurrentWeatherViewModelTests.swift
//  iosWeatherTests
//
//  Created by Juan Carlos Suarez Marin
//

import XCTest
@testable import iosWeather

// MARK: - Current Weather ViewModel Tests

@MainActor
final class CurrentWeatherViewModelTests: XCTestCase {

    // MARK: - Properties

    var sut: CurrentWeatherViewModel!
    var mockNetworkService: MockNetworkService!
    var mockLocationService: MockLocationService!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        mockLocationService = MockLocationService()
        sut = CurrentWeatherViewModel(
            networkService: mockNetworkService,
            locationService: mockLocationService
        )
    }

    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        mockLocationService = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testInitialState() {
        // Given & When: ViewModel is initialized
        // Then: Initial state should be idle
        XCTAssertEqual(sut.state, .idle)
        XCTAssertFalse(sut.showLocationPermissionAlert)
    }

    func testFetchCurrentLocationWeather_Success() async {
        // Given: Mock services are configured to return success
        let mockCoordinates = MockLocationService.createMockCoordinates()
        let mockWeather = MockNetworkService.createMockWeatherResponse()

        mockLocationService.mockCoordinates = mockCoordinates
        mockNetworkService.weatherResponse = mockWeather

        // When: Fetching current location weather
        await sut.fetchCurrentLocationWeather()

        // Then: State should be loaded with weather data
        if case .loaded(let weather) = sut.state {
            XCTAssertEqual(weather.temperature, mockWeather.current.temperature)
            XCTAssertEqual(weather.description, mockWeather.current.weatherDescription)
        } else {
            XCTFail("Expected loaded state, got \(sut.state)")
        }

        // And: Services should be called
        XCTAssertEqual(mockLocationService.getCurrentLocationCallCount, 1)
        XCTAssertEqual(mockNetworkService.fetchWeatherCallCount, 1)
    }

    func testFetchCurrentLocationWeather_LoadingState() async {
        // Given: Mock services configured
        let mockCoordinates = MockLocationService.createMockCoordinates()
        let mockWeather = MockNetworkService.createMockWeatherResponse()

        mockLocationService.mockCoordinates = mockCoordinates
        mockNetworkService.weatherResponse = mockWeather

        // When: Starting to fetch weather
        let fetchTask = Task {
            await sut.fetchCurrentLocationWeather()
        }

        // Then: State should transition through loading
        // (Note: In a real test, you might use expectations to catch the loading state)

        await fetchTask.value

        // Final state should be loaded
        XCTAssertNotEqual(sut.state, .loading)
    }

    func testFetchCurrentLocationWeather_LocationError() async {
        // Given: Location service configured to return error
        mockLocationService.shouldReturnError = true
        mockLocationService.errorToReturn = .permissionDenied

        // When: Fetching current location weather
        await sut.fetchCurrentLocationWeather()

        // Then: State should be error
        if case .error(let message) = sut.state {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected error state, got \(sut.state)")
        }

        // And: Permission alert should be shown
        XCTAssertTrue(sut.showLocationPermissionAlert)
    }

    func testFetchCurrentLocationWeather_NetworkError() async {
        // Given: Network service configured to return error
        let mockCoordinates = MockLocationService.createMockCoordinates()
        mockLocationService.mockCoordinates = mockCoordinates
        mockNetworkService.shouldReturnError = true
        mockNetworkService.errorToReturn = .networkError(NSError(domain: "test", code: -1))

        // When: Fetching current location weather
        await sut.fetchCurrentLocationWeather()

        // Then: State should be error
        if case .error(let message) = sut.state {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected error state, got \(sut.state)")
        }

        // And: Permission alert should NOT be shown (it's a network error)
        XCTAssertFalse(sut.showLocationPermissionAlert)
    }

    func testRefresh() async {
        // Given: Mock services configured
        let mockCoordinates = MockLocationService.createMockCoordinates()
        let mockWeather = MockNetworkService.createMockWeatherResponse()

        mockLocationService.mockCoordinates = mockCoordinates
        mockNetworkService.weatherResponse = mockWeather

        // When: Calling refresh
        await sut.refresh()

        // Then: Weather should be fetched
        XCTAssertEqual(mockLocationService.getCurrentLocationCallCount, 1)
        XCTAssertEqual(mockNetworkService.fetchWeatherCallCount, 1)
    }

    func testMultipleFetches() async {
        // Given: Mock services configured
        let mockCoordinates = MockLocationService.createMockCoordinates()
        let mockWeather = MockNetworkService.createMockWeatherResponse()

        mockLocationService.mockCoordinates = mockCoordinates
        mockNetworkService.weatherResponse = mockWeather

        // When: Fetching weather multiple times
        await sut.fetchCurrentLocationWeather()
        await sut.fetchCurrentLocationWeather()

        // Then: Services should be called twice
        XCTAssertEqual(mockLocationService.getCurrentLocationCallCount, 2)
        XCTAssertEqual(mockNetworkService.fetchWeatherCallCount, 2)
    }
}
