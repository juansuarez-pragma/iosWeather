//
//  Location.swift
//  iosWeather
//
//  Created by Juan Carlos Suarez Marin
//

import Foundation
import CoreLocation

// MARK: - Location Models

/// Represents a geographic location with coordinates
struct LocationCoordinates: Codable, Equatable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(from location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
    }
}

// MARK: - Geocoding Models (Open-Meteo Geocoding API)

/// Response from Open-Meteo Geocoding API
struct GeocodingResponse: Codable {
    let results: [GeocodingResult]?
}

/// Individual geocoding result
struct GeocodingResult: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let admin1: String? // State/Province

    var displayName: String {
        if let admin1 = admin1, let country = country {
            return "\(name), \(admin1), \(country)"
        } else if let country = country {
            return "\(name), \(country)"
        }
        return name
    }
}
