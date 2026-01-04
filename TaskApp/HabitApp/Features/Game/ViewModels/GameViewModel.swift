//
//  GameViewModel.swift
//  HabitApp
//
//  ViewModel para el plugin de gamificación
//

import Foundation
import Combine

@MainActor
final class GameViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var habitos: [Habito] = []
    @Published var selectedHabitoId: UUID?
    @Published var gameData = GameData()
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let storageProvider: StorageProvider
    private let gameStorageService = GameStorageService.shared
    
    // MARK: - Computed Properties
    
    var selectedHabito: Habito? {
        guard let id = selectedHabitoId else { return nil }
        return habitos.first { $0.id == id }
    }
    
    var nivel: Int {
        guard let habito = selectedHabito else { return 0 }
        return calculateLevel(for: habito)
    }
    
    var currentProgress: HabitGameProgress? {
        guard let habitId = selectedHabitoId else { return nil }
        return gameData.habitProgresses[habitId] ?? HabitGameProgress(habitId: habitId)
    }
    
    var currentSprite: DragonSpriteType {
        return currentProgress?.currentSprite ?? .egg
    }
    
    var currentAsciiArt: String {
        let sprite = currentSprite
        
        // Si es dragón adulto, usar la semilla para mantener consistencia
        if sprite == .adultDragon, let progress = currentProgress {
            let models = [
                """
                    /\\_/\\
                   ( o.o )
                    > ^ <  ~<{
                   /|   |\\  ))
                  (_|   |_)/
                """,
                """
                   ____
                  /    \\__
                 (  @  @ )
                  \\  <>  /~<{
                   /|  |\\  ))
                  (_|  |_)/
                """,
                """
                   _/\\_
                  ( ^^ )
                 /\\_||_/\\
                 ( o  o )~<{
                  \\____/ ))
                   || ||
                """,
                """
                     /\\
                   _/  \\_
                  ( O  O )
                   \\ __ /~<{
                  /|    |\\ ))
                 (_|    |_)/
                """,
                """
                  __/\\__
                 /  **  \\
                ( @    @ )
                 \\  ==  /~<{
                  /|  |\\ ))
                 (_|  |_)/
                """
            ]
            let index = progress.dragonSeed % models.count
            return models[index]
        }
        
        return sprite.asciiArt
    }
    
    var availableItems: [ShopItem] {
        return ShopItem.allItems.filter { $0.requiredLevel <= nivel }
    }
    
    // MARK: - Initialization
    
    init(storageProvider: StorageProvider) {
        self.storageProvider = storageProvider
        Task {
            await loadGameData()
            await loadHabitos()
        }
    }
    
    // MARK: - Data Loading
    
    func loadGameData() async {
        do {
            gameData = try await gameStorageService.loadGameData()
            print("[GameViewModel] Game data loaded: \(gameData.habitProgresses.count) progresses")
        } catch {
            print("❌ [GameViewModel] Error loading game data: \(error)")
            gameData = GameData()
        }
    }
    
    func loadHabitos() async {
        isLoading = true
        errorMessage = nil
        
        do {
            habitos = try await storageProvider.loadHabits()
            print("[GameViewModel] Loaded \(habitos.count) habits")
            
            // Seleccionar el primer hábito por defecto si no hay ninguno seleccionado
            if selectedHabitoId == nil, let firstHabito = habitos.first {
                selectedHabitoId = firstHabito.id
            }
            
            // Si el hábito seleccionado ya no existe, seleccionar el primero disponible
            if let selectedId = selectedHabitoId,
               !habitos.contains(where: { $0.id == selectedId }),
               let firstHabito = habitos.first {
                selectedHabitoId = firstHabito.id
            }
        } catch {
            errorMessage = "Error al cargar hábitos: \(error.localizedDescription)"
            print("❌ [GameViewModel] Error loading habits: \(error)")
        }
        
        isLoading = false
    }
    
    /// Recarga los hábitos (llamar cuando el usuario hace clic en el selector)
    func reloadHabitos() async {
        await loadHabitos()
    }
    
    // MARK: - Level Calculation
    
    /// Calcula el nivel sumando todas las rachas que ha tenido el hábito
    /// - Parameter habito: El hábito para calcular el nivel
    /// - Returns: La suma de todas las rachas individuales
    private func calculateLevel(for habito: Habito) -> Int {
        let calendar = Calendar.current
        
        // Normalizar todas las fechas de completitud
        let completedDatesSet = Set(habito.fechaCompletitud.map { 
            calendar.startOfDay(for: $0) 
        })
        
        guard !completedDatesSet.isEmpty else { return 0 }
        
        // Obtener la fecha más antigua de completitud
        guard let oldestCompletion = completedDatesSet.min() else { return 0 }
        
        // Generar todas las fechas esperadas desde el inicio hasta hoy
        let today = calendar.startOfDay(for: Date())
        var expectedDates: [Date] = []
        var currentDate = oldestCompletion
        
        while currentDate <= today {
            if habito.debeRealizarse(en: currentDate) {
                expectedDates.append(currentDate)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        guard !expectedDates.isEmpty else { return 0 }
        
        // Calcular todas las rachas individuales
        var totalLevel = 0
        var currentStreakLength = 0
        
        for expectedDate in expectedDates {
            let isCompleted = completedDatesSet.contains(expectedDate)
            
            if isCompleted {
                currentStreakLength += 1
            } else {
                // Si había una racha en curso, sumarla al nivel total
                if currentStreakLength > 0 {
                    totalLevel += currentStreakLength
                    currentStreakLength = 0
                }
            }
        }
        
        // No olvidar sumar la última racha si aún está activa
        if currentStreakLength > 0 {
            totalLevel += currentStreakLength
        }
        
        return totalLevel
    }
    
    // MARK: - Shop Methods
    
    func canPurchaseItem(_ item: ShopItem) -> Bool {
        guard let habitId = selectedHabitoId else { return false }
        let progress = gameData.habitProgresses[habitId] ?? HabitGameProgress(habitId: habitId)
        
        // Puede comprar si: el nivel es suficiente Y no lo ha comprado ya
        return item.requiredLevel <= nivel && !progress.isItemPurchased(item.id)
    }
    
    func isItemPurchased(_ item: ShopItem) -> Bool {
        guard let habitId = selectedHabitoId else { return false }
        let progress = gameData.habitProgresses[habitId] ?? HabitGameProgress(habitId: habitId)
        return progress.isItemPurchased(item.id)
    }
    
    func purchaseItem(_ item: ShopItem) async {
        guard let habitId = selectedHabitoId else { return }
        
        // Verificar que puede comprar
        guard canPurchaseItem(item) else {
            print("⚠️ [GameViewModel] Cannot purchase item: \(item.name)")
            return
        }
        
        // Obtener o crear progreso
        var progress = gameData.habitProgresses[habitId] ?? HabitGameProgress(habitId: habitId)
        
        // Comprar el objeto
        progress.purchaseItem(item.id)
        
        // Actualizar en gameData
        gameData.updateProgress(progress)
        
        // Guardar
        do {
            try await gameStorageService.saveGameData(gameData)
            print("✅ [GameViewModel] Purchased item: \(item.name)")
        } catch {
            print("❌ [GameViewModel] Error saving after purchase: \(error)")
            errorMessage = "Error al guardar la compra"
        }
    }
}
