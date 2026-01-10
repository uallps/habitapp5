//
//  FilterState.swift
//  HabitApp
//
//  Created on 04/01/26.
//

import Foundation

/// Modelo que representa el estado actual de filtros aplicados
struct FilterState: Codable, Equatable {
    /// IDs de categorías seleccionadas para filtrar
    var selectedCategoryIds: Set<UUID> = []
    
    /// Texto de búsqueda por palabras clave
    var searchText: String = ""
    
    /// Prioridades seleccionadas para filtrar
    var selectedPriorities: Set<Prioridad> = []
    
    /// Frecuencias seleccionadas para filtrar
    var selectedFrequencies: Set<TipoFrecuencia> = []
    
    init(
        selectedCategoryIds: Set<UUID> = [],
        searchText: String = "",
        selectedPriorities: Set<Prioridad> = [],
        selectedFrequencies: Set<TipoFrecuencia> = []
    ) {
        self.selectedCategoryIds = selectedCategoryIds
        self.searchText = searchText
        self.selectedPriorities = selectedPriorities
        self.selectedFrequencies = selectedFrequencies
    }
    
    /// Verificar si hay algún filtro activo
    var isActive: Bool {
        !selectedCategoryIds.isEmpty || 
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty ||
        !selectedPriorities.isEmpty ||
        !selectedFrequencies.isEmpty
    }
    
    /// Limpiar todos los filtros
    mutating func reset() {
        selectedCategoryIds.removeAll()
        searchText = ""
        selectedPriorities.removeAll()
        selectedFrequencies.removeAll()
    }
}
