//
//  SearchHistory.swift
//  iosWeather
//
//  Created by Juan Carlos Suarez Marin
//

import Foundation

// MARK: - Search History Model

/// Represents a search history entry
struct SearchHistoryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let cityName: String
    let coordinates: LocationCoordinates
    let searchDate: Date

    init(id: UUID = UUID(), cityName: String, coordinates: LocationCoordinates, searchDate: Date = Date()) {
        self.id = id
        self.cityName = cityName
        self.coordinates = coordinates
        self.searchDate = searchDate
    }

    static func == (lhs: SearchHistoryItem, rhs: SearchHistoryItem) -> Bool {
        lhs.id == rhs.id
    }
}
