//
//  GameView.swift
//  HabitApp
//
//  Vista principal del plugin de gamificación
//

import SwiftUI

struct GameView: View {
    @StateObject private var viewModel: GameViewModel
    @EnvironmentObject var appConfig: AppConfig
    
    init(storageProvider: StorageProvider) {
        _viewModel = StateObject(wrappedValue: GameViewModel(storageProvider: storageProvider))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    ProgressView("Cargando hábitos...")
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if viewModel.habitos.isEmpty {
                    emptyStateView
                } else {
                    habitSelectorSection
                    levelSection
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("Juego")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Components
    
    private var habitSelectorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hábito")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Picker("Seleccionar hábito", selection: $viewModel.selectedHabitoId) {
                ForEach(viewModel.habitos) { habito in
                    Text(habito.title)
                        .tag(habito.id as UUID?)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var levelSection: some View {
        VStack(spacing: 12) {
            Text("Nivel: \(viewModel.nivel)")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            if let habito = viewModel.selectedHabito {
                Text("Basado en todas las rachas de '\(habito.title)'")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.purple.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No hay hábitos")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Crea un hábito para empezar a ganar niveles")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    GameView(storageProvider: MockStorageProvider())
        .environmentObject(AppConfig())
}
