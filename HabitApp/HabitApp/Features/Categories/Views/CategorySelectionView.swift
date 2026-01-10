//
//  CategorySelectionView.swift
//  HabitApp
//
//  Created on 18/11/25.
//

import SwiftUI

/// Vista para seleccionar una categoría
struct CategorySelectionView: View {
    @Binding var selectedCategory: CategoryModel?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CategorySelectionViewModel()
    
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.filteredCategories) { category in
                    CategoryCardView(
                        category: category,
                        isSelected: selectedCategory?.id == category.id
                    )
                    .onTapGesture {
                        selectCategory(category)
                    }
                }
            }
            .padding(16)
        }
        .appScrollBackground()
        .navigationTitle("Seleccionar Categoría")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Limpiar") {
                    selectedCategory = nil
                    dismiss()
                }
                .disabled(selectedCategory == nil)
            }
        }
    }
    
    private func selectCategory(_ category: CategoryModel) {
        selectedCategory = category
        dismiss()
    }
}

// MARK: - Category Card View
struct CategoryCardView: View {
    let category: CategoryModel
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: category.iconName)
                    .font(.system(size: 28))
                    .foregroundStyle(category.color)
            }
            
            Text(category.name)
                .font(.caption.weight(isSelected ? .semibold : .regular))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 32)
        }
        .frame(maxWidth: .infinity)
        .appCard(padding: 12)
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius, style: .continuous)
                    .stroke(category.color, lineWidth: 2)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    CategorySelectionView(selectedCategory: .constant(nil))
}

#Preview("Con categoría seleccionada") {
    CategorySelectionView(selectedCategory: .constant(.salud))
}
