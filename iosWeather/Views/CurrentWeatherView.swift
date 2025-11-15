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
            .navigationTitle("Clima Actual")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    refreshButton
                }
            }
            .alert("Permiso de Ubicación Requerido", isPresented: $viewModel.showLocationPermissionAlert) {
                Button("OK", role: .cancel) { }
                Button("Abrir Ajustes") {
                    openSettings()
                }
            } message: {
                Text("Por favor habilita el acceso a la ubicación en Ajustes para ver el clima de tu ubicación actual.")
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
                title: "Listo",
                message: "Toca actualizar para obtener el clima de tu ubicación actual"
            )

        case .loading:
            LoadingView(message: "Obteniendo tu ubicación...")

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
