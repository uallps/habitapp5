//
//  GameModels.swift
//  HabitApp
//
//  Modelos de datos para el plugin de gamificación
//

import Foundation
import SwiftData

// MARK: - Game Profile (Futuro modelo SwiftData)

/// Perfil de gamificación del usuario
/// TODO: Convertir a @Model cuando se implemente persistencia
struct GameProfile: Codable {
    var totalPoints: Int
    var currentLevel: Int
    var experiencePoints: Int
    var lastUpdated: Date
    
    init(
        totalPoints: Int = 0,
        currentLevel: Int = 1,
        experiencePoints: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.totalPoints = totalPoints
        self.currentLevel = currentLevel
        self.experiencePoints = experiencePoints
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Achievement (Futuro modelo SwiftData)

/// Logro desbloqueable
/// TODO: Convertir a @Model cuando se implemente persistencia
struct Achievement: Codable, Identifiable {
    var id: UUID
    var name: String
    var description: String
    var icon: String
    var isUnlocked: Bool
    var unlockedDate: Date?
    var requiredPoints: Int?
    var requiredStreak: Int?
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        icon: String,
        isUnlocked: Bool = false,
        unlockedDate: Date? = nil,
        requiredPoints: Int? = nil,
        requiredStreak: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
        self.requiredPoints = requiredPoints
        self.requiredStreak = requiredStreak
    }
}

// MARK: - Point Transaction (Futuro modelo SwiftData)

/// Registro de transacción de puntos
/// TODO: Convertir a @Model cuando se implemente persistencia
struct PointTransaction: Codable, Identifiable {
    var id: UUID
    var habitId: UUID
    var points: Int
    var reason: String
    var timestamp: Date
    
    init(
        id: UUID = UUID(),
        habitId: UUID,
        points: Int,
        reason: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.habitId = habitId
        self.points = points
        self.reason = reason
        self.timestamp = timestamp
    }
}
