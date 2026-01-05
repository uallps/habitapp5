//
//  FilterViewModel.swift
//  HabitApp
//
//  Created on 04/01/26.
//

import Foundation
import Combine

/// ViewModel para gestionar filtros de hábitos
@MainActor
class FilterViewModel: ObservableObject {
    private let storageKey = "filter_state_storage"
    
    @Published private(set) var filterState: FilterState = FilterState()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        Task {
            await loadFilterState()
        }
    }
    
    // MARK: - Persistencia
    
    /// Cargar estado de filtros desde UserDefaults
    @MainActor
    func loadFilterState() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let data = UserDefaults.standard.data(forKey: storageKey) else {
                filterState = FilterState()
                return
            }
            
            let decoder = JSONDecoder()
            filterState = try decoder.decode(FilterState.self, from: data)
        } catch {
            errorMessage = "Error al cargar filtros: \(error.localizedDescription)"
            filterState = FilterState()
        }
    }
    
    /// Guardar estado de filtros en UserDefaults
    @MainActor
    private func saveFilterState() async {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(filterState)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            errorMessage = "Error al guardar filtros: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Operaciones
    
    /// Alternar selección de una categoría
    func toggleCategory(_ categoryId: UUID) {
        if filterState.selectedCategoryIds.contains(categoryId) {
            filterState.selectedCategoryIds.remove(categoryId)
        } else {
            filterState.selectedCategoryIds.insert(categoryId)
        }
        Task {
            await saveFilterState()
        }
    }
    
    /// Establecer texto de búsqueda
    func setSearchText(_ text: String) {
        filterState.searchText = text
        Task {
            await saveFilterState()
        }
    }
    
    /// Limpiar todos los filtros
    func resetFilters() {
        filterState.reset()
        Task {
            await saveFilterState()
        }
    }
    
    /// Aplicar filtro a un array de hábitos
    func filterHabits(_ habits: [Habito]) -> [Habito] {
        guard filterState.isActive else { return habits }
        
        return habits.filter { habit in
            // Filtrar por categoría si hay categorías seleccionadas
            if !filterState.selectedCategoryIds.isEmpty {
                guard let habitCategory = habit.categoria,
                      filterState.selectedCategoryIds.contains(habitCategory) else {
                    return false
                }
            }
            
            // Filtrar por búsqueda de texto si hay texto
            if !filterState.searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                let searchLower = filterState.searchText.lowercased()
                let titleMatches = habit.title.lowercased().contains(searchLower)
                let descriptionMatches = habit.descripcion?.lowercased().contains(searchLower) ?? false
                
                if !titleMatches && !descriptionMatches {
                    return false
                }
            }
            
            return true
        }
    }
}
