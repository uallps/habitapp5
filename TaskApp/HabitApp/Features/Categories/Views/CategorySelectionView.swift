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
            LazyVGrid(columns: columns, spacing: 16) {
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
            .padding()
        }
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
                    .foregroundColor(category.color)
            }
            
            Text(category.name)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? category.color.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? category.color : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
    }
}

// MARK: - Preview
#Preview {
    CategorySelectionView(selectedCategory: .constant(nil))
}

#Preview("Con categoría seleccionada") {
    CategorySelectionView(selectedCategory: .constant(.salud))
}
