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
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading {
                        ProgressView("Cargando hábitos...")
                            .padding()
                    } else if let error = viewModel.errorMessage {
                        errorView(error)
                    } else if viewModel.habitos.isEmpty {
                        emptyStateView
                    } else {
                        habitSelectorSection
                        levelSection
                        dragonSpriteSection
                        shopSection
                    }
                }
                .padding()
            }
            .navigationTitle("Juego")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Components
    
    private var habitSelectorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Hábito")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.reloadHabitos()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            
            Menu {
                ForEach(viewModel.habitos) { habito in
                    Button(action: {
                        viewModel.selectedHabitoId = habito.id
                    }) {
                        HStack {
                            Text(habito.title)
                            if viewModel.selectedHabitoId == habito.id {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.selectedHabito?.title ?? "Seleccionar hábito")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
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
    
    private var dragonSpriteSection: some View {
        VStack(spacing: 12) {
            Text("Tu Dragón")
                .font(.headline)
            
            Text(viewModel.currentAsciiArt)
                .font(.system(.body, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 2)
                )
        }
        .padding(.vertical)
    }
    
    private var shopSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "cart.fill")
                    .foregroundStyle(.orange)
                Text("Tienda de Objetos")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            Text("Compra objetos para hacer evolucionar a tu dragón")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Divider()
            
            ForEach(ShopItem.allItems) { item in
                ShopItemRow(
                    item: item,
                    currentLevel: viewModel.nivel,
                    isPurchased: viewModel.isItemPurchased(item),
                    canPurchase: viewModel.canPurchaseItem(item),
                    onPurchase: {
                        Task {
                            await viewModel.purchaseItem(item)
                        }
                    }
                )
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
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
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)
            
            Text(message)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
            
            Button("Reintentar") {
                Task {
                    await viewModel.loadHabitos()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Shop Item Row

struct ShopItemRow: View {
    let item: ShopItem
    let currentLevel: Int
    let isPurchased: Bool
    let canPurchase: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Estado del item
            Image(systemName: isPurchased ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isPurchased ? .green : .secondary)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(isPurchased ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    Label("Nivel \(item.requiredLevel)", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundStyle(currentLevel >= item.requiredLevel ? .purple : .secondary)
                    
                    if isPurchased {
                        Text("• Comprado")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
            
            Spacer()
            
            if !isPurchased {
                if canPurchase {
                    Button(action: onPurchase) {
                        Text("Comprar")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } else {
                    Text("🔒")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(isPurchased ? Color.green.opacity(0.05) : Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPurchased ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    GameView(storageProvider: MockStorageProvider())
        .environmentObject(AppConfig())
}
