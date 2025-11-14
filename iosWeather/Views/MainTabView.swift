//
//  MainTabView.swift
//  iosWeather
//
//  Created by Juan Carlos Suarez Marin
//

import SwiftUI

// MARK: - Main Tab View

/// Main container view with tab navigation
struct MainTabView: View {

    // MARK: - Dependencies (Injected)

    private let networkService: NetworkServiceProtocol
    private let locationService: LocationServiceProtocol
    private let storageService: StorageServiceProtocol

    // MARK: - State

    @State private var selectedTab = 0

    // MARK: - Initialization

    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        locationService: LocationServiceProtocol = LocationService(),
        storageService: StorageServiceProtocol = StorageService()
    ) {
        self.networkService = networkService
        self.locationService = locationService
        self.storageService = storageService
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Current Weather Tab
            CurrentWeatherView(
                viewModel: CurrentWeatherViewModel(
                    networkService: networkService,
                    locationService: locationService
                )
            )
            .tabItem {
                Label("Current", systemImage: "location.fill")
            }
            .tag(0)

            // Search Tab
            SearchView(
                viewModel: SearchViewModel(
                    networkService: networkService,
                    storageService: storageService
                )
            )
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(1)

            // History Tab
            HistoryView(
                viewModel: HistoryViewModel(
                    networkService: networkService,
                    storageService: storageService
                )
            )
            .tabItem {
                Label("History", systemImage: "clock.fill")
            }
            .tag(2)
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}
