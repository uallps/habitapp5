//
//  GameViewModel.swift
//  HabitApp
//
//  ViewModel para el plugin de gamificación
//

import Foundation
import Combine

@MainActor
final class GameViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var habitos: [Habito] = []
    @Published var selectedHabitoId: UUID?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let storageProvider: StorageProvider
    
    // MARK: - Computed Properties
    
    var selectedHabito: Habito? {
        guard let id = selectedHabitoId else { return nil }
        return habitos.first { $0.id == id }
    }
    
    var nivel: Int {
        guard let habito = selectedHabito else { return 0 }
        return calculateLevel(for: habito)
    }
    
    // MARK: - Initialization
    
    init(storageProvider: StorageProvider) {
        self.storageProvider = storageProvider
        Task {
            await loadHabitos()
        }
    }
    
    // MARK: - Data Loading
    
    func loadHabitos() async {
        isLoading = true
        errorMessage = nil
        
        do {
            habitos = try await storageProvider.loadHabits()
            
            // Seleccionar el primer hábito por defecto si hay alguno
            if selectedHabitoId == nil, let firstHabito = habitos.first {
                selectedHabitoId = firstHabito.id
            }
        } catch {
            errorMessage = "Error al cargar hábitos: \(error.localizedDescription)"
            print("❌ [GameViewModel] Error cargando hábitos: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Level Calculation
    
    /// Calcula el nivel sumando todas las rachas que ha tenido el hábito
    /// - Parameter habito: El hábito para calcular el nivel
    /// - Returns: La suma de todas las rachas individuales
    private func calculateLevel(for habito: Habito) -> Int {
        let calendar = Calendar.current
        
        // Normalizar todas las fechas de completitud
        let completedDatesSet = Set(habito.fechaCompletitud.map { 
            calendar.startOfDay(for: $0) 
        })
        
        guard !completedDatesSet.isEmpty else { return 0 }
        
        // Obtener la fecha más antigua de completitud
        guard let oldestCompletion = completedDatesSet.min() else { return 0 }
        
        // Generar todas las fechas esperadas desde el inicio hasta hoy
        let today = calendar.startOfDay(for: Date())
        var expectedDates: [Date] = []
        var currentDate = oldestCompletion
        
        while currentDate <= today {
            if habito.debeRealizarse(en: currentDate) {
                expectedDates.append(currentDate)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        guard !expectedDates.isEmpty else { return 0 }
        
        // Calcular todas las rachas individuales
        var totalLevel = 0
        var currentStreakLength = 0
        
        for expectedDate in expectedDates {
            let isCompleted = completedDatesSet.contains(expectedDate)
            
            if isCompleted {
                currentStreakLength += 1
            } else {
                // Si había una racha en curso, sumarla al nivel total
                if currentStreakLength > 0 {
                    totalLevel += currentStreakLength
                    currentStreakLength = 0
                }
            }
        }
        
        // No olvidar sumar la última racha si aún está activa
        if currentStreakLength > 0 {
            totalLevel += currentStreakLength
        }
        
        return totalLevel
    }
}
