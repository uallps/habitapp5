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
    
    // Propiedades futuras para gamificación
    @Published var totalPoints: Int = 0
    @Published var currentLevel: Int = 1
    @Published var unlockedAchievements: [String] = []
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
        loadGameData()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observar cambios en hábitos para actualizar puntos
        NotificationCenter.default.publisher(for: .habitCompleted)
            .sink { [weak self] notification in
                self?.handleHabitCompleted(notification)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    private func loadGameData() {
        // TODO: Cargar datos de gamificación desde SwiftData
        // Por ahora, datos de ejemplo
        totalPoints = 0
        currentLevel = 1
        unlockedAchievements = []
    }
    
    // MARK: - Event Handlers
    
    private func handleHabitCompleted(_ notification: Notification) {
        // TODO: Implementar lógica cuando se complete un hábito
        // Calcular puntos, verificar logros, etc.
    }
    
    // MARK: - Public Methods
    
    func calculatePoints(for habit: Habito) -> Int {
        // TODO: Implementar cálculo de puntos según dificultad, racha, etc.
        return 10
    }
    
    func checkForNewAchievements() {
        // TODO: Verificar si se desbloquearon nuevos logros
    }
    
    func calculateLevelProgress() -> Double {
        // TODO: Calcular progreso hacia el siguiente nivel
        return 0.0
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let habitCompleted = Notification.Name("habitCompleted")
}
