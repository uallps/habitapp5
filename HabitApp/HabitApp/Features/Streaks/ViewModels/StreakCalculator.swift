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
        
        // Validación: necesitamos al menos una fecha de completitud
        guard !habit.fechaCompletitud.isEmpty else {
            print("⚠️ [StreakCalculator] Sin fechas de completitud registradas")
            return StreakData(currentStreak: 0, longestStreak: 0, lastCompletionDate: nil)
        }
        
        // Normalizar fechas de completitud
        let completedDatesSet = Set(habit.fechaCompletitud.map { calendar.startOfDay(for: $0) })
        print("✅ [StreakCalculator] Fechas completadas: \(completedDatesSet.count)")
        
        // Usar la fecha de completitud más antigua como punto de inicio
        guard let oldestCompletion = completedDatesSet.min() else {
            print("⚠️ [StreakCalculator] No se pudo determinar fecha más antigua")
            return StreakData(currentStreak: 0, longestStreak: 0, lastCompletionDate: nil)
        }
        
        let startDate = oldestCompletion
        
        print("📅 [StreakCalculator] Rango: \(startDate.formatted(date: .abbreviated, time: .omitted)) -> \(today.formatted(date: .abbreviated, time: .omitted))")
        
        // 1. Generar todas las fechas esperadas desde el inicio hasta hoy (INCLUSIVE)
        var expectedDates: [Date] = []
        var currentDate = startDate
        
        while currentDate <= today {
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
        
        // Debug: Mostrar últimas 10 fechas esperadas
        print("🔍 [StreakCalculator] Últimas fechas esperadas:")
        for date in expectedDates.reversed().prefix(10) {
            let completed = completedDatesSet.contains(date) ? "✅" : "❌"
            print("  \(completed) \(date.formatted(date: .abbreviated, time: .omitted))")
        }
        
        // 2. Calcular racha ACTUAL (desde hoy hacia atrás, se detiene en el primer incompleto)
        var currentStreak = 0
        var foundIncomplete = false
        var isFirstDate = true // Para identificar si estamos en la fecha más reciente (hoy)
        
        for expectedDate in expectedDates.reversed() {
            let isCompleted = completedDatesSet.contains(expectedDate)
            let isToday = calendar.isDate(expectedDate, inSameDayAs: today)
            
            if isCompleted && !foundIncomplete {
                // Día completado: seguimos contando la racha actual
                currentStreak += 1
            } else if !isCompleted {
                // Día NO completado
                if isToday {
                    // EXCEPCIÓN: Si es HOY, no rompemos la racha pero tampoco sumamos
                    print("⚠️ [StreakCalculator] Hoy está esperado pero no completado (no rompe racha)")
                } else {
                    // Cualquier otro día pasado esperado y no completado SÍ rompe la racha
                    if !foundIncomplete {
                        print("🔴 [StreakCalculator] Racha actual rota en: \(expectedDate.formatted(date: .abbreviated, time: .omitted))")
                        foundIncomplete = true
                    }
                    // Ya no incrementamos currentStreak nunca más
                }
            }
            
            isFirstDate = false
        }
        
        // 3. Calcular racha MÁXIMA (mejor secuencia en todo el historial)
        var longestStreak = 0
        var tempStreak = 0
        
        for expectedDate in expectedDates {
            let isCompleted = completedDatesSet.contains(expectedDate)
            
            if isCompleted {
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)
            } else {
                tempStreak = 0
            }
        }
        
        print("🔥 [StreakCalculator] RESULTADO: current=\(currentStreak), longest=\(longestStreak)")
        
        // 4. Obtener la última fecha de completitud
        let lastCompletion = completedDatesSet.max()
        
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