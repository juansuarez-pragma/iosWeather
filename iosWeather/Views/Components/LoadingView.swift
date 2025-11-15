//
//  LoadingView.swift
//  iosWeather
//
//  Created by Juan Carlos Suarez Marin
//

import SwiftUI

// MARK: - Loading View

/// Reusable loading indicator component
struct LoadingView: View {

    var message: String = "Cargando..."

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error View

/// Reusable error display component
struct ErrorView: View {

    let message: String
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("¡Ups!")
                .font(.title)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    Label("Intentar de Nuevo", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View

/// Reusable empty state component
struct EmptyStateView: View {

    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("Loading") {
    LoadingView()
}

#Preview("Error") {
    ErrorView(message: "No se pudo obtener los datos del clima. Por favor verifica tu conexión a internet.") {
        print("Retry tapped")
    }
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "magnifyingglass",
        title: "Sin Resultados",
        message: "Intenta buscar una ciudad diferente"
    )
}
