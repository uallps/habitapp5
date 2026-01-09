//
//  DailyNoteView.swift
//  HabitApp
//
//  Created on 04/01/26.
//

import SwiftUI

/// Vista para gestionar notas diarias de un hábito
struct DailyNoteView: View {
    let habit: Habito
    @StateObject private var viewModel = DailyNoteViewModel()
    @State private var selectedDate = Date()
    @State private var noteContent = ""
    @State private var isEditing = false
    @State private var showHistory = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Selector de fecha
            HStack {
                Text("Fecha:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .labelsHidden()
                .onChange(of: selectedDate) { _, _ in
                    loadNoteForSelectedDate()
                }
            }
            
            // Editor de nota
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Nota del día")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if !noteContent.isEmpty {
                        Text("\(noteContent.count) caracteres")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                #if os(iOS)
                TextField("Escribe tu nota aquí...", text: $noteContent, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                    .focused($isTextFieldFocused)
                    .onChange(of: noteContent) { _, _ in
                        isEditing = true
                    }
                #else
                TextEditor(text: $noteContent)
                    .frame(minHeight: 80)
                    .font(.body)
                    .border(Color.gray.opacity(0.2))
                    .onChange(of: noteContent) { _, _ in
                        isEditing = true
                    }
                #endif
                
                // Botones de acción
                HStack {
                    if isEditing || !noteContent.isEmpty {
                        Button {
                            Task {
                                await saveNote()
                            }
                        } label: {
                            Label("Guardar", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    if !noteContent.isEmpty {
                        Button(role: .destructive) {
                            Task {
                                await deleteNote()
                            }
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                }
            }
            .padding(.vertical, 4)
            
            // Lista de notas recientes
            if !viewModel.getNotes(for: habit.id).isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Notas recientes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Button {
                            showHistory = true
                        } label: {
                            Label("Ver todo", systemImage: "list.bullet")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    ForEach(viewModel.getNotes(for: habit.id).prefix(5)) { note in
                        Button {
                            selectedDate = note.date
                            loadNoteForSelectedDate()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(note.formattedDate)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(note.content)
                                        .font(.subheadline)
                                        .lineLimit(2)
                                        .foregroundStyle(.primary)
                                }
                                Spacer()
                                if Calendar.current.isDate(note.date, inSameDayAs: selectedDate) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            loadNoteForSelectedDate()
        }
        .task {
            // Asegura que las notas se carguen desde persistencia al mostrar la vista
            await viewModel.loadNotes()
            loadNoteForSelectedDate()
        }
        .sheet(isPresented: $showHistory) {
            NotesHistoryView(habit: habit, viewModel: viewModel)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadNoteForSelectedDate() {
        if let note = viewModel.getNote(for: habit.id, on: selectedDate) {
            noteContent = note.content
        } else {
            noteContent = ""
        }
        isEditing = false
    }
    
    private func saveNote() async {
        let trimmedContent = noteContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }
        
        await viewModel.saveNote(
            habitId: habit.id,
            date: selectedDate,
            content: trimmedContent
        )
        
        isEditing = false
        isTextFieldFocused = false
    }
    
    private func deleteNote() async {
        if let note = viewModel.getNote(for: habit.id, on: selectedDate) {
            await viewModel.deleteNote(note)
            noteContent = ""
            isEditing = false
        }
    }
}

// MARK: - Preview
#Preview {
    let habit = Habito(
        title: "Ejercicio diario",
        descripcion: "30 minutos de ejercicio",
        prioridad: .high
    )
    
    return Form {
        Section(header: Text("Notas Diarias")) {
            DailyNoteView(habit: habit)
        }
    }
}
