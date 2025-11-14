//
//  MockLocationService.swift
//  iosWeatherTests
//
//  Created by Juan Carlos Suarez Marin
//

import Foundation
import CoreLocation
@testable import iosWeather

// MARK: - Mock Location Service

/// Mock implementation of LocationServiceProtocol for testing
final class MockLocationService: LocationServiceProtocol {

    // MARK: - Properties

    var shouldReturnError = false
    var mockCoordinates: LocationCoordinates?
    var errorToReturn: LocationError = .locationUnavailable
    var mockAuthorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse

    // Call tracking
    var requestPermissionCallCount = 0
    var getCurrentLocationCallCount = 0

    // MARK: - LocationServiceProtocol

    var authorizationStatus: CLAuthorizationStatus {
        mockAuthorizationStatus
    }

    func requestPermission() {
        requestPermissionCallCount += 1
    }

    func getCurrentLocation() async throws -> LocationCoordinates {
        getCurrentLocationCallCount += 1

        if shouldReturnError {
            throw errorToReturn
        }

        guard let coordinates = mockCoordinates else {
            throw LocationError.locationUnavailable
        }

        return coordinates
    }

    // MARK: - Helper Methods

    func reset() {
        shouldReturnError = false
        mockCoordinates = nil
        errorToReturn = .locationUnavailable
        mockAuthorizationStatus = .authorizedWhenInUse
        requestPermissionCallCount = 0
        getCurrentLocationCallCount = 0
    }
}

// MARK: - Mock Data Factory

extension MockLocationService {

    /// Creates sample location coordinates
    static func createMockCoordinates(
        latitude: Double = 40.7128,
        longitude: Double = -74.0060
    ) -> LocationCoordinates {
        LocationCoordinates(latitude: latitude, longitude: longitude)
    }
}
