//
//  StatisticsModel.swift
//  HabitApp
//
//  Created on 02/01/26.
//
import Foundation

struct StatisticsModel {
    let totalHabits: Int
    let completedToday: Int
    let activeHabits: Int
    let averageCompletionRate: Double /// Completitud promedio (0.0 - 1.0)
    let completionsLastWeek: Int
    let completionsThisMonth: Int
    let mostCompletedHabit: HabitSummary?
    let mostActiveCategory: UUID?
    let activeByPriority: (high: Int, medium: Int, low: Int)
}

struct HabitSummary {
    let id: UUID
    let title: String
    let completionCount: Int
    let category: UUID?
}

/// Detalle de una completitud individual
struct CompletionDetail: Identifiable {
    let id = UUID()
    let habitTitle: String
    let habitId: UUID
    let completionDate: Date
    let category: UUID?
}

/// Por período de tiempo
struct PeriodStatistics {
    let period: String // "Hoy", "Esta Semana", "Este Mes"
    let completions: Int
    let targetHabits: Int
    let completionRate: Double
}

/// Por categoría
struct CategoryStatistics: Identifiable {
    let id: UUID
    let categoryId: UUID
    let categoryName: String
    let habitCount: Int
    let totalCompletions: Int
    let averageCompletionRate: Double
}
