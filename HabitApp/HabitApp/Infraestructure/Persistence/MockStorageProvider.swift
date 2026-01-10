//
//  MockStorageProvider.swift
//  HabitApp
//
//  Created by Aula03 on 5/11/25.
//
import Foundation

class MockStorageProvider: StorageProvider {
    private var storedHabits: [Habito] = [
        Habito(title: "Mock Habit 1", descripcion: "Descripcion"),
        Habito(title: "Mock Habit 2", descripcion: "Descripcion", diasSemana: [2, 4, 6], fechaCompletitud: [Date()])
    ]
    
    func loadHabits() async throws -> [Habito] {
        return storedHabits
    }
    
    func saveHabits(habits: [Habito]) async throws {
        storedHabits = habits
    }
}
