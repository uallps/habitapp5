//
//  FilterView.swift
//  HabitApp
//
//  Created on 04/01/26.
//

import SwiftUI

/// Vista de filtros para hábitos
struct FilterView: View {
    @ObservedObject var viewModel: FilterViewModel
    @State private var showCategoryPicker = false
    
    /// Array de todas las categorías disponibles
    let availableCategories: [CategoryModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Encabezado
            HStack {
                Image(systemName: "funnel")
                    .font(.headline)
                Text("Filtros")
                    .font(.headline)
                
                Spacer()
                
                if viewModel.filterState.isActive {
                    Button {
                        viewModel.resetFilters()
                    } label: {
                        Text("Limpiar")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            // Campo de búsqueda
            VStack(alignment: .leading, spacing: 6) {
                Text("Buscar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                #if os(iOS)
                SearchFieldView(viewModel: viewModel)
                #else
                TextField("Título o descripción...", text: Binding(
                    get: { viewModel.filterState.searchText },
                    set: { viewModel.setSearchText($0) }
                ))
                    .textFieldStyle(.roundedBorder)
                #endif
            }
            
            // Filtro de categorías
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Categorías")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if !viewModel.filterState.selectedCategoryIds.isEmpty {
                        Text("\(viewModel.filterState.selectedCategoryIds.count) seleccionadas")
                            .font(.caption)
                            .foregroundStyle(.tint)
                    }
                }
                
                if availableCategories.isEmpty {
                    Text("No hay categorías disponibles")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(availableCategories) { category in
                            CategoryFilterButton(
                                category: category,
                                isSelected: viewModel.filterState.selectedCategoryIds.contains(category.id),
                                action: {
                                    viewModel.toggleCategory(category.id)
                                }
                            )
                        }
                    }
                }
            }
            
            // Filtro de prioridades
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Prioridades")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if !viewModel.filterState.selectedPriorities.isEmpty {
                        Text("\(viewModel.filterState.selectedPriorities.count) seleccionadas")
                            .font(.caption)
                            .foregroundStyle(.tint)
                    }
                }
                
                FlowLayout(spacing: 8) {
                    ForEach([Prioridad.low, Prioridad.medium, Prioridad.high], id: \.self) { priority in
                        PriorityFilterButton(
                            priority: priority,
                            isSelected: viewModel.filterState.selectedPriorities.contains(priority),
                            action: {
                                viewModel.togglePriority(priority)
                            }
                        )
                    }
                }
            }
            
            // Filtro de frecuencias
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Frecuencias")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if !viewModel.filterState.selectedFrequencies.isEmpty {
                        Text("\(viewModel.filterState.selectedFrequencies.count) seleccionadas")
                            .font(.caption)
                            .foregroundStyle(.tint)
                    }
                }
                
                FlowLayout(spacing: 8) {
                    ForEach([TipoFrecuencia.semanal, TipoFrecuencia.mensual], id: \.self) { frequency in
                        FrequencyFilterButton(
                            frequency: frequency,
                            isSelected: viewModel.filterState.selectedFrequencies.contains(frequency),
                            action: {
                                viewModel.toggleFrequency(frequency)
                            }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(backgroundColorForPlatform)
        .cornerRadius(10)
    }
    
    private var backgroundColorForPlatform: Color {
        #if os(iOS)
        Color(uiColor: .secondarySystemGroupedBackground).opacity(0.35)
        #else
        Color.secondary.opacity(0.08)
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
            .padding(.vertical, 6)
            .background(isSelected ? category.color.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundStyle(isSelected ? category.color : .secondary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 1)
            )
        }
    }
}

private struct PriorityFilterButton: View {
    let priority: Prioridad
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: priorityIcon)
                    .font(.caption)
                Text(priorityLabel)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? priorityColor.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundStyle(isSelected ? priorityColor : .secondary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? priorityColor : Color.clear, lineWidth: 1)
            )
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    private var priorityIcon: String {
        switch priority {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        }
    }
    
    private var priorityLabel: String {
        switch priority {
        case .low: return "Baja"
        case .medium: return "Media"
        case .high: return "Alta"
        }
    }
}

private struct FrequencyFilterButton: View {
    let frequency: TipoFrecuencia
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: frequency == .semanal ? "calendar.badge.clock" : "calendar.badge")
                    .font(.caption)
                Text(frequency.rawValue)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundStyle(isSelected ? .blue : .secondary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
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

private struct SearchFieldView: View {
    @ObservedObject var viewModel: FilterViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Título o descripción...", text: Binding(
                get: { viewModel.filterState.searchText },
                set: { viewModel.setSearchText($0) }
            ))
            
            if !viewModel.filterState.searchText.isEmpty {
                Button {
                    viewModel.setSearchText("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
        .background(searchFieldBackground)
        .cornerRadius(8)
    }
    
    private var searchFieldBackground: Color {
        #if os(iOS)
        Color(uiColor: .tertiarySystemGroupedBackground)
        #else
        Color.gray.opacity(0.1)
        #endif
    }
}

// MARK: - Preview
#Preview {
    let viewModel = FilterViewModel()
    return VStack {
        FilterView(
            viewModel: viewModel,
            availableCategories: [
                CategoryModel(id: UUID(), name: "Salud", iconName: "heart.fill", colorHex: "#FF6B6B"),
                CategoryModel(id: UUID(), name: "Estudio", iconName: "book.fill", colorHex: "#4ECDC4"),
                CategoryModel(id: UUID(), name: "Deporte", iconName: "dumbbell.fill", colorHex: "#95E1D3")
            ]
        )
        Spacer()
    }
    .padding()
}
