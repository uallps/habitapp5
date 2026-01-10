//
//  StorageProvider.swift
//  HabitApp
//
//  Created by Aula03 on 5/11/25.
//
protocol StorageProvider {
    func loadHabits() async throws -> [Habito]
    func saveHabits(habits: [Habito]) async throws
}
