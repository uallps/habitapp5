//
//  CategorySelectionViewModel.swift
//  HabitApp
//
//  Created on 18/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class CategorySelectionViewModel: ObservableObject {
    @Published var categories: [CategoryModel]
    @Published var selectedCategory: CategoryModel?
    @Published var searchText: String = ""
    
    init() {
        self.categories = CategoryModel.allCategories
        self.selectedCategory = nil
    }
    
    /// Categorías filtradas según la búsqueda
    var filteredCategories: [CategoryModel] {
        if searchText.isEmpty {
            return categories
        }
        return categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    /// Selecciona una categoría
    func selectCategory(_ category: CategoryModel) {
        selectedCategory = category
    }
    
    /// Limpia la selección de categoría
    func clearSelection() {
        selectedCategory = nil
    }
    
    /// Verifica si una categoría está seleccionada
    func isSelected(_ category: CategoryModel) -> Bool {
        selectedCategory?.id == category.id
    }
}
