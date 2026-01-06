//
//  TaskListView.swift
//  TaskApp
//
//  Created by Aula03 on 15/10/25.
//

import Foundation
import SwiftUI
import Combine

struct HabitListView: View {
    @StateObject private var viewModel: HabitListViewModel
    @State private var selectedHabitID: UUID?
    @State private var filterProvider: HabitFilterProvider?
    @State private var availableCategories: [CategoryModel] = []
    @State private var filterRefreshToggle = false
    @ObservedObject private var pluginRegistry = PluginRegistry.shared

    init(storageProvider: StorageProvider) {
        _viewModel = StateObject(wrappedValue: HabitListViewModel(storageProvider: storageProvider))
    }
    
    private var filteredHabits: [Habito] {
        guard let provider = filterProvider, provider.isEnabled else { return viewModel.habitos }
        return provider.applyFilter(to: viewModel.habitos)
    }
    
    var body: some View {
        #if os(iOS)
        NavigationStack {
            content
        }
        #else
        content
        #endif
    }

    private var content: some View {
        VStack(spacing: 0) {
            // Filtro completamente fuera de la List
            if let provider = filterProvider, provider.isEnabled {
                ScrollView {
                    provider.filterView(categories: availableCategories)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .frame(maxHeight: 250)
            }
            
            // Lista de hábitos
            List {
                ForEach(filteredHabits, id: \Habito.id) { habit in
                    habitRow(habit: habit)
                }
                .onDelete { indexSet in
                    let ids = indexSet.compactMap { filteredHabits[safe: $0]?.id }
                    let originalOffsets = IndexSet(ids.compactMap { id in
                        viewModel.habitos.firstIndex(where: { $0.id == id })
                    })
                    _Concurrency.Task {
                        await viewModel.removeHabits(atOffsets: originalOffsets)
                    }
                }
            }
            .id(filterRefreshToggle)
            .appListContainer()
        }
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
            setupFilter()
            loadCategories()
        }
        .onReceive(pluginRegistry.objectWillChange) { _ in
            setupFilter()
            filterRefreshToggle.toggle()
        }
        .onReceive(filterChangePublisher) { _ in
            filterRefreshToggle.toggle()
        }
    }
    
    @ViewBuilder
    private func habitRow(habit: Habito) -> some View {
        // Solo mostrar si pasa el filtro
        if filteredHabits.contains(where: { $0.id == habit.id }) {
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
    
    // MARK: - Filter Setup
    
    private func setupFilter() {
        filterProvider = PluginRegistry.shared.getPluginConformingTo(HabitFilterProvider.self)
    }
    
    private func loadCategories() {
        availableCategories = CategoryModel.allCategories
    }

    private var filterChangePublisher: AnyPublisher<Void, Never> {
        if let provider = filterProvider {
            return provider.filterDidChange
        }
        return Empty(completeImmediately: false).eraseToAnyPublisher()
    }
}

// MARK: - Safe collection access
private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    HabitListView(storageProvider: MockStorageProvider())
}
