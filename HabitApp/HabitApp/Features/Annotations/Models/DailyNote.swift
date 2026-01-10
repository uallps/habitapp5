//
//  DailyNote.swift
//  HabitApp
//
//  Created on 04/01/26.
//

import Foundation

/// Modelo para las notas diarias de un hábito
struct DailyNote: Identifiable, Codable, Hashable {
    let id: UUID
    let habitId: UUID
    let date: Date
    var content: String
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        habitId: UUID,
        date: Date,
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.habitId = habitId
        self.date = date
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Obtener la fecha normalizada (sin hora) para comparación
    var normalizedDate: Date {
        Calendar.current.startOfDay(for: date)
    }
    
    /// Verificar si la nota es de hoy
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Obtener fecha formateada
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
