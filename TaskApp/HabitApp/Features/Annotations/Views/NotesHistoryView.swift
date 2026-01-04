//
//  NotesHistoryView.swift
//  HabitApp
//
//  Created on 04/01/26.
//

import SwiftUI

/// Vista para mostrar el historial completo de notas diarias
struct NotesHistoryView: View {
    let habit: Habito
    @ObservedReferencedObject private var viewModel: DailyNoteViewModel
    @State private var searchText = ""
    @State private var showDeleteConfirmation = false
    @State private var noteToDelete: DailyNote?
    @Environment(\.dismiss) private var dismiss

    init(habit: Habito, viewModel: DailyNoteViewModel) {
        self.habit = habit
        self.viewModel = viewModel
    }
    
    private var filteredNotes: [DailyNote] {
        let habitNotes = viewModel.getNotes(for: habit.id)
        
        if searchText.isEmpty {
            return habitNotes
        } else {
            return habitNotes.filter { note in
                note.content.localizedCaseInsensitiveContains(searchText) ||
                note.formattedDate.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var groupedNotes: [(String, [DailyNote])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredNotes) { note -> String in
            let components = calendar.dateComponents([.year, .month], from: note.date)
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: calendar.date(from: components) ?? note.date)
        }
        
        return grouped.sorted { first, second in
            let firstDate = filteredNotes.first(where: { note in
                let components = calendar.dateComponents([.year, .month], from: note.date)
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: calendar.date(from: components) ?? note.date) == first.key
            })?.date ?? Date()
            
            let secondDate = filteredNotes.first(where: { note in
                let components = calendar.dateComponents([.year, .month], from: note.date)
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: calendar.date(from: components) ?? note.date) == second.key
            })?.date ?? Date()
            
            return firstDate > secondDate
        }.map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.getNotes(for: habit.id).isEmpty {
                    emptyStateView
                } else {
                    notesListView
                }
            }
            .navigationTitle("Historial de Notas")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
                
                #if os(iOS)
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Historial de Notas")
                            .font(.headline)
                        Text(habit.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                #endif
            }
            .searchable(text: $searchText, prompt: "Buscar en notas")
            .alert("Eliminar nota", isPresented: $showDeleteConfirmation, presenting: noteToDelete) { note in
                Button("Cancelar", role: .cancel) { }
                Button("Eliminar", role: .destructive) {
                    Task {
                        await deleteNote(note)
                    }
                }
            } message: { note in
                Text("¿Estás seguro de que quieres eliminar la nota del \(note.formattedDate)?")
            }
            .task {
                // Cargar notas al presentar el historial
                await viewModel.loadNotes()
            }
        }
    }
    
    // MARK: - Views
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No hay notas todavía")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Las notas que escribas aparecerán aquí")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var notesListView: some View {
        List {
            // Estadísticas
            Section {
                VStack(spacing: 12) {
                    HStack {
                        StatBox(
                            title: "Total",
                            value: "\(viewModel.getNotes(for: habit.id).count)",
                            icon: "note.text"
                        )
                        
                        StatBox(
                            title: "Este mes",
                            value: "\(notesThisMonth)",
                            icon: "calendar"
                        )
                        
                        StatBox(
                            title: "Esta semana",
                            value: "\(notesThisWeek)",
                            icon: "calendar.badge.clock"
                        )
                    }
                }
                .listRowBackground(Color.clear)
            }
            
            // Notas agrupadas por mes
            ForEach(groupedNotes, id: \.0) { monthYear, notes in
                Section(header: Text(monthYear)) {
                    ForEach(notes) { note in
                        NoteRowView(note: note) {
                            noteToDelete = note
                            showDeleteConfirmation = true
                        }
                    }
                }
            }
            
            // Mensaje si no hay resultados de búsqueda
            if !searchText.isEmpty && filteredNotes.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No se encontraron notas")
                            .font(.headline)
                        Text("Intenta con otros términos de búsqueda")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
    }
    
    // MARK: - Computed Properties
    
    private var notesThisMonth: Int {
        let calendar = Calendar.current
        return viewModel.getNotes(for: habit.id).filter { note in
            calendar.isDate(note.date, equalTo: Date(), toGranularity: .month)
        }.count
    }
    
    private var notesThisWeek: Int {
        let calendar = Calendar.current
        return viewModel.getNotes(for: habit.id).filter { note in
            calendar.isDate(note.date, equalTo: Date(), toGranularity: .weekOfYear)
        }.count
    }
    
    // MARK: - Actions
    
    private func deleteNote(_ note: DailyNote) async {
        await viewModel.deleteNote(note)
    }
}

// MARK: - Supporting Views

private struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(statBackground)
        .cornerRadius(12)
    }

    private var statBackground: Color {
        #if os(iOS)
        Color(uiColor: .secondarySystemGroupedBackground)
        #else
        Color.secondary.opacity(0.1)
        #endif
    }
}

private struct NoteRowView: View {
    let note: DailyNote
    let onDelete: () -> Void
    @State private var isExpanded = false
    
    private var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: note.date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.formattedDate)
                        .font(.headline)
                    Text(weekdayName.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if note.isToday {
                    Text("Hoy")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.tint.opacity(0.2))
                        .foregroundStyle(.tint)
                        .cornerRadius(8)
                }
            }
            
            Text(note.content)
                .font(.body)
                .lineLimit(isExpanded ? nil : 3)
                .foregroundStyle(.primary)
            
            HStack {
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Ver menos" : "Ver más")
                        .font(.caption)
                        .foregroundStyle(.tint)
                }
                
                Spacer()
                
                Text("Actualizado: \(note.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Eliminar nota", systemImage: "trash")
            }
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
    
    return NotesHistoryView(habit: habit)
}
