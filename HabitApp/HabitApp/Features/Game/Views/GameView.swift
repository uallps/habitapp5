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
    
    init(storageProvider: StorageProvider, appConfig: AppConfig) {
        _viewModel = StateObject(wrappedValue: GameViewModel(storageProvider: storageProvider, appConfig: appConfig))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                            if viewModel.isLoading {
                                ProgressView("Cargando hábitos...")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else if let error = viewModel.errorMessage {
                                errorView(error)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else if viewModel.habitos.isEmpty {
                                emptyStateView
                            } else {
                                ScrollView {
                                    VStack(spacing: 24) {
                                        habitSelectorSection
                                        levelSection
                                        dragonSpriteSection
                                        shopSection
                                        dragonCollectionSection
                                    }
                                    .padding()
                                }
                                .background(AppStyle.screenBackground)
                            }
                        }
            .navigationTitle("Juego")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .task {
                // Recargar datos del juego y hábitos cada vez que se muestra la vista
                // Esto mantiene el nivel actualizado cuando cambia la racha
                await viewModel.loadGameData()
                await viewModel.reloadHabitos()
            }
        }
        .id("game-\(appConfig.storageType.rawValue)") // Forzar recreación cuando cambia el tipo de almacenamiento
    }
    
    // MARK: - Components
    
    private var habitSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Hábito")
                    .font(.headline)
                
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
                .background(AppStyle.subtleFill)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(AppStyle.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius))
    }
    
    private var levelSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.purple)
                Text("Nivel")
                    .font(.headline)
            }
            
            Text("\(viewModel.nivel)")
                .font(.system(size: 56, weight: .bold))
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
        .background(AppStyle.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius))
    }
    
    private var dragonSpriteSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("Tu Dragón")
                    .font(.headline)
                Spacer()
            }
            
            Text(viewModel.currentAsciiArt)
                .font(.system(.body, design: .monospaced))
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppStyle.subtleFill)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(AppStyle.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius))
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
        .background(AppStyle.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius))
    }
    
    private var dragonCollectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundStyle(.blue)
                Text("Colección de Dragones")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(viewModel.collectedDragonsCount)/\(viewModel.totalDragonsCount)")
                    .font(.headline)
                    .foregroundStyle(.blue)
            }
            
            Text("Colecciona todos los dragones adultos únicos")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Divider()
            
            // Grid de dragones (2 columnas para mejor visualización)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(0..<GameData.totalDragonVariants, id: \.self) { index in
                    DragonCollectionCard(
                        dragonIndex: index,
                        isCollected: viewModel.gameData.isDragonCollected(index),
                        collectedDragon: viewModel.gameData.collectedDragons.first { $0.id == index },
                        dragonArt: viewModel.getDragonModelByIndex(index),
                        getDragonInfo: { dragon in
                            viewModel.getDragonInfo(for: dragon)
                        }
                    )
                }
            }
        }
        .padding()
        .background(AppStyle.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius))
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label {
                Text("No hay hábitos")
                    .font(.title3)
                    .fontWeight(.semibold)
            } icon: {
                Image(systemName: "tray.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
            }
        } description: {
            Text("Crea un hábito para empezar a ganar niveles")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    private var statusMessage: String? {
        if isPurchased {
            return nil
        }
        
        if currentLevel < item.requiredLevel {
            return "Nivel \(item.requiredLevel) requerido"
        }
        
        // Si no puede comprar pero tiene el nivel, es por restricción secuencial
        if !canPurchase && currentLevel >= item.requiredLevel {
            return "Compra el objeto anterior primero"
        }
        
        return nil
    }
    
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
                
                // Mensaje de estado adicional
                if let message = statusMessage {
                    Text(message)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .padding(.top, 2)
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
        .background(AppStyle.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPurchased ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Dragon Collection Card

struct DragonCollectionCard: View {
    let dragonIndex: Int
    let isCollected: Bool
    let collectedDragon: CollectedDragon?
    let dragonArt: String
    let getDragonInfo: (CollectedDragon) -> (habitName: String, habitExists: Bool)
    
    var body: some View {
        VStack(spacing: 8) {
            // Arte del dragón
            if isCollected {
                Text(dragonArt)
                    .font(.system(.caption2, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(8)
                    .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 120)
                    .background(AppStyle.subtleFill)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                // Dragón no descubierto - silueta
                ZStack {
                    Text(dragonArt)
                        .font(.system(.caption2, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .blur(radius: 5)
                        .opacity(0.3)
                    
                    Image(systemName: "questionmark")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 120)
                .background(AppStyle.subtleFill)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Información
            VStack(spacing: 4) {
                if isCollected, let dragon = collectedDragon {
                    let info = getDragonInfo(dragon)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption2)
                        Text("Dragón #\(dragonIndex + 1)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    
                    Text("Descubierto en:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        Text(info.habitName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        if !info.habitExists {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .help("Este hábito ya no existe")
                        }
                    }
                } else {
                    Text("???")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    Text("Por descubrir")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(AppStyle.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCollected ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    let config = AppConfig()
    return GameView(storageProvider: MockStorageProvider(), appConfig: config)
        .environmentObject(config)
}
