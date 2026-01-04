//
//  GameModels.swift
//  HabitApp
//
//  Modelos de datos para el plugin de gamificación
//

import Foundation
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
    var dragonSeed: Int // Semilla para mantener el mismo dragón adulto
    
    init(habitId: UUID, purchasedItemIds: [String] = [], dragonSeed: Int = Int.random(in: 0...99999)) {
        self.id = habitId
        self.purchasedItemIds = purchasedItemIds
        self.dragonSeed = dragonSeed
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

// MARK: - Game Data

/// Datos completos del juego (contiene progresión de todos los hábitos)
struct GameData: Codable {
    var habitProgresses: [UUID: HabitGameProgress]
    
    init(habitProgresses: [UUID: HabitGameProgress] = [:]) {
        self.habitProgresses = habitProgresses
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
}
