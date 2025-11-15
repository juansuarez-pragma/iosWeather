//
//  LocationService.swift
//  iosWeather
//
//  Created by Juan Carlos Suarez Marin
//

import Foundation
import CoreLocation
import Combine

// MARK: - Location Error

enum LocationError: LocalizedError {
    case permissionDenied
    case locationUnavailable
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Permiso de ubicación denegado. Por favor habilita el acceso a la ubicación en Ajustes."
        case .locationUnavailable:
            return "No se pudo determinar tu ubicación. Por favor intenta de nuevo."
        case .unknown(let error):
            return "Error de ubicación: \(error.localizedDescription)"
        }
    }
}

// MARK: - Location Service Protocol

/// Protocol for location operations - enables dependency injection and testing
protocol LocationServiceProtocol {
    var authorizationStatus: CLAuthorizationStatus { get }
    func requestPermission()
    func getCurrentLocation() async throws -> LocationCoordinates
}

// MARK: - Location Service Implementation

/// Manages CoreLocation operations
final class LocationService: NSObject, LocationServiceProtocol {

    // MARK: - Properties

    private let locationManager: CLLocationManager
    private var locationContinuation: CheckedContinuation<LocationCoordinates, Error>?

    var authorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }

    // MARK: - Initialization

    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Public Methods

    /// Request location permission from user
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Get current user location
    /// - Returns: LocationCoordinates
    func getCurrentLocation() async throws -> LocationCoordinates {
        // Check authorization status
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            requestPermission()
            throw LocationError.permissionDenied

        case .restricted, .denied:
            throw LocationError.permissionDenied

        case .authorizedAlways, .authorizedWhenInUse:
            return try await fetchLocation()

        @unknown default:
            throw LocationError.permissionDenied
        }
    }

    // MARK: - Private Methods

    private func fetchLocation() async throws -> LocationCoordinates {
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            locationContinuation?.resume(throwing: LocationError.locationUnavailable)
            locationContinuation = nil
            return
        }

        let coordinates = LocationCoordinates(from: location)
        locationContinuation?.resume(returning: coordinates)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationContinuation?.resume(throwing: LocationError.permissionDenied)
            default:
                locationContinuation?.resume(throwing: LocationError.unknown(error))
            }
        } else {
            locationContinuation?.resume(throwing: LocationError.unknown(error))
        }
        locationContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Handle authorization changes if needed
        // This can be extended to notify ViewModels via Combine
    }
}
