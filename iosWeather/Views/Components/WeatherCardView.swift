//
//  WeatherCardView.swift
//  iosWeather
//
//  Created by Juan Carlos Suarez Marin
//

import SwiftUI

// MARK: - Weather Card View

/// Reusable card component to display weather information
struct WeatherCardView: View {

    let weather: WeatherDisplayModel

    var body: some View {
        VStack(spacing: 20) {
            // City name
            Text(weather.cityName)
                .font(.title)
                .fontWeight(.semibold)

            // Weather icon
            Image(systemName: weather.iconName)
                .font(.system(size: 80))
                .symbolRenderingMode(.multicolor)

            // Temperature
            Text(weather.temperatureFormatted)
                .font(.system(size: 60, weight: .thin))

            // Description
            Text(weather.description)
                .font(.title3)
                .foregroundColor(.secondary)

            // Additional info
            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    Image(systemName: "humidity.fill")
                        .font(.title2)
                    Text(weather.humidity)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Humidity")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 8) {
                    Image(systemName: "wind")
                        .font(.title2)
                    Text(weather.windSpeed)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Wind Speed")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 10)

            // Last updated
            Text("Updated: \(formattedDate(weather.lastUpdated))")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 5)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    WeatherCardView(
        weather: WeatherDisplayModel(
            from: WeatherResponse(
                latitude: 40.7128,
                longitude: -74.0060,
                timezone: "America/New_York",
                current: CurrentWeather(
                    time: "2024-01-01T12:00:00",
                    temperature: 22.5,
                    weatherCode: 0,
                    windSpeed: 15.3,
                    humidity: 65
                )
            ),
            cityName: "New York"
        )
    )
    .padding()
}
