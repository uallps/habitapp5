//
//  FilterScreenView.swift
//  HabitApp
//
//  Pantalla modal de filtros con botón "Aplicar Filtros"
//

import SwiftUI

struct FilterScreenView: View {
    @ObservedObject var viewModel: FilterViewModel
    @State private var tempSearchText: String = ""
    @State private var tempSelectedCategories: Set<UUID> = []
    let availableCategories: [CategoryModel]
    let onApply: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Contenido de filtros
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Campo de búsqueda
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                
                                TextField("Buscar por título o descripción...", text: $tempSearchText)
                                
                                if !tempSearchText.isEmpty {
                                    Button {
                                        tempSearchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(10)
                            .background(searchFieldBackground)
                            .cornerRadius(8)
                        }
                        
                        // Filtro de categorías
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.headline)
                                    Text("Categoría")
                                        .font(.headline)
                                }
                                
                                Spacer()
                                
                                if !tempSelectedCategories.isEmpty {
                                    Text("\(tempSelectedCategories.count) seleccionadas")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            if availableCategories.isEmpty {
                                Text("No hay categorías disponibles")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 16)
                            } else {
                                FlowLayout(spacing: 10) {
                                    ForEach(availableCategories) { category in
                                        CategoryFilterButton(
                                            category: category,
                                            isSelected: tempSelectedCategories.contains(category.id),
                                            action: {
                                                if tempSelectedCategories.contains(category.id) {
                                                    tempSelectedCategories.remove(category.id)
                                                } else {
                                                    tempSelectedCategories.insert(category.id)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Filtro de estado (Pendiente/Completado)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .font(.headline)
                                Text("Estado")
                                    .font(.headline)
                            }
                            
                            HStack(spacing: 10) {
                                Button {
                                    tempSearchText = ""
                                    tempSelectedCategories.removeAll()
                                } label: {
                                    Text("Todos")
                                        .font(.caption)
                                        .frame(maxWidth: .infinity)
                                        .padding(10)
                                        .background(
                                            tempSearchText.isEmpty && tempSelectedCategories.isEmpty
                                                ? Color.accentColor.opacity(0.2)
                                                : Color.gray.opacity(0.1)
                                        )
                                        .foregroundStyle(
                                            tempSearchText.isEmpty && tempSelectedCategories.isEmpty
                                                ? .accentColor
                                                : .secondary
                                        )
                                        .cornerRadius(8)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(16)
                }
                
                // Botones de acción
                VStack(spacing: 12) {
                    Divider()
                        .padding(.horizontal, -16)
                    
                    Button {
                        applyFilters()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark")
                                .font(.headline)
                            Text("Aplicar Filtros")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                    }
                    
                    Button {
                        tempSearchText = ""
                        tempSelectedCategories.removeAll()
                    } label: {
                        Text("Restablecer")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.gray.opacity(0.1))
                            .foregroundStyle(.secondary)
                            .cornerRadius(10)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Filtrar Hábitos")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadCurrentFilters()
        }
    }
    
    private func loadCurrentFilters() {
        tempSearchText = viewModel.filterState.searchText
        tempSelectedCategories = viewModel.filterState.selectedCategoryIds
    }
    
    private func applyFilters() {
        viewModel.setSearchText(tempSearchText)
        
        // Actualizar categorías seleccionadas
        let previousCategories = viewModel.filterState.selectedCategoryIds
        for id in previousCategories {
            if !tempSelectedCategories.contains(id) {
                viewModel.toggleCategory(id)
            }
        }
        for id in tempSelectedCategories {
            if !previousCategories.contains(id) {
                viewModel.toggleCategory(id)
            }
        }
        
        onApply()
    }
    
    private var searchFieldBackground: Color {
        #if os(iOS)
        Color(uiColor: .tertiarySystemGroupedBackground)
        #else
        Color.gray.opacity(0.1)
        #endif
    }
}

// MARK: - Supporting Views

private struct CategoryFilterButton: View {
    let category: CategoryModel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .font(.caption)
                Text(category.name)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? category.color.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundStyle(isSelected ? category.color : .secondary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

private struct FlowLayout: Layout {
    let spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        
        let maxWidth = (proposal.width ?? 300)
        var width: CGFloat = 0
        var height: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if width + size.width + spacing > maxWidth {
                height += lineHeight + spacing
                width = 0
                lineHeight = 0
            }
            width += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        height += lineHeight
        
        return CGSize(width: maxWidth, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                y += lineHeight + spacing
                x = bounds.minX
                lineHeight = 0
            }
            let proposedSize = ProposedViewSize(width: size.width, height: size.height)
            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: proposedSize
            )
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

#Preview {
    let viewModel = FilterViewModel()
    FilterScreenView(
        viewModel: viewModel,
        availableCategories: [
            CategoryModel(id: UUID(), name: "Salud", iconName: "heart.fill", colorHex: "#FF6B6B"),
            CategoryModel(id: UUID(), name: "Trabajo", iconName: "briefcase.fill", colorHex: "#4ECDC4"),
            CategoryModel(id: UUID(), name: "Deporte", iconName: "dumbbell.fill", colorHex: "#95E1D3")
        ],
        onApply: {}
    )
}
