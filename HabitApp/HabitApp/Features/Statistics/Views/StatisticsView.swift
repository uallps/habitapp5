//
//  StatisticsView.swift
//  HabitApp
//
//  Created on 02/01/26.
//

import SwiftUI

struct StatisticsView: View {
    @StateObject private var viewModel: StatisticsViewModel
    @EnvironmentObject var appConfig: AppConfig
    @State private var showWeekDetails = false
    @State private var showMonthDetails = false
    
    init(storageProvider: StorageProvider) {
        _viewModel = StateObject(wrappedValue: StatisticsViewModel(storageProvider: storageProvider))
    }
    
    var body: some View {
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
                                
                                PriorityCardView(
                                    high: stats.activeByPriority.high,
                                    medium: stats.activeByPriority.medium,
                                    low: stats.activeByPriority.low
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
                                
                                Button(action: {
                                    showWeekDetails.toggle()
                                }) {
                                    StatisticRowView(
                                        title: "Última Semana",
                                        value: "\(stats.completionsLastWeek) completitudes",
                                        icon: "calendar",
                                        color: .teal,
                                        showChevron: true
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                if showWeekDetails {
                                    CompletionDetailsView(completions: viewModel.weekCompletions)
                                }
                                
                                Button(action: {
                                    showMonthDetails.toggle()
                                }) {
                                    StatisticRowView(
                                        title: "Este Mes",
                                        value: "\(stats.completionsThisMonth) completitudes",
                                        icon: "calendar.badge.clock",
                                        color: .indigo,
                                        showChevron: true
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                if showMonthDetails {
                                    CompletionDetailsView(completions: viewModel.monthCompletions)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
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
        .appScrollBackground()
        .frame(maxWidth: .infinity)
        .navigationTitle("Estadísticas")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(AppStyle.screenBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        #endif
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
            .font(.title3.weight(.semibold))
            .foregroundStyle(.primary)
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
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(padding: 14)
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
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(String(format: "%.1f%%", value * 100))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }
            
            ProgressView(value: value)
                .tint(color)
        }
        .appCard(padding: 14)
    }
}

// MARK: - Statistic Row View
struct StatisticRowView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var showChevron: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            if showChevron {
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .appCard(padding: 14)
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
                    .foregroundStyle(category.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Categoría con más hábitos")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "star.fill")
                .font(.title2)
                .foregroundStyle(category.color)
        }
        .appCard(padding: 14)
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
                    .foregroundStyle(.primary)
                
                Text("\(habit.completionCount) completitudes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "medal.fill")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
        }
        .appCard(padding: 14)
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
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(String(format: "%.1f%% tasa", statistic.averageCompletionRate * 100))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: statistic.averageCompletionRate)
                .tint(getCategoryColor(for: statistic.categoryId))
        }
        .appCard(padding: 14)
    }
    
    private func getCategoryColor(for categoryId: UUID) -> Color {
        CategoryModel.allCategories.first(where: { $0.id == categoryId })?.color ?? .gray
    }
}

// MARK: - Completion Details View
struct CompletionDetailsView: View {
    let completions: [CompletionDetail]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if completions.isEmpty {
                Text("No hay completitudes en este período")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(completions) { completion in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(completion.habitTitle)
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text(completion.completionDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(nombreDiaSemana(completion.completionDate))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    if completion.id != completions.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func nombreDiaSemana(_ fecha: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: fecha)
        return DiaSemana(rawValue: weekday)?.nombre ?? ""
    }
}

// MARK: - Priority Card View
struct PriorityCardView: View {
    let high: Int
    let medium: Int
    let low: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flag.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(alignment: .top, spacing: 12) {
                priorityItem(title: "Alta", value: high, color: priorityColorHigh)
                    .frame(maxWidth: .infinity, alignment: .leading)

                priorityItem(title: "Media", value: medium, color: priorityColorMedium)
                    .frame(maxWidth: .infinity, alignment: .leading)

                priorityItem(title: "Baja", value: low, color: priorityColorLow)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("Hábitos Activos Por Prioridad")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .allowsTightening(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(padding: 14)
    }

    private func priorityItem(title: String, value: Int, color: Color) -> some View {
        #if os(iOS)
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)

                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .allowsTightening(true)
            }

            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .allowsTightening(true)
        }
        #else
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .monospacedDigit()
                .padding(.leading, 6)
        }
        #endif
    }

    private var priorityColorLow: Color { .green }
    private var priorityColorMedium: Color { .yellow }
    private var priorityColorHigh: Color { .red }
}
