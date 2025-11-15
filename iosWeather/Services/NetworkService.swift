//
//  NetworkService.swift
//  iosWeather
//
//  Created by Juan Carlos Suarez Marin
//

import Foundation
import Alamofire

// MARK: - Network Error

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .noData:
            return "No se recibieron datos"
        case .decodingError(let error):
            return "Error al decodificar datos: \(error.localizedDescription)"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        case .serverError(let statusCode):
            return "Error del servidor con código: \(statusCode)"
        }
    }
}

// MARK: - Network Service Protocol

/// Protocol for network operations - enables dependency injection and testing
protocol NetworkServiceProtocol {
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse
    func searchCity(query: String) async throws -> [GeocodingResult]
}

// MARK: - Network Service Implementation

/// Concrete implementation using Alamofire
final class NetworkService: NetworkServiceProtocol {

    // MARK: - Properties

    private let session: Session

    // MARK: - API Endpoints

    private enum Endpoint {
        static let weatherBaseURL = "https://api.open-meteo.com/v1/forecast"
        static let geocodingBaseURL = "https://geocoding-api.open-meteo.com/v1/search"
    }

    // MARK: - Initialization

    init(session: Session = .default) {
        self.session = session
    }

    // MARK: - Weather API

    /// Fetches current weather data for given coordinates
    /// - Parameters:
    ///   - latitude: Location latitude
    ///   - longitude: Location longitude
    /// - Returns: WeatherResponse object
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse {
        let parameters: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "current": "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m",
            "timezone": "auto"
        ]

        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                Endpoint.weatherBaseURL,
                method: .get,
                parameters: parameters
            )
            .validate()
            .responseDecodable(of: WeatherResponse.self) { response in
                switch response.result {
                case .success(let weatherResponse):
                    continuation.resume(returning: weatherResponse)

                case .failure(let error):
                    if let statusCode = response.response?.statusCode {
                        continuation.resume(throwing: NetworkError.serverError(statusCode: statusCode))
                    } else if let decodingError = error.asAFError?.underlyingError {
                        continuation.resume(throwing: NetworkError.decodingError(decodingError))
                    } else {
                        continuation.resume(throwing: NetworkError.networkError(error))
                    }
                }
            }
        }
    }

    // MARK: - Geocoding API

    /// Searches for cities by name
    /// - Parameter query: City name to search
    /// - Returns: Array of geocoding results
    func searchCity(query: String) async throws -> [GeocodingResult] {
        guard !query.isEmpty else {
            return []
        }

        let parameters: [String: Any] = [
            "name": query,
            "count": 10,
            "language": "en",
            "format": "json"
        ]

        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                Endpoint.geocodingBaseURL,
                method: .get,
                parameters: parameters
            )
            .validate()
            .responseDecodable(of: GeocodingResponse.self) { response in
                switch response.result {
                case .success(let geocodingResponse):
                    continuation.resume(returning: geocodingResponse.results ?? [])

                case .failure(let error):
                    if let statusCode = response.response?.statusCode {
                        continuation.resume(throwing: NetworkError.serverError(statusCode: statusCode))
                    } else if let decodingError = error.asAFError?.underlyingError {
                        continuation.resume(throwing: NetworkError.decodingError(decodingError))
                    } else {
                        continuation.resume(throwing: NetworkError.networkError(error))
                    }
                }
            }
        }
    }
}
