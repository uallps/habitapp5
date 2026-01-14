//
//  StatisticsViewModel.swift
//  HabitApp
//
//  Created on 02/01/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class StatisticsViewModel: ObservableObject {
    @Published var statistics: StatisticsModel?
    @Published var periodStatistics: [PeriodStatistics] = []
    @Published var categoryStatistics: [CategoryStatistics] = []
    @Published var isLoading: Bool = false
    @Published var weekCompletions: [CompletionDetail] = []
    @Published var monthCompletions: [CompletionDetail] = []
    
    private let storageProvider: StorageProvider
    private var allHabits: [Habito] = []
    
    init(storageProvider: StorageProvider) {
        self.storageProvider = storageProvider
    }
    
    /// Carga y calcula todas las estadísticas
    func loadStatistics() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let habits = try await storageProvider.loadHabits()
            allHabits = habits
            calculateStatistics(from: habits)
            calculateDetailedCompletions(from: habits)
        } catch {
            print("[ERROR] Failed to load statistics: \(error)")
        }
    }
    
    /// Calcula las completitudes detalladas por período
    private func calculateDetailedCompletions(from habits: [Habito]) {
        let now = Date()
        let calendar = Calendar.current
        
        // Completitudes última semana
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        var weekDetails: [CompletionDetail] = []
        
        for habit in habits {
            let weekCompletionDates = habit.fechaCompletitud.filter { $0 >= oneWeekAgo && $0 <= now }
            for date in weekCompletionDates {
                weekDetails.append(CompletionDetail(
                    habitTitle: habit.title,
                    habitId: habit.id,
                    completionDate: date,
                    category: habit.categoria
                ))
            }
        }
        
        // Completitudes este mes
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        var monthDetails: [CompletionDetail] = []
        
        for habit in habits {
            let monthCompletionDates = habit.fechaCompletitud.filter { $0 >= startOfMonth && $0 <= now }
            for date in monthCompletionDates {
                monthDetails.append(CompletionDetail(
                    habitTitle: habit.title,
                    habitId: habit.id,
                    completionDate: date,
                    category: habit.categoria
                ))
            }
        }
        
        // Ordenar por fecha descendente (más recientes primero)
        self.weekCompletions = weekDetails.sorted { $0.completionDate > $1.completionDate }
        self.monthCompletions = monthDetails.sorted { $0.completionDate > $1.completionDate }
    }
    
    /// Calcula las estadísticas
    private func calculateStatistics(from habits: [Habito]) {
        let now = Date()
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Lunes como primer día de la semana
        let totalHabits = habits.count
        // Hábitos activos (sin fecha fin o fecha fin >= hoy)
        let activeHabitsList = habits.filter { $0.isActive(at: now) }
        let activeHabits = activeHabitsList.count
        
        // Contar hábitos activos por prioridad
        let highPriority = activeHabitsList.filter { $0.prioridad == .high }.count
        let mediumPriority = activeHabitsList.filter { $0.prioridad == .medium }.count
        let lowPriority = activeHabitsList.filter { $0.prioridad == .low }.count
        
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
            mostActiveCategory: mostActiveCategory,
            activeByPriority: (high: highPriority, medium: mediumPriority, low: lowPriority)
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
        // Solo considerar hábitos activos
        let activeHabits = habits.filter { $0.isActive() }
        guard !activeHabits.isEmpty else { return 0.0 }
        
        var totalRate = 0.0
        var validHabitsCount = 0
        
        for habit in activeHabits {
            if let rate = calculateCompletionRateForHabit(habit, calendar: calendar) {
                totalRate += rate
                validHabitsCount += 1
            }
        }
        
        let finalRate = validHabitsCount > 0 ? totalRate / Double(validHabitsCount) : 0.0
        return finalRate
    }
    
    /// Calcula la tasa de completitud para un hábito individual
    private func calculateCompletionRateForHabit(_ habit: Habito, calendar: Calendar) -> Double? {
        let now = Date()
        
        // Solo calcular para hábitos activos
        guard habit.isActive(at: now) else { return nil }
        
        // Determinar fecha de inicio
        guard let startDate = habit.fechaInicio else { return nil }
        
        // No calcular si la fecha de inicio es futura
        guard startDate <= now else { return nil }
        
        if let fechaFin = habit.fechaFin {
            // CON FECHA DE FINALIZACIÓN: Calcular sobre todo el intervalo
            // Usar el intervalo completo (inicio a fin) para calcular el 100%
            let endDate = fechaFin // NO limitar a 'now', usar la fecha fin completa
            
            // No calcular si la fecha de fin es anterior a la fecha de inicio
            guard endDate >= startDate else { return nil }
            
            // Contar completitudes válidas (solo hasta hoy para no contar futuro)
            let validCompletions = habit.fechaCompletitud.filter { completionDate in
                completionDate >= calendar.startOfDay(for: startDate) && 
                completionDate <= calendar.startOfDay(for: min(endDate, now))
            }
            
            let actualCompletions = validCompletions.count
            
            // Calcular completitudes esperadas en TODO el intervalo (inicio a fin)
            let expectedCompletions = calculateExpectedCompletions(
                for: habit, 
                from: startDate, 
                to: endDate, // Usar fecha fin completa, no limitada a hoy
                calendar: calendar
            )
            
            guard expectedCompletions > 0 else { return nil }
            
            let rate = Double(actualCompletions) / Double(expectedCompletions)
            return min(1.0, rate) // Cap al 100%
            
        } else {
            // SIN FECHA DE FINALIZACIÓN: Calcular solo para el período actual
            let vecesPorPeriodo = habit.vecesPorPeriodoActual
            
            switch habit.tipoFrecuenciaActual {
            case .semanal:
                // Calcular solo para la semana actual (lunes a domingo)
                var weekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
                weekComponents.weekday = 2 // Lunes
                let startOfWeek = calendar.date(from: weekComponents)!
                let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
                
                // Contar completitudes en esta semana
                let weekCompletions = habit.fechaCompletitud.filter { completionDate in
                    completionDate >= startOfWeek && completionDate <= min(endOfWeek, now)
                }
                
                let actualCompletions = weekCompletions.count
                let expectedCompletions = vecesPorPeriodo
                
                guard expectedCompletions > 0 else { return nil }
                
                let rate = Double(actualCompletions) / Double(expectedCompletions)
                return min(1.0, rate)
                
            case .mensual:
                // Calcular solo para el mes actual
                let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
                
                // Contar completitudes en este mes
                let monthCompletions = habit.fechaCompletitud.filter { completionDate in
                    completionDate >= startOfMonth && completionDate <= min(endOfMonth, now)
                }
                
                let actualCompletions = monthCompletions.count
                let expectedCompletions = vecesPorPeriodo
                
                guard expectedCompletions > 0 else { return nil }
                
                let rate = Double(actualCompletions) / Double(expectedCompletions)
                return min(1.0, rate)
            }
        }
    }
    
    /// Calcula el número de completitudes esperadas en un rango de fechas
    private func calculateExpectedCompletions(for habit: Habito, from startDate: Date, to endDate: Date, calendar: Calendar) -> Int {
        let frequency = habit.tipoFrecuenciaActual
        
        switch frequency {
        case .semanal:
            return calculateWeeklyExpectedCompletions(for: habit, from: startDate, to: endDate, calendar: calendar)
        case .mensual:
            return calculateMonthlyExpectedCompletions(for: habit, from: startDate, to: endDate, calendar: calendar)
        }
    }
    
    /// Calcula completitudes esperadas para hábitos semanales
    private func calculateWeeklyExpectedCompletions(for habit: Habito, from startDate: Date, to endDate: Date, calendar: Calendar) -> Int {
        let vecesPorSemana = habit.vecesPorPeriodoActual
        
        // Si hay fecha fin: calcular según semanas disponibles (lunes-domingo)
        if habit.fechaFin != nil {
            var totalExpected = 0
            var currentDate = calendar.startOfDay(for: startDate)
            let finalDate = calendar.startOfDay(for: endDate)
            
            while currentDate <= finalDate {
                // Obtener inicio de la semana (lunes) para la fecha actual
                var weekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)
                weekComponents.weekday = 2 // Lunes
                let weekStart = calendar.date(from: weekComponents)!
                let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)! // Domingo
                
                // Determinar el rango efectivo de esta semana
                let effectiveStart = max(weekStart, currentDate)
                let effectiveEnd = min(weekEnd, finalDate)
                
                // Calcular días usados en esta semana
                let daysInRange = calendar.dateComponents([.day], from: effectiveStart, to: effectiveEnd).day ?? 0
                let daysUsed = daysInRange + 1 // +1 para incluir el día final
                
                // Para esta semana: usar el mínimo entre días disponibles y veces configuradas
                let expectedThisWeek = min(daysUsed, vecesPorSemana)
                totalExpected += expectedThisWeek
                
                // Avanzar a la siguiente semana
                currentDate = calendar.date(byAdding: .day, value: 1, to: effectiveEnd)!
            }
            
            return totalExpected
        }
        
        // Sin fecha fin: usar vecesPorPeriodo como objetivo de la semana actual
        return vecesPorSemana
    }
    
    /// Calcula completitudes esperadas para hábitos mensuales
    private func calculateMonthlyExpectedCompletions(for habit: Habito, from startDate: Date, to endDate: Date, calendar: Calendar) -> Int {
        let vecesPorMes = habit.vecesPorPeriodoActual
        
        // Si hay fecha fin: calcular según tiempo disponible en cada mes
        if habit.fechaFin != nil {
            var currentMonth = calendar.startOfDay(for: startDate)
            let finalDate = calendar.startOfDay(for: endDate)
            var totalExpected = 0
            
            while currentMonth <= finalDate {
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
                let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart)!
                let monthEnd = calendar.date(byAdding: .day, value: -1, to: nextMonth)!
                
                // Determinar el rango efectivo dentro de este mes
                let effectiveStart = max(monthStart, startDate)
                let effectiveEnd = min(monthEnd, finalDate)
                
                // Días disponibles en este mes
                let daysInRange = calendar.dateComponents([.day], from: effectiveStart, to: effectiveEnd).day ?? 0
                let daysUsed = daysInRange + 1 // +1 para incluir el día final
                
                // Para este mes: usar el mínimo entre días disponibles y veces configuradas
                let expectedThisMonth = min(daysUsed, vecesPorMes)
                totalExpected += expectedThisMonth
                
                // Avanzar al siguiente mes
                currentMonth = nextMonth
            }
            
            return totalExpected
        }
        
        // Sin fecha fin: usar vecesPorPeriodo como objetivo del mes actual
        // Excepción: si vecesPorPeriodo > días del mes actual, usar días del mes
        let now = Date()
        let daysInCurrentMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        
        return min(vecesPorMes, daysInCurrentMonth)
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
        // Obtener inicio de semana con lunes como primer día
        var weekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        weekComponents.weekday = 2 // Lunes
        let startOfWeek = calendar.date(from: weekComponents)!
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        // Hoy
        let todayCompletions = countCompletions(in: habits, from: startOfToday, to: now, calendar: calendar)
        let todayTarget = calculateExpectedCompletionsForPeriod(habits: habits, from: startOfToday, to: startOfToday, calendar: calendar)
        let todayRate = todayTarget > 0 ? Double(todayCompletions) / Double(todayTarget) : 0.0
        
        // Esta Semana
        let weekCompletions = countCompletions(in: habits, from: startOfWeek, to: now, calendar: calendar)
        let weekTarget = calculateExpectedCompletionsForPeriod(habits: habits, from: startOfWeek, to: now, calendar: calendar)
        let weekRate = weekTarget > 0 ? Double(weekCompletions) / Double(weekTarget) : 0.0
        
        // Este Mes
        let monthCompletions = countCompletions(in: habits, from: startOfMonth, to: now, calendar: calendar)
        let monthTarget = calculateExpectedCompletionsForPeriod(habits: habits, from: startOfMonth, to: now, calendar: calendar)
        let monthRate = monthTarget > 0 ? Double(monthCompletions) / Double(monthTarget) : 0.0
        
        self.periodStatistics = [
            PeriodStatistics(period: "Hoy", completions: todayCompletions, targetHabits: todayTarget, completionRate: todayRate),
            PeriodStatistics(period: "Esta Semana", completions: weekCompletions, targetHabits: weekTarget, completionRate: weekRate),
            PeriodStatistics(period: "Este Mes", completions: monthCompletions, targetHabits: monthTarget, completionRate: monthRate)
        ]
    }
    
    /// Calcula el total de completitudes esperadas para un grupo de hábitos en un período
    private func calculateExpectedCompletionsForPeriod(habits: [Habito], from startDate: Date, to endDate: Date, calendar: Calendar) -> Int {
        var total = 0
        
        // Solo considerar hábitos activos
        let activeHabits = habits.filter { $0.isActive(at: endDate) }
        
        for habit in activeHabits {
            if let fechaFin = habit.fechaFin {
                // CON FECHA FIN: calcular basado en días específicos configurados
                let habitStartDate = habit.fechaInicio ?? startDate
                let habitEndDate = fechaFin
                
                // Determinar el rango válido de intersección
                let rangeStart = max(habitStartDate, startDate)
                let rangeEnd = min(habitEndDate, endDate, Date()) // No contar días futuros
                
                // Si el rango es válido, calcular completitudes esperadas
                if rangeStart <= rangeEnd {
                    let expected = calculateExpectedCompletions(
                        for: habit,
                        from: rangeStart,
                        to: rangeEnd,
                        calendar: calendar
                    )
                    total += expected
                }
            } else {
                // SIN FECHA FIN: usar vecesPorPeriodo según el tipo de período que estamos calculando
                // Solo contar si el hábito ya debería estar activo
                guard let habitStart = habit.fechaInicio, habitStart <= Date() else {
                    continue
                }
                
                // Determinar si estamos calculando para hoy, esta semana o este mes
                let isToday = calendar.isDate(startDate, inSameDayAs: endDate)
                let isWeek = !isToday && calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0 <= 7
                let isMonth = !isToday && !isWeek
                
                let vecesPorPeriodo = habit.vecesPorPeriodoActual
                
                if isToday {
                    // Para "hoy", verificar si el hábito debe realizarse hoy
                    if habit.debeRealizarse(en: startDate) {
                        total += 1
                    }
                } else if isWeek {
                    // Para "esta semana", usar vecesPorPeriodo solo si es semanal
                    if habit.tipoFrecuenciaActual == .semanal {
                        total += vecesPorPeriodo
                    } else {
                        // Mensual: contar días específicos en esta semana
                        var currentDate = startDate
                        while currentDate <= min(endDate, Date()) {
                            if habit.debeRealizarse(en: currentDate) {
                                total += 1
                            }
                            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                        }
                    }
                } else if isMonth {
                    // Para "este mes", usar vecesPorPeriodo solo si es mensual
                    if habit.tipoFrecuenciaActual == .mensual {
                        total += vecesPorPeriodo
                    } else {
                        // Semanal: calcular cuántas veces debería hacerse en el mes
                        let daysInPeriod = calendar.dateComponents([.day], from: startDate, to: min(endDate, Date())).day ?? 0
                        let weeksInPeriod = Double(daysInPeriod) / 7.0
                        total += Int(ceil(weeksInPeriod * Double(vecesPorPeriodo)))
                    }
                }
            }
        }
        
        return total
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
