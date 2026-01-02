//
//  StatisticsViewModel.swift
//  HabitApp
//
//  Created on 02/01/26.
//

import Foundation
internal import SwiftUI
import Combine

@MainActor
class StatisticsViewModel: ObservableObject {
    @Published var statistics: StatisticsModel?
    @Published var periodStatistics: [PeriodStatistics] = []
    @Published var categoryStatistics: [CategoryStatistics] = []
    @Published var isLoading: Bool = false
    
    private let storageProvider: StorageProvider
    
    init(storageProvider: StorageProvider = SwiftDataStorageProvider()) {
        self.storageProvider = storageProvider
    }
    
    /// Carga y calcula todas las estadísticas
    func loadStatistics() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let habits = try await storageProvider.loadHabits()
            calculateStatistics(from: habits)
        } catch {
            print("[ERROR] Failed to load statistics: \(error)")
        }
    }
    
    /// Calcula las estadísticas
    private func calculateStatistics(from habits: [Habito]) {
        let now = Date()
        let calendar = Calendar.current
        let totalHabits = habits.count
        // Hábitos activos (sin fecha fin o fecha fin futura)
        let activeHabits = habits.filter { habit in
            guard let endDate = habit.fechaFin else { return true }
            return endDate >= now
        }.count
        
        // Completitudes de hoy
        let startOfToday = calendar.startOfDay(for: now)
        let completedToday = habits.reduce(0) { count, habit in
            let todayCompletions = habit.fechaCompletitud.filter { completionDate in
                calendar.isDate(completionDate, inSameDayAs: startOfToday)
            }.count
            return count + todayCompletions
        }
        
        // Completitudes última semana
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        let completionsLastWeek = countCompletions(in: habits, from: oneWeekAgo, to: now, calendar: calendar)
        
        // Completitudes este mes
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let completionsThisMonth = countCompletions(in: habits, from: startOfMonth, to: now, calendar: calendar)
        
        // Hábito más completado
        let mostCompletedHabit = findMostCompletedHabit(from: habits)
        
        // Tasa de completitud promedio
        let averageCompletionRate = calculateAverageCompletionRate(from: habits, calendar: calendar)
        
        // Categoría con más hábitos
        let mostActiveCategory = findMostActiveCategory(from: habits)
        

        self.statistics = StatisticsModel(
            totalHabits: totalHabits,
            completedToday: completedToday,
            activeHabits: activeHabits,
            averageCompletionRate: averageCompletionRate,
            completionsLastWeek: completionsLastWeek,
            completionsThisMonth: completionsThisMonth,
            mostCompletedHabit: mostCompletedHabit,
            mostActiveCategory: mostActiveCategory
        )
        
        // Calcular estadísticas por período
        calculatePeriodStatistics(from: habits, calendar: calendar)
        
        // Calcular estadísticas por categoría
        calculateCategoryStatistics(from: habits, calendar: calendar)
    }
    
    /// Cuenta completitudes en un rango de fechas
    private func countCompletions(in habits: [Habito], from startDate: Date, to endDate: Date, calendar: Calendar) -> Int {
        var count = 0
        for habit in habits {
            count += habit.fechaCompletitud.filter { date in
                date >= startDate && date <= endDate
            }.count
        }
        return count
    }
    
    /// Encuentra el hábito con más completitudes
    private func findMostCompletedHabit(from habits: [Habito]) -> HabitSummary? {
        guard !habits.isEmpty else { return nil }
        
        let habitWithMostCompletions = habits.max { $0.fechaCompletitud.count < $1.fechaCompletitud.count }
        
        guard let habit = habitWithMostCompletions, !habit.fechaCompletitud.isEmpty else { return nil }
        
        return HabitSummary(
            id: habit.id,
            title: habit.title,
            completionCount: habit.fechaCompletitud.count,
            category: habit.categoria
        )
    }
    
    /// Calcula la tasa de completitud promedio
    private func calculateAverageCompletionRate(from habits: [Habito], calendar: Calendar) -> Double {
        guard !habits.isEmpty else { return 0.0 }
        var totalRate = 0.0
        var validHabitsCount = 0
        
        for habit in habits {
            // Usar valores por defecto si no están configurados
            let startDate = habit.fechaInicio ?? Date()
            let frequency = habit.tipoFrecuencia ?? .semanal
            let timesPerPeriod = habit.vecesPorPeriodo ?? 1
            
            let now = Date()
            let endDate = habit.fechaFin ?? now
            
            // Calcular cuántos períodos han pasado
            if frequency == .semanal {
                let daysPassed = calendar.dateComponents([.day], from: startDate, to: min(endDate, now)).day ?? 0
                let weeksPassed = max(1, daysPassed / 7)
                let expectedCompletions = weeksPassed * timesPerPeriod
                let actualCompletions = habit.fechaCompletitud.count
                
                if expectedCompletions > 0 {
                    let rate = Double(actualCompletions) / Double(expectedCompletions)
                    totalRate += min(1.0, rate)
                    validHabitsCount += 1
                }
            } else {
                // Mensual
                let monthsPassed = calendar.dateComponents([.month], from: startDate, to: min(endDate, now)).month ?? 0
                let periodsCount = max(1, monthsPassed)
                let expectedCompletions = periodsCount * timesPerPeriod
                let actualCompletions = habit.fechaCompletitud.count
                
                if expectedCompletions > 0 {
                    let rate = Double(actualCompletions) / Double(expectedCompletions)
                    totalRate += min(1.0, rate)
                    validHabitsCount += 1
                }
            }
        }
        
        let finalRate = validHabitsCount > 0 ? totalRate / Double(validHabitsCount) : 0.0
        return finalRate
    }
    
    /// Encuentra la categoría más activa
    private func findMostActiveCategory(from habits: [Habito]) -> UUID? {
        let categoryCounts = Dictionary(grouping: habits.compactMap { $0.categoria }, by: { $0 })
            .mapValues { $0.count }
        
        return categoryCounts.max(by: { $0.value < $1.value })?.key
    }
    
    /// Calcula estadísticas por período
    private func calculatePeriodStatistics(from habits: [Habito], calendar: Calendar) {
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        // Hoy
        let todayCompletions = countCompletions(in: habits, from: startOfToday, to: now, calendar: calendar)
        let todayTarget = habits.count // Simplificado: asumimos que cada hábito debería completarse hoy
        let todayRate = todayTarget > 0 ? Double(todayCompletions) / Double(todayTarget) : 0.0
        
        // Esta Semana
        let weekCompletions = countCompletions(in: habits, from: startOfWeek, to: now, calendar: calendar)
        let weekTarget = habits.count * 7
        let weekRate = weekTarget > 0 ? Double(weekCompletions) / Double(weekTarget) : 0.0
        
        // Este Mes
        let monthCompletions = countCompletions(in: habits, from: startOfMonth, to: now, calendar: calendar)
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let monthTarget = habits.count * daysInMonth
        let monthRate = monthTarget > 0 ? Double(monthCompletions) / Double(monthTarget) : 0.0
        
        self.periodStatistics = [
            PeriodStatistics(period: "Hoy", completions: todayCompletions, targetHabits: todayTarget, completionRate: todayRate),
            PeriodStatistics(period: "Esta Semana", completions: weekCompletions, targetHabits: weekTarget, completionRate: weekRate),
            PeriodStatistics(period: "Este Mes", completions: monthCompletions, targetHabits: monthTarget, completionRate: monthRate)
        ]
    }
    
    /// Calcula estadísticas por categoría
    private func calculateCategoryStatistics(from habits: [Habito], calendar: Calendar) {
        let habitsByCategory = Dictionary(grouping: habits.filter { $0.categoria != nil }, by: { $0.categoria! })
        
        var categoryStats: [CategoryStatistics] = []
        
        for (categoryId, categoryHabits) in habitsByCategory {
            let totalCompletions = categoryHabits.reduce(0) { $0 + $1.fechaCompletitud.count }
            let avgRate = calculateAverageCompletionRate(from: categoryHabits, calendar: calendar)
            
            // Obtener nombre de categoría desde CategoryModel
            let categoryName = CategoryModel.allCategories.first(where: { $0.id == categoryId })?.name ?? "Sin nombre"
            
            let stat = CategoryStatistics(
                id: UUID(),
                categoryId: categoryId,
                categoryName: categoryName,
                habitCount: categoryHabits.count,
                totalCompletions: totalCompletions,
                averageCompletionRate: avgRate
            )
            
            categoryStats.append(stat)
        }
        
        // Ordenar por número de hábitos descendente
        self.categoryStatistics = categoryStats.sorted { $0.habitCount > $1.habitCount }
    }
}
