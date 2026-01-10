//
//  DailyNoteViewModel.swift
//  HabitApp
//
//  Created on 04/01/26.
//

import Foundation
import SwiftUI
import Combine 

/// ViewModel para gestionar notas diarias
@MainActor
class DailyNoteViewModel: ObservableObject {
    private let storageKey = "daily_notes_storage"
    @Published private(set) var notes: [DailyNote] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        Task {
            await loadNotes()
        }
    }
    
    // MARK: - Persistencia
    
    /// Cargar notas desde UserDefaults
    @MainActor
    func loadNotes() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let data = UserDefaults.standard.data(forKey: storageKey) else {
                notes = []
                return
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            notes = try decoder.decode([DailyNote].self, from: data)
        } catch {
            errorMessage = "Error al cargar notas: \(error.localizedDescription)"
            notes = []
        }
    }
    
    /// Guardar notas en UserDefaults
    @MainActor
    private func saveNotes() async {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(notes)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            errorMessage = "Error al guardar notas: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Operaciones CRUD
    
    /// Obtener nota para un hábito en una fecha específica
    func getNote(for habitId: UUID, on date: Date) -> DailyNote? {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return notes.first { note in
            note.habitId == habitId &&
            Calendar.current.isDate(note.normalizedDate, inSameDayAs: normalizedDate)
        }
    }
    
    /// Obtener todas las notas de un hábito
    func getNotes(for habitId: UUID) -> [DailyNote] {
        notes.filter { $0.habitId == habitId }
            .sorted { $0.date > $1.date }
    }
    
    /// Crear o actualizar nota
    @MainActor
    func saveNote(habitId: UUID, date: Date, content: String) async {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        
        if let index = notes.firstIndex(where: { note in
            note.habitId == habitId &&
            Calendar.current.isDate(note.normalizedDate, inSameDayAs: normalizedDate)
        }) {
            // Actualizar nota existente
            notes[index] = DailyNote(
                id: notes[index].id,
                habitId: habitId,
                date: normalizedDate,
                content: content,
                createdAt: notes[index].createdAt,
                updatedAt: Date()
            )
        } else {
            // Crear nueva nota
            let newNote = DailyNote(
                habitId: habitId,
                date: normalizedDate,
                content: content
            )
            notes.append(newNote)
        }
        
        await saveNotes()
    }
    
    /// Eliminar nota
    @MainActor
    func deleteNote(_ note: DailyNote) async {
        notes.removeAll { $0.id == note.id }
        await saveNotes()
    }
    
    /// Eliminar todas las notas de un hábito
    @MainActor
    func deleteAllNotes(for habitId: UUID) async {
        notes.removeAll { $0.habitId == habitId }
        await saveNotes()
    }
}
