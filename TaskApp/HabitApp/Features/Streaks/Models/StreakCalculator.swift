//
//  StreakCalculator.swift
//  HabitApp
//
//  Created on 3/1/26.
//

import Foundation

/// Datos de racha calculados para un hábito
struct StreakData {
    /// Racha actual (consecutiva desde el más reciente)
    let currentStreak: Int
    
    /// La racha más larga alcanzada
    let longestStreak: Int
    
    /// Fecha de la última completitud registrada
    let lastCompletionDate: Date?
}

/// Calculadora de rachas para hábitos
struct StreakCalculator {
    
    /// Calcula las estadísticas de racha para un hábito dado
    /// - Parameter habit: El hábito para el cual calcular las rachas
    /// - Returns: StreakData con la racha actual, mejor racha y última fecha
    static func calculate(for habit: Habito) -> StreakData {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Validaciones básicas
        guard let startDate = habit.fechaInicio else {
            return StreakData(currentStreak: 0, longestStreak: 0, lastCompletionDate: nil)
        }
        
        // 1. Generar todas las fechas esperadas desde el inicio hasta hoy
        var expectedDates: [Date] = []
        var currentDate = calendar.startOfDay(for: startDate)
        
        while currentDate <= today {
            if habit.debeRealizarse(en: currentDate) {
                expectedDates.append(currentDate)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        guard !expectedDates.isEmpty else {
            return StreakData(currentStreak: 0, longestStreak: 0, lastCompletionDate: nil)
        }
        
        // 2. Calcular racha actual y mejor racha
        var currentStreak = 0
        var tempStreak = 0
        var longestStreak = 0
        var brokeCurrent = false
        
        // Recorrer desde la fecha más reciente hacia atrás
        for expectedDate in expectedDates.reversed() {
            let isCompleted = habit.estaCompletado(en: expectedDate)
            
            if isCompleted {
                tempStreak += 1
                
                // Solo incrementar racha actual si no se ha roto antes
                if !brokeCurrent {
                    currentStreak += 1
                }
            } else {
                // Solo romper racha si es una fecha pasada
                // Si es hoy y no está completado, no rompe la racha aún
                if expectedDate < today {
                    brokeCurrent = true
                    tempStreak = 0
                }
            }
            
            // Actualizar mejor racha
            longestStreak = max(longestStreak, tempStreak)
        }
        
        // 3. Obtener la última fecha de completitud
        let lastCompletion = habit.fechaCompletitud.max()
        
        return StreakData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastCompletionDate: lastCompletion
        )
    }
    
    /// Calcula las fechas esperadas para un hábito en un rango de fechas
    /// - Parameters:
    ///   - habit: El hábito
    ///   - startDate: Fecha de inicio del rango
    ///   - endDate: Fecha de fin del rango
    /// - Returns: Array de fechas en las que el hábito debería realizarse
    static func expectedDates(for habit: Habito, from startDate: Date, to endDate: Date) -> [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        var currentDate = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        
        while currentDate <= end {
            if habit.debeRealizarse(en: currentDate) {
                dates.append(currentDate)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dates
    }
    
    /// Calcula el porcentaje de completitud para un hábito en un periodo
    /// - Parameters:
    ///   - habit: El hábito
    ///   - startDate: Fecha de inicio del periodo
    ///   - endDate: Fecha de fin del periodo
    /// - Returns: Porcentaje de 0.0 a 1.0
    static func completionRate(for habit: Habito, from startDate: Date, to endDate: Date) -> Double {
        let expected = expectedDates(for: habit, from: startDate, to: endDate)
        guard !expected.isEmpty else { return 0.0 }
        
        let completed = expected.filter { habit.estaCompletado(en: $0) }.count
        return Double(completed) / Double(expected.count)
    }
}
