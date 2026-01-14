//
//  SwiftDataStorageProvider.swift
//  HabitApp
//
//  Created by Aula03 on 5/11/25.
//
import Foundation
import SwiftData

class SwiftDataContext {
    static var shared: ModelContext?
    
    static func initialize(with models: [any PersistentModel.Type]) {
        do {
            let schema = Schema(models)
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            shared = ModelContext(container)
        } catch {
            fatalError("Failed to initialize SwiftData context: \(error)")
        }
    }
}

@MainActor
class SwiftDataStorageProvider: StorageProvider {

    static let shared = SwiftDataStorageProvider()

    private var context: ModelContext {
        guard let context = SwiftDataContext.shared else {
            fatalError("SwiftData context not initialized. Call SwiftDataContext.initialize first")
        }
        return context
    }

    init(){
        
    }

    func loadHabits() async throws -> [Habito] {
        let descriptor = FetchDescriptor<Habito>() // Use FetchDescriptor
        let habits = try context.fetch(descriptor)
        print("[DEBUG] SwiftDataStorageProvider: Habitos cargados: \(habits.map { $0.title })")
        return habits
    }

    func saveHabits(habits: [Habito]) async throws {
        // Cargar hábitos existentes
        let savedHabits = try await self.loadHabits()
        let savedIds = Set(savedHabits.map { $0.id })
        let newIds = Set(habits.map { $0.id })
        
        // Eliminar hábitos que ya no están en la lista
        let idsToDelete = savedIds.subtracting(newIds)
        for habit in savedHabits where idsToDelete.contains(habit.id) {
            context.delete(habit)
        }
        
        // Insertar solo los hábitos nuevos (que no existían antes)
        let idsToInsert = newIds.subtracting(savedIds)
        for habit in habits where idsToInsert.contains(habit.id) {
            context.insert(habit)
        }
        
        // Los hábitos existentes ya están en el contexto y se actualizarán automáticamente
        // porque SwiftData trackea los cambios en objetos @Model
        
        try context.save()
        print("[DEBUG] SwiftDataStorageProvider: Habitos guardados: \(habits.map { $0.title })")
    }
}
