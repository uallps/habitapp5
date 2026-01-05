//
//  GameModels.swift
//  HabitApp
//
//  Modelos de datos para el plugin de gamificación
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Shop Item

/// Objeto de la tienda que desbloquea sprites
struct ShopItem: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let requiredLevel: Int
    let spriteType: DragonSpriteType
    
    static let allItems: [ShopItem] = [
        ShopItem(id: "cushion", name: "Cojín", requiredLevel: 1, spriteType: .egg),
        ShopItem(id: "thin_blanket", name: "Manta fina", requiredLevel: 3, spriteType: .egg),
        ShopItem(id: "candle", name: "Vela", requiredLevel: 7, spriteType: .eggSlightlyCracked),
        ShopItem(id: "fur_blanket", name: "Manta de pelo", requiredLevel: 11, spriteType: .eggSlightlyCracked),
        ShopItem(id: "hand_warmers", name: "Calientamanos", requiredLevel: 15, spriteType: .eggCracked),
        ShopItem(id: "light_bulb", name: "Bombilla", requiredLevel: 19, spriteType: .eggCracked),
        ShopItem(id: "thermal_blanket", name: "Manta térmica", requiredLevel: 23, spriteType: .eggVeryCracked),
        ShopItem(id: "electric_heater", name: "Calefactor eléctrico", requiredLevel: 27, spriteType: .eggVeryCracked),
        ShopItem(id: "wood_stove", name: "Caldera de leña", requiredLevel: 31, spriteType: .babyDragon),
        ShopItem(id: "lava_chamber", name: "Cámara de lava", requiredLevel: 35, spriteType: .babyDragon),
        ShopItem(id: "mini_sun", name: "Sol en miniatura", requiredLevel: 40, spriteType: .adultDragon)
    ]
}

// MARK: - Dragon Sprite Type

enum DragonSpriteType: String, Codable {
    case egg
    case eggSlightlyCracked
    case eggCracked
    case eggVeryCracked
    case babyDragon
    case adultDragon
    
    var asciiArt: String {
        switch self {
        case .egg:
            return """
                   ___
                 /     \\
                |       |
                |       |
                 \\_____/
            """
        case .eggSlightlyCracked:
            return """
                   ___
                 /  /  \\
                |  /    |
                |       |
                 \\_____/
            """
        case .eggCracked:
            return """
                   _/_
                 / / | \\
                | /  \\ |
                |  /   |
                 \\_|__/
            """
        case .eggVeryCracked:
            return """
                  _/_/_
                /|/ /| \\
               | / \\ |/ |
               | / \\_|  |
                \\_|_|_/
            """
        case .babyDragon:
            return """
                  ^   ^
                 / \\_/ \\
                |  O O  |
                |  \\_/  |
                 \\_---_/
                  /| |\\
            """
        case .adultDragon:
            // Retorna uno de 5 modelos aleatorios
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
            return models.randomElement() ?? models[0]
        }
    }
}

// MARK: - Habit Game Progress

/// Progresión del juego para un hábito específico
struct HabitGameProgress: Codable, Identifiable {
    let id: UUID // ID del hábito
    var purchasedItemIds: [String]
    var dragonIndex: Int // Índice directo del dragón adulto (0-4)
    
    init(habitId: UUID, purchasedItemIds: [String] = [], dragonIndex: Int? = nil) {
        self.id = habitId
        self.purchasedItemIds = purchasedItemIds
        // Generar un índice aleatorio entre 0 y 4 directamente
        self.dragonIndex = dragonIndex ?? Int.random(in: 0...4)
    }
    
    /// Obtiene el sprite actual basado en los objetos comprados
    var currentSprite: DragonSpriteType {
        let sortedItems = ShopItem.allItems
            .filter { purchasedItemIds.contains($0.id) }
            .sorted { $0.requiredLevel < $1.requiredLevel }
        
        return sortedItems.last?.spriteType ?? .egg
    }
    
    func isItemPurchased(_ itemId: String) -> Bool {
        return purchasedItemIds.contains(itemId)
    }
    
    mutating func purchaseItem(_ itemId: String) {
        if !purchasedItemIds.contains(itemId) {
            purchasedItemIds.append(itemId)
        }
    }
}

// MARK: - Dragon Collection

