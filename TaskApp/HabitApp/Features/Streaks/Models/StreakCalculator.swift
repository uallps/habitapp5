// TaskApp/HabitApp/Features/Streaks/Models/StreakCalculator.swift

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
        
        // 1. Generar todas las fechas esperadas desde el inicio hasta hoy (INCLUSIVE)
        var expectedDates: [Date] = []
        var currentDate = calendar.startOfDay(for: startDate)
        
        // Incluir hoy en el rango
        let endDate = today
        
        while currentDate <= endDate {
            if habit.debeRealizarse(en: currentDate) {
                expectedDates.append(currentDate)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        guard !expectedDates.isEmpty else {
            return StreakData(currentStreak: 0, longestStreak: 0, lastCompletionDate: nil)
        }
        
        // 2. Calcular racha actual (desde el más reciente hacia atrás)
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        
        // Recorrer fechas esperadas en orden descendente (más reciente primero)
        for expectedDate in expectedDates.reversed() {
            let isCompleted = habit.estaCompletado(en: expectedDate)
            
            if isCompleted {
                // Fecha completada: incrementar rachas
                currentStreak += 1
                tempStreak += 1
            } else {
                // Fecha NO completada
                // Si es hoy o futuro, no rompe la racha (aún puede completarse)
                // Si es pasado, rompe la racha actual
                if expectedDate < today {
                    // Ya pasó y no se completó -> romper racha actual
                    currentStreak = 0
                }
                // La racha temporal se resetea siempre que no está completado
                tempStreak = 0
            }
            
            // Actualizar mejor racha
            longestStreak = max(longestStreak, tempStreak)
        }
        
        // 3. Obtener la última fecha de completitud
        let lastCompletion = habit.fechaCompletitud.max()
        
        return StreakData(
            currentStreak: currentStreak,
            longestStreak: max(longestStreak, currentStreak), // Asegurar que longest >= current
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