//
//  SwiftDataStorageProvider.swift
//  HabitApp
//
//  Created by Aula03 on 5/11/25.
//
import Foundation
import SwiftData

class SwiftDataStorageProvider: StorageProvider {

    static let shared = SwiftDataStorageProvider()

    private let modelContainer: ModelContainer
    private let context: ModelContext

    init(){
        do {
            self.modelContainer = try ModelContainer(for: Habito.self)
            self.context = ModelContext(self.modelContainer)
        } catch {
            fatalError("Failed to initialize storage provider: \(error)")
       }
    }

    func loadHabits() async throws -> [Habito] {
        let descriptor = FetchDescriptor<Habito>() // Use FetchDescriptor
        let habits = try context.fetch(descriptor)
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
    }
}
