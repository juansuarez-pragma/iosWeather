//
//  HistoryView.swift
//  iosWeather
//
//  Created by Juan Carlos Suarez Marin
//

import SwiftUI

// MARK: - History View

/// View displaying search history
struct HistoryView: View {

    @StateObject private var viewModel: HistoryViewModel

    init(viewModel: HistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.green.opacity(0.3), Color.cyan.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                contentView
            }
            .navigationTitle("Historial de Búsqueda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !viewModel.historyItems.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        clearButton
                    }
                }
            }
            .onAppear {
                viewModel.loadHistory()
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if case .loaded(let weather) = viewModel.weatherState {
            weatherDetailView(weather)
        } else {
            historyListView
        }
    }

    // MARK: - History List View

    @ViewBuilder
    private var historyListView: some View {
        if viewModel.historyItems.isEmpty {
            EmptyStateView(
                icon: "clock.fill",
                title: "Sin Historial",
                message: "Tu historial de búsquedas aparecerá aquí"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.historyItems) { item in
                        HistoryItemRow(item: item)
                            .onTapGesture {
                                Task {
                                    await viewModel.fetchWeather(for: item)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.deleteItem(item)
                                    }
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Weather Detail View

    @ViewBuilder
    private func weatherDetailView(_ weather: WeatherDisplayModel) -> some View {
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
                        Label("Volver al Historial", systemImage: "clock.arrow.circlepath")
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

    // MARK: - Clear Button

    private var clearButton: some View {
        Button(action: {
            withAnimation {
                viewModel.clearAllHistory()
            }
        }) {
            Text("Limpiar Todo")
                .foregroundColor(.red)
        }
    }
}

// MARK: - History Item Row

struct HistoryItemRow: View {

    let item: SearchHistoryItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.cityName)
                    .font(.headline)

                Text(formattedDate(item.searchDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
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

    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    HistoryView(
        viewModel: HistoryViewModel(
            networkService: NetworkService(),
            storageService: StorageService()
        )
    )
}
