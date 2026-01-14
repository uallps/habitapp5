//
//  GameViewModel.swift
//  HabitApp
//
//  ViewModel para el plugin de gamificación
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class GameViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var habitos: [Habito] = []
    @Published var selectedHabitoId: UUID? {
        didSet {
            Task { [weak self] in
                await self?.recalculateLevel()
            }
        }
    }
    @Published var gameData = GameData()
    @Published private(set) var nivel: Int = 0
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let storageProvider: StorageProvider
    private var gameStorageService: GameStorageService
    private let appConfig: AppConfig
    
    // MARK: - Computed Properties
    
    var selectedHabito: Habito? {
        guard let id = selectedHabitoId else { return nil }
        return habitos.first { $0.id == id }
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
        
        // Si es dragón adulto, usar el índice directo del dragón
        if sprite == .adultDragon, let progress = currentProgress {
            let models = getDragonModels()
            return models[progress.dragonIndex]
        }
        
        return sprite.asciiArt
    }
    
    /// Obtiene el índice del modelo de dragón actual (solo válido para dragón adulto)
    var currentDragonIndex: Int? {
        guard currentSprite == .adultDragon, let progress = currentProgress else {
            return nil
        }
        return progress.dragonIndex
    }
    
    var availableItems: [ShopItem] {
        return ShopItem.allItems.filter { $0.requiredLevel <= nivel }
    }
    
    var collectedDragonsCount: Int {
        return gameData.collectedDragons.count
    }
    
    var totalDragonsCount: Int {
        return GameData.totalDragonVariants
    }
    
    // MARK: - Initialization
    
    init(storageProvider: StorageProvider, appConfig: AppConfig) {
        self.storageProvider = storageProvider
        self.appConfig = appConfig
        
        // Inicializar el servicio de almacenamiento según la configuración
        let storageType: GameStorageType = (appConfig.storageType == .swiftData) ? .swiftData : .json
        self.gameStorageService = GameStorageService(storageType: storageType)
        
        Task {
            await loadGameData()
            await loadHabitos()
        }
    }
    
    // MARK: - Helper Methods
    
    private func getDragonModels() -> [String] {
        return [
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
    }
    
    func getDragonModelByIndex(_ index: Int) -> String {
        let models = getDragonModels()
        guard index >= 0 && index < models.count else {
            return models[0]
        }
        return models[index]
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

        // Recalcular el nivel con los datos más recientes
        await recalculateLevel()
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

    /// Recalcula el nivel usando una versión fresca del hábito desde el StorageProvider.
    /// De esta forma evitamos acceder a instancias de Habito que SwiftData ya haya eliminado
    /// de su ModelContext (lo que generaba el fatal error en fechaCompletitud).
    private func recalculateLevel() async {
        guard let selectedId = selectedHabitoId else {
            nivel = 0
            return
        }

        do {
            let upToDateHabits = try await storageProvider.loadHabits()
            guard let habit = upToDateHabits.first(where: { $0.id == selectedId }) else {
                // El hábito seleccionado ya no existe
                nivel = 0
                return
            }

            nivel = calculateLevel(for: habit)
        } catch {
            print("❌ [GameViewModel] Error recalculating level: \(error)")
            nivel = 0
        }
    }
    
    // MARK: - Shop Methods
    
    func canPurchaseItem(_ item: ShopItem) -> Bool {
        guard let habitId = selectedHabitoId else { return false }
        let progress = gameData.habitProgresses[habitId] ?? HabitGameProgress(habitId: habitId)
        
        // No puede comprar si ya lo tiene
        if progress.isItemPurchased(item.id) {
            return false
        }
        
        // No puede comprar si el nivel no es suficiente
        if item.requiredLevel > nivel {
            return false
        }
        
        // RESTRICCIÓN SECUENCIAL: Debe tener el objeto anterior
        // Encontrar el índice del item actual
        guard let currentIndex = ShopItem.allItems.firstIndex(where: { $0.id == item.id }) else {
            return false
        }
        
        // Si no es el primer item, verificar que tiene el anterior
        if currentIndex > 0 {
            let previousItem = ShopItem.allItems[currentIndex - 1]
            if !progress.isItemPurchased(previousItem.id) {
                return false // No tiene el item anterior
            }
        }
        
        return true
    }
    
    func isItemPurchased(_ item: ShopItem) -> Bool {
        guard let habitId = selectedHabitoId else { return false }
        let progress = gameData.habitProgresses[habitId] ?? HabitGameProgress(habitId: habitId)
        return progress.isItemPurchased(item.id)
    }
    
    func purchaseItem(_ item: ShopItem) async {
        guard let habitId = selectedHabitoId,
              let habito = selectedHabito else { return }
        
        // Verificar que puede comprar
        guard canPurchaseItem(item) else {
            print("⚠️ [GameViewModel] Cannot purchase item: \(item.name)")
            return
        }
        
        // Obtener o crear progreso
        var progress = gameData.habitProgresses[habitId] ?? HabitGameProgress(habitId: habitId)
        
        // Verificar si acabamos de alcanzar el dragón adulto con esta compra
        let wasAdultDragonBefore = progress.currentSprite == .adultDragon
        
        // Comprar el objeto
        progress.purchaseItem(item.id)
        
        // Actualizar en gameData
        gameData.updateProgress(progress)
        
        // Si ahora es dragón adulto y antes no lo era, añadirlo a la colección
        if progress.currentSprite == .adultDragon && !wasAdultDragonBefore {
            gameData.collectDragon(dragonIndex: progress.dragonIndex, habitId: habitId, habitName: habito.title)
            print("🐉 [GameViewModel] New dragon collected! Index: \(progress.dragonIndex)")
        }
        
        // Guardar
        do {
            try await gameStorageService.saveGameData(gameData)
            print("✅ [GameViewModel] Purchased item: \(item.name)")
        } catch {
            print("❌ [GameViewModel] Error saving after purchase: \(error)")
            errorMessage = "Error al guardar la compra"
        }
    }
    
    // MARK: - Dragon Collection Methods
    
    /// Obtiene la información de un dragón coleccionado, incluyendo el nombre actualizado del hábito si existe
    func getDragonInfo(for collectedDragon: CollectedDragon) -> (habitName: String, habitExists: Bool) {
        // Intentar encontrar el hábito actual por ID
        if let currentHabit = habitos.first(where: { $0.id == collectedDragon.habitId }) {
            return (currentHabit.title, true)
        } else {
            // El hábito ya no existe, usar el nombre guardado
            return (collectedDragon.habitNameAtDiscovery, false)
        }
    }
}
