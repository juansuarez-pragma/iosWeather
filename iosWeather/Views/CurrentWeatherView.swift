//
//  CurrentWeatherView.swift
//  iosWeather
//
//  Created by Juan Carlos Suarez Marin
//

import SwiftUI

// MARK: - Current Weather View

/// View displaying weather for current GPS location
struct CurrentWeatherView: View {

    @StateObject private var viewModel: CurrentWeatherViewModel

    init(viewModel: CurrentWeatherViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Content
                contentView
            }
            .navigationTitle("Current Weather")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    refreshButton
                }
            }
            .alert("Location Permission Required", isPresented: $viewModel.showLocationPermissionAlert) {
                Button("OK", role: .cancel) { }
                Button("Open Settings") {
                    openSettings()
                }
            } message: {
                Text("Please enable location access in Settings to see weather for your current location.")
            }
        }
        .task {
            await viewModel.fetchCurrentLocationWeather()
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            EmptyStateView(
                icon: "location.fill",
                title: "Ready",
                message: "Tap refresh to get weather for your current location"
            )

        case .loading:
            LoadingView(message: "Getting your location...")

        case .loaded(let weather):
            ScrollView {
                VStack(spacing: 20) {
                    WeatherCardView(weather: weather)
                        .padding(.top, 20)

                    Spacer()
                }
            }

        case .error(let message):
            ErrorView(message: message) {
                Task {
                    await viewModel.refresh()
                }
            }
        }
    }

    // MARK: - Refresh Button

    private var refreshButton: some View {
        Button(action: {
            Task {
                await viewModel.refresh()
            }
        }) {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(viewModel.state == .loading)
    }

    // MARK: - Helper Methods

    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - Preview

#Preview {
    CurrentWeatherView(
        viewModel: CurrentWeatherViewModel(
            networkService: NetworkService(),
            locationService: LocationService()
        )
    )
}
