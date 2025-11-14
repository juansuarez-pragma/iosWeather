//
//  MockNetworkService.swift
//  iosWeatherTests
//
//  Created by Juan Carlos Suarez Marin
//

import Foundation
@testable import iosWeather

// MARK: - Mock Network Service

/// Mock implementation of NetworkServiceProtocol for testing
final class MockNetworkService: NetworkServiceProtocol {

    // MARK: - Properties

    var shouldReturnError = false
    var weatherResponse: WeatherResponse?
    var geocodingResults: [GeocodingResult] = []
    var errorToReturn: NetworkError = .noData

    // Call tracking
    var fetchWeatherCallCount = 0
    var searchCityCallCount = 0
    var lastFetchedCoordinates: (latitude: Double, longitude: Double)?
    var lastSearchQuery: String?

    // MARK: - NetworkServiceProtocol

    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse {
        fetchWeatherCallCount += 1
        lastFetchedCoordinates = (latitude, longitude)

        if shouldReturnError {
            throw errorToReturn
        }

        guard let response = weatherResponse else {
            throw NetworkError.noData
        }

        return response
    }

    func searchCity(query: String) async throws -> [GeocodingResult] {
        searchCityCallCount += 1
        lastSearchQuery = query

        if shouldReturnError {
            throw errorToReturn
        }

        return geocodingResults
    }

    // MARK: - Helper Methods

    func reset() {
        shouldReturnError = false
        weatherResponse = nil
        geocodingResults = []
        errorToReturn = .noData
        fetchWeatherCallCount = 0
        searchCityCallCount = 0
        lastFetchedCoordinates = nil
        lastSearchQuery = nil
    }
}

// MARK: - Mock Data Factory

extension MockNetworkService {

    /// Creates a sample successful weather response
    static func createMockWeatherResponse(
        latitude: Double = 40.7128,
        longitude: Double = -74.0060,
        temperature: Double = 22.5,
        weatherCode: Int = 0,
        windSpeed: Double = 15.3,
        humidity: Int = 65
    ) -> WeatherResponse {
        WeatherResponse(
            latitude: latitude,
            longitude: longitude,
            timezone: "America/New_York",
            current: CurrentWeather(
                time: "2024-01-01T12:00:00",
                temperature: temperature,
                weatherCode: weatherCode,
                windSpeed: windSpeed,
                humidity: humidity
            )
        )
    }

    /// Creates sample geocoding results
    static func createMockGeocodingResults() -> [GeocodingResult] {
        [
            GeocodingResult(
                name: "New York",
                latitude: 40.7128,
                longitude: -74.0060,
                country: "United States",
                admin1: "New York"
            ),
            GeocodingResult(
                name: "London",
                latitude: 51.5074,
                longitude: -0.1278,
                country: "United Kingdom",
                admin1: "England"
            )
        ]
    }
}
