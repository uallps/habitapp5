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
        let savedHabits = try await self.loadHabits()
        for habit in savedHabits {
            context.delete(habit)
        }
        for habit in habits {
            context.insert(habit)
        }
        try context.save()
        print("[DEBUG] SwiftDataStorageProvider: Habitos guardados: \(habits.map { $0.title })")
    }
}
