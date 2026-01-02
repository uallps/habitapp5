//
//  StatisticsView.swift
//  HabitApp
//
//  Created on 02/01/26.
//

internal import SwiftUI

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            // Fondo sólido
            #if os(iOS)
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            #else
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()
            #endif
            
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("Cargando estadísticas...")
                        .padding()
                } else if let stats = viewModel.statistics {
                    VStack(spacing: 20) {
                    // Sección: Resumen General
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeaderView(title: "Resumen General")
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                StatisticCardView(
                                    title: "Total Hábitos",
                                    value: "\(stats.totalHabits)",
                                    icon: "list.bullet",
                                    color: .blue
                                )
                                
                                StatisticCardView(
                                    title: "Hábitos Activos",
                                    value: "\(stats.activeHabits)",
                                    icon: "checkmark.circle.fill",
                                    color: .green
                                )
                                
                                StatisticCardView(
                                    title: "Completados Hoy",
                                    value: "\(stats.completedToday)",
                                    icon: "star.fill",
                                    color: .orange
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Sección: Rendimiento
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeaderView(title: "Rendimiento")
                            
                            VStack(spacing: 12) {
                                ProgressStatisticCardView(
                                    title: "Tasa de Completitud",
                                    value: stats.averageCompletionRate,
                                    icon: "chart.line.uptrend.xyaxis",
                                    color: .purple
                                )
                                
                                StatisticRowView(
                                    title: "Última Semana",
                                    value: "\(stats.completionsLastWeek) completitudes",
                                    icon: "calendar",
                                    color: .teal
                                )
                                
                                StatisticRowView(
                                    title: "Este Mes",
                                    value: "\(stats.completionsThisMonth) completitudes",
                                    icon: "calendar.badge.clock",
                                    color: .indigo
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Sección: Hábito Destacado
                        if let mostCompleted = stats.mostCompletedHabit {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderView(title: "Hábito Más Completado")
                                
                                HabitHighlightCardView(habit: mostCompleted)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Sección: Categoría Más Activa
                        if let categoryId = stats.mostActiveCategory,
                           let category = CategoryModel.allCategories.first(where: { $0.id == categoryId }) {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderView(title: "Categoría Con Más Hábitos Activos")
                                
                                CategoryHighlightCardView(category: category)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Sección: Por Categoría
                        if !viewModel.categoryStatistics.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderView(title: "Completitud Por Categoría")
                                
                                ForEach(viewModel.categoryStatistics) { categoryStat in
                                    CategoryStatisticRowView(statistic: categoryStat)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .padding(.top, 8) // Espacio adicional superior
                } else {
                    ContentUnavailableView(
                        "Sin Estadísticas",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Aún no hay datos suficientes para mostrar estadísticas")
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Estadísticas")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color(UIColor.systemGroupedBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        #endif
        .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        Task {
                            await viewModel.loadStatistics()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await viewModel.loadStatistics()
            }
        }
}

// MARK: - Section Header
struct SectionHeaderView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.primary)
    }
}

// MARK: - Statistic Card View
struct StatisticCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Progress Statistic Card View
struct ProgressStatisticCardView: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(value * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            ProgressView(value: value)
                .tint(color)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Statistic Row View
struct StatisticRowView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Category Highlight Card View
struct CategoryHighlightCardView: View {
    let category: CategoryModel
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: category.iconName)
                    .font(.system(size: 28))
                    .foregroundColor(category.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Categoría con más hábitos")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "star.fill")
                .font(.title2)
                .foregroundColor(category.color)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(category.color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(category.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Habit Highlight Card View
struct HabitHighlightCardView: View {
    let habit: HabitSummary
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(habit.completionCount) completitudes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "medal.fill")
                .font(.largeTitle)
                .foregroundColor(.yellow)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Category Statistic Row View
struct CategoryStatisticRowView: View {
    let statistic: CategoryStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(statistic.categoryName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(statistic.habitCount) hábitos")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("\(statistic.totalCompletions) completitudes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(statistic.averageCompletionRate * 100))% tasa")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: statistic.averageCompletionRate)
                .tint(getCategoryColor(for: statistic.categoryId))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func getCategoryColor(for categoryId: UUID) -> Color {
        CategoryModel.allCategories.first(where: { $0.id == categoryId })?.color ?? .gray
    }
}

// MARK: - Preview
#Preview {
    StatisticsView()
}
