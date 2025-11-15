//
//  SearchView.swift
//  iosWeather
//
//  Created by Juan Carlos Suarez Marin
//

import SwiftUI

// MARK: - Search View

/// View for searching cities and displaying their weather
struct SearchView: View {

    @StateObject private var viewModel: SearchViewModel

    init(viewModel: SearchViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.orange.opacity(0.3), Color.pink.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                        .padding()
                        .background(Color(.systemBackground).opacity(0.9))

                    // Content
                    contentView
                }
            }
            .navigationTitle("Buscar Ciudad")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Buscar una ciudad...", text: $viewModel.searchQuery)
                .textFieldStyle(PlainTextFieldStyle())
                .autocorrectionDisabled()

            if !viewModel.searchQuery.isEmpty {
                Button(action: {
                    viewModel.searchQuery = ""
                    viewModel.clearWeather()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.searchQuery.isEmpty {
            if case .loaded(let weather) = viewModel.weatherState {
                weatherResultView(weather)
            } else {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "Buscar Clima",
                    message: "Ingresa el nombre de una ciudad para buscar información del clima"
                )
            }
        } else if viewModel.isSearching {
            LoadingView(message: "Buscando ciudades...")
        } else if viewModel.searchResults.isEmpty {
            EmptyStateView(
                icon: "map",
                title: "Sin Resultados",
                message: "No se encontraron ciudades para '\(viewModel.searchQuery)'"
            )
        } else {
            searchResultsList
        }
    }

    // MARK: - Search Results List

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.searchResults, id: \.name) { city in
                    CityResultRow(city: city)
                        .onTapGesture {
                            viewModel.searchQuery = ""
                            Task {
                                await viewModel.fetchWeather(for: city)
                            }
                        }
                }
            }
            .padding()
        }
    }

    // MARK: - Weather Result View

    @ViewBuilder
    private func weatherResultView(_ weather: WeatherDisplayModel) -> some View {
        switch viewModel.weatherState {
        case .loading:
            LoadingView(message: "Cargando clima...")

        case .loaded:
            ScrollView {
                VStack(spacing: 20) {
                    WeatherCardView(weather: weather)
                        .padding(.top, 20)

                    Button(action: {
                        viewModel.clearWeather()
                    }) {
                        Label("Nueva Búsqueda", systemImage: "magnifyingglass")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }

                    Spacer()
                }
            }

        case .error(let message):
            ErrorView(message: message) {
                viewModel.clearWeather()
            }

        default:
            EmptyView()
        }
    }
}

// MARK: - City Result Row

struct CityResultRow: View {

    let city: GeocodingResult

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(city.name)
                    .font(.headline)

                if let country = city.country {
                    Text(country)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    SearchView(
        viewModel: SearchViewModel(
            networkService: NetworkService(),
            storageService: StorageService()
        )
    )
}
