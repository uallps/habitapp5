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
        NavigationLink(destination: HabitDetailView(
            habit: binding(for: habit),
            onSave: {
                saveHabits()
            }
        )) {
            HabitRowView(habit: habit, toggleCompletion: {
                _Concurrency.Task {
                    await viewModel.toggleCompletion(task: habit)
                }
            })
            .appCard(padding: 14)
            .contentShape(Rectangle())
            .contextMenu {
                Button("Eliminar hábito") {
                    deleteHabit(habit)
                }
            }
        }
        .buttonStyle(.plain)
        .appListRowCard()
    }
    
    private func binding(for habit: Habito) -> Binding<Habito> {
        guard let index = viewModel.habitos.firstIndex(where: { $0.id == habit.id }) else {
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
