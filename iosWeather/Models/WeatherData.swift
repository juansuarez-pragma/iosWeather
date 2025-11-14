//
//  WeatherData.swift
//  iosWeather
//
//  Created by Juan Carlos Suarez Marin
//

import Foundation

// MARK: - Weather Response Models (Open-Meteo API)

/// Main weather response from Open-Meteo API
struct WeatherResponse: Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let current: CurrentWeather

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case timezone
        case current = "current"
    }
}

/// Current weather data
struct CurrentWeather: Codable {
    let time: String
    let temperature: Double
    let weatherCode: Int
    let windSpeed: Double
    let humidity: Int?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case weatherCode = "weather_code"
        case windSpeed = "wind_speed_10m"
        case humidity = "relative_humidity_2m"
    }

    /// Get weather description based on WMO Weather interpretation codes
    var weatherDescription: String {
        WeatherCodeMapper.description(for: weatherCode)
    }

    /// Get weather icon name based on weather code
    var weatherIcon: String {
        WeatherCodeMapper.iconName(for: weatherCode)
    }
}

// MARK: - Weather Display Model

/// Simplified model for UI display
struct WeatherDisplayModel {
    let cityName: String
    let temperature: Double
    let temperatureFormatted: String
    let description: String
    let iconName: String
    let humidity: String
    let windSpeed: String
    let lastUpdated: Date

    init(from response: WeatherResponse, cityName: String) {
        self.cityName = cityName
        self.temperature = response.current.temperature
        self.temperatureFormatted = String(format: "%.1f°C", response.current.temperature)
        self.description = response.current.weatherDescription
        self.iconName = response.current.weatherIcon
        self.humidity = "\(response.current.humidity ?? 0)%"
        self.windSpeed = String(format: "%.1f km/h", response.current.windSpeed)

        // Parse ISO 8601 date
        let formatter = ISO8601DateFormatter()
        self.lastUpdated = formatter.date(from: response.current.time) ?? Date()
    }
}

// MARK: - Weather Code Mapper

/// Maps WMO Weather interpretation codes to descriptions and icons
struct WeatherCodeMapper {
    static func description(for code: Int) -> String {
        switch code {
        case 0: return "Clear sky"
        case 1: return "Mainly clear"
        case 2: return "Partly cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Foggy"
        case 51, 53, 55: return "Drizzle"
        case 61, 63, 65: return "Rain"
        case 71, 73, 75: return "Snow"
        case 77: return "Snow grains"
        case 80, 81, 82: return "Rain showers"
        case 85, 86: return "Snow showers"
        case 95: return "Thunderstorm"
        case 96, 99: return "Thunderstorm with hail"
        default: return "Unknown"
        }
    }

    static func iconName(for code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1: return "sun.max"
        case 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55: return "cloud.drizzle.fill"
        case 61, 63, 65: return "cloud.rain.fill"
        case 71, 73, 75: return "cloud.snow.fill"
        case 77: return "cloud.snow"
        case 80, 81, 82: return "cloud.heavyrain.fill"
        case 85, 86: return "cloud.snow.fill"
        case 95: return "cloud.bolt.fill"
        case 96, 99: return "cloud.bolt.rain.fill"
        default: return "questionmark.circle"
        }
    }
}
