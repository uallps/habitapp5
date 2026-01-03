//
//  TaskListView.swift
//  TaskApp
//
//  Created by Aula03 on 15/10/25.
//

import Foundation
internal import SwiftUI

struct HabitListView: View {
    @StateObject private var viewModel: HabitListViewModel
    @State private var selectedHabitID: UUID?

    init(storageProvider: StorageProvider) {
        _viewModel = StateObject(wrappedValue: HabitListViewModel(storageProvider: storageProvider))
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach($viewModel.habitos) { $habit in
                    habitRow(habit: habit)
                }
                .onDelete { indexSet in
                    _Concurrency.Task {
                        await viewModel.removeHabits(atOffsets: indexSet)
                    }
                }
            }
            .appListContainer()
            .navigationTitle("Hábitos")
            .navigationDestination(isPresented: Binding(
                get: { selectedHabitID != nil },
                set: { isPresented in
                    if !isPresented { selectedHabitID = nil }
                }
            )) {
                if let id = selectedHabitID {
                    HabitDetailView(
                        habit: binding(forHabitId: id),
                        onSave: {
                            saveHabits()
                        }
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addNewHabit()
                    } label: {
                        Label("Añadir", systemImage: "plus")
                    }
                }
            }
            .task {
                await viewModel.loadHabits()
            }
        }
    }
    
    @ViewBuilder
    private func habitRow(habit: Habito) -> some View {
        Button {
            selectedHabitID = habit.id
        } label: {
            HabitRowView(habit: habit, toggleCompletion: {
                _Concurrency.Task {
                    await viewModel.toggleCompletion(task: habit)
                }
            })
            .appCard(padding: 14)
            .overlay(alignment: .bottomTrailing) {
                statusBadge(for: habit)
                    .padding(10)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(AppCardPressedHighlightStyle())
        .contextMenu {
            Button("Eliminar hábito") {
                deleteHabit(habit)
            }
        }
        .appListRowCard()
    }

    @ViewBuilder
    private func statusBadge(for habit: Habito) -> some View {
        let now = Date()
        if let dueDate = habit.fechaFin, dueDate <= now {
            Text("Vencido: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.18))
                .foregroundStyle(.red)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .allowsHitTesting(false)
        } else {
            Text("Activo")
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.18))
                .foregroundStyle(.green)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .allowsHitTesting(false)
        }
    }
    
    private func binding(for habit: Habito) -> Binding<Habito> {
        guard let index = viewModel.habitos.firstIndex(where: { $0.id == habit.id }) else {
            fatalError("Habit not found")
        }
        return $viewModel.habitos[index]
    }

    private func binding(forHabitId id: UUID) -> Binding<Habito> {
        guard let index = viewModel.habitos.firstIndex(where: { $0.id == id }) else {
            fatalError("Habit not found")
        }
        return $viewModel.habitos[index]
    }
    
    private func deleteHabit(_ habit: Habito) {
        if let index = viewModel.habitos.firstIndex(where: { $0.id == habit.id }) {
            _Concurrency.Task {
                await viewModel.removeHabits(atOffsets: IndexSet(integer: index))
            }
        }
    }
    
    private func addNewHabit() {
        let newHabit = Habito(title: "Nuevo Hábito", descripcion: "Descripcion")
        _Concurrency.Task {
            await viewModel.addHabit(habit: newHabit)
        }
    }
    
    private func saveHabits() {
        _Concurrency.Task {
            await viewModel.saveHabits()
        }
    }
}

#Preview {
    HabitListView(storageProvider: MockStorageProvider())
}