/// Información de un dragón adulto coleccionado
struct CollectedDragon: Codable, Identifiable {
    let id: Int // Índice del modelo de dragón (0-4)
    let habitId: UUID // ID del hábito donde se descubrió
    let habitNameAtDiscovery: String // Nombre del hábito en el momento del descubrimiento
    let discoveredDate: Date
    
    init(dragonIndex: Int, habitId: UUID, habitName: String, discoveredDate: Date = Date()) {
        self.id = dragonIndex
        self.habitId = habitId
        self.habitNameAtDiscovery = habitName
        self.discoveredDate = discoveredDate
    }
}

// MARK: - Game Data

/// Datos completos del juego (contiene progresión de todos los hábitos)
struct GameData: Codable {
    var habitProgresses: [UUID: HabitGameProgress]
    var collectedDragons: [CollectedDragon] // Dragones adultos coleccionados
    
    init(habitProgresses: [UUID: HabitGameProgress] = [:], collectedDragons: [CollectedDragon] = []) {
        self.habitProgresses = habitProgresses
        self.collectedDragons = collectedDragons
    }
    
    mutating func getOrCreateProgress(for habitId: UUID) -> HabitGameProgress {
        if let existing = habitProgresses[habitId] {
            return existing
        }
        let newProgress = HabitGameProgress(habitId: habitId)
        habitProgresses[habitId] = newProgress
        return newProgress
    }
    
    mutating func updateProgress(_ progress: HabitGameProgress) {
        habitProgresses[progress.id] = progress
    }
    
    /// Verifica si un dragón específico ya fue coleccionado
    func isDragonCollected(_ dragonIndex: Int) -> Bool {
        return collectedDragons.contains { $0.id == dragonIndex }
    }
    
    /// Añade un dragón a la colección si no existe
    mutating func collectDragon(dragonIndex: Int, habitId: UUID, habitName: String) {
        if !isDragonCollected(dragonIndex) {
            let dragon = CollectedDragon(dragonIndex: dragonIndex, habitId: habitId, habitName: habitName)
            collectedDragons.append(dragon)
        }
    }
    
    /// Número total de dragones adultos únicos (siempre 5)
    static let totalDragonVariants = 5
}

// MARK: - SwiftData Models

/// Modelo de SwiftData para almacenar los datos completos del juego
@Model
final class GameDataModel {
    var habitProgressesData: Data  // JSON codificado de [UUID: HabitGameProgress]
    var collectedDragonsData: Data  // JSON codificado de [CollectedDragon]
    var lastUpdated: Date
    
    init(habitProgressesData: Data = Data(), collectedDragonsData: Data = Data()) {
        self.habitProgressesData = habitProgressesData
        self.collectedDragonsData = collectedDragonsData
        self.lastUpdated = Date()
    }
    
    /// Convierte el modelo SwiftData a GameData
    func toGameData() throws -> GameData {
        let decoder = JSONDecoder()
        
        let habitProgresses: [UUID: HabitGameProgress]
        if habitProgressesData.isEmpty {
            habitProgresses = [:]
        } else {
            // Decodificar como array de tuplas y convertir a diccionario
            let progressArray = try decoder.decode([[String: HabitGameProgress]].self, from: habitProgressesData)
            habitProgresses = Dictionary(uniqueKeysWithValues: progressArray.compactMap { dict in
                guard let (key, value) = dict.first,
                      let uuid = UUID(uuidString: key) else { return nil }
                return (uuid, value)
            })
        }
        
        let collectedDragons: [CollectedDragon]
        if collectedDragonsData.isEmpty {
            collectedDragons = []
        } else {
            collectedDragons = try decoder.decode([CollectedDragon].self, from: collectedDragonsData)
        }
        
        return GameData(habitProgresses: habitProgresses, collectedDragons: collectedDragons)
    }
    
    /// Actualiza el modelo SwiftData desde GameData
    func update(from gameData: GameData) throws {
        let encoder = JSONEncoder()
        
        // Convertir el diccionario a array de diccionarios para codificación
        let progressArray = gameData.habitProgresses.map { key, value in
            [key.uuidString: value]
        }
        self.habitProgressesData = try encoder.encode(progressArray)
        self.collectedDragonsData = try encoder.encode(gameData.collectedDragons)
        self.lastUpdated = Date()
    }
}

