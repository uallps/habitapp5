//
//  FilterPlugin.swift
//  HabitApp
//
//  Plugin desacoplado para filtrado de hábitos
//

import Foundation
import SwiftUI
import SwiftData
import Combine

final class FilterPlugin: ViewPlugin, HabitFilterProvider {
    
    // MARK: - Propiedades de FeaturePlugin
    
    let identifier = "com.habitapp.filters"
    let name = "Filtros"
    
    var models: [any PersistentModel.Type] {
        return []
    }
    
    @AppStorage("plugin.filters.enabled")
    private var pluginEnabled: Bool = true
    
    var isEnabled: Bool {
        return pluginEnabled
    }
    
    // MARK: - Propiedades Privadas
    
    private let config: AppConfig
    @MainActor private let filterViewModel: FilterViewModel = FilterViewModel()
    var viewModel: FilterViewModel { filterViewModel }

    var filterDidChange: AnyPublisher<Void, Never> {
        filterViewModel.objectWillChange
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Inicialización
    
    required init(config: AppConfig) {
        self.config = config
        print("FilterPlugin inicializado - Enabled: \(isEnabled)")
    }
    
    // MARK: - Implementación de ViewPlugin
    
    func habitRowView(for habito: Habito) -> some View {
        EmptyView()
    }
    
    func habitDetailView(for habito: Binding<Habito>) -> some View {
        EmptyView()
    }
    
    func settingsView() -> some View {
        Toggle(isOn: Binding(
            get: { self.pluginEnabled },
            set: { newValue in
                self.pluginEnabled = newValue
                PluginRegistry.shared.pluginStateDidChange()
            }
        )) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Filtros")
                    .font(.headline)
                Text("Filtrado por categorías y búsqueda")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    /// Provee la vista de filtros para mostrar en HabitListView
    @MainActor
    func filterView(categories: [CategoryModel]) -> AnyView {
        guard isEnabled else { return AnyView(EmptyView()) }
        return AnyView(
            FilterView(viewModel: filterViewModel, availableCategories: categories)
        )
    }
    
    /// Aplica el filtro a un array de hábitos
    @MainActor
    func applyFilter(to habits: [Habito]) -> [Habito] {
        guard isEnabled else { return habits }
        return filterViewModel.filterHabits(habits)
    }
    
    /// Obtiene el estado actual del filtro
    @MainActor
    var filterState: FilterState {
        return filterViewModel.filterState
    }
}
