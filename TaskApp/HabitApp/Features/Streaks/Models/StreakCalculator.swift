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
        
        print("🔥 [StreakCalculator] INICIANDO CÁLCULO para '\(habit.title)'")
        
        // Validaciones básicas
        guard let startDate = habit.fechaInicio else {
            print("⚠️ [StreakCalculator] Sin fecha de inicio")
            return StreakData(currentStreak: 0, longestStreak: 0, lastCompletionDate: nil)
        }
        
        // 1. Generar todas las fechas esperadas desde el inicio hasta hoy (INCLUSIVE)
        var expectedDates: [Date] = []
        var currentDate = calendar.startOfDay(for: startDate)
        let endDate = today
        
        print("📅 [StreakCalculator] Rango: \(startDate.formatted(date: .abbreviated, time: .omitted)) -> \(today.formatted(date: .abbreviated, time: .omitted))")
        
        while currentDate <= endDate {
            if habit.debeRealizarse(en: currentDate) {
                expectedDates.append(currentDate)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        guard !expectedDates.isEmpty else {
            print("⚠️ [StreakCalculator] No hay fechas esperadas")
            return StreakData(currentStreak: 0, longestStreak: 0, lastCompletionDate: nil)
        }
        
        print("📊 [StreakCalculator] Total fechas esperadas: \(expectedDates.count)")
        
        // Normalizar fechas de completitud para comparación
        let completedDatesSet = Set(habit.fechaCompletitud.map { calendar.startOfDay(for: $0) })
        
        print("✅ [StreakCalculator] Fechas completadas: \(completedDatesSet.count)")
        
        // 2. Calcular racha actual (desde el más reciente hacia atrás)
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        
        // Debug: Mostrar últimas 10 fechas esperadas
        print("🔍 [StreakCalculator] Últimas fechas esperadas:")
        for date in expectedDates.reversed().prefix(10) {
            let completed = completedDatesSet.contains(date) ? "✅" : "❌"
            print("  \(completed) \(date.formatted(date: .abbreviated, time: .omitted))")
        }
        
        // Recorrer fechas esperadas en orden descendente (más reciente primero)
        var foundIncomplete = false
        
        for expectedDate in expectedDates.reversed() {
            let isCompleted = completedDatesSet.contains(expectedDate)
            
            if isCompleted {
                // Fecha completada
                tempStreak += 1
                
                // Solo incrementar currentStreak si no hemos encontrado ninguna fecha incompleta
                if !foundIncomplete {
                    currentStreak += 1
                }
            } else {
                // Fecha NO completada que se esperaba
                // Si aún no habíamos encontrado ninguna incompleta, marcar que la racha actual termina
                if !foundIncomplete {
                    foundIncomplete = true
                    print("🔴 [StreakCalculator] Racha rota en: \(expectedDate.formatted(date: .abbreviated, time: .omitted))")
                }
                
                // Resetear la racha temporal
                tempStreak = 0
            }
            
            // Actualizar mejor racha
            longestStreak = max(longestStreak, tempStreak)
        }
        
        // Asegurar que longest >= current
        longestStreak = max(longestStreak, currentStreak)
        
        print("🔥 [StreakCalculator] RESULTADO: current=\(currentStreak), longest=\(longestStreak)")
        
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
        
        let calendar = Calendar.current
        let completedDatesSet = Set(expected.filter { habit.estaCompletado(en: $0) })
        
        return Double(completedDatesSet.count) / Double(expected.count)
    }
}