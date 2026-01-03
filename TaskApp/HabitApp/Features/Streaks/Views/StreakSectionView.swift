//
//  StreakSectionView.swift
//  HabitApp
//
//  Created on 3/1/26.
//

import SwiftUI

/// Vista que muestra información de racha en HabitDetailView
struct StreakSectionView: View {
    @Binding var habit: Habito
    
    private var streakData: StreakData {
        // Recalcular cada vez que cambia el hábito
        // Esto asegura que se actualice cuando se marca como completado
        StreakCalculator.calculate(for: habit)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Racha actual destacada
            rachaActualCard
            
            // Estadísticas adicionales
            estadisticasSecundarias
        }
    }
    
    // MARK: - Componentes
    
    private var rachaActualCard: some View {
        HStack(spacing: 16) {
            // Ícono de llama
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    streakData.currentStreak > 0 ?
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .top,
                            endPoint: .bottom
                        ) :
                        LinearGradient(
                            colors: [.gray, .gray],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                )
            
            // Texto de racha
            VStack(alignment: .leading, spacing: 4) {
                Text("Tu racha actual en este hábito es")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(streakData.currentStreak)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(streakData.currentStreak > 0 ? .orange : .secondary)
                    
                    Text(streakData.currentStreak == 1 ? "día" : "días")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var estadisticasSecundarias: some View {
        HStack(spacing: 12) {
            // Mejor racha
            StatItem(
                title: "Mejor Racha",
                value: "\(streakData.longestStreak)",
                icon: "trophy.fill",
                color: .yellow
            )
            
            // Última vez completado
            if let lastDate = streakData.lastCompletionDate {
                StatItem(
                    title: "Última Vez",
                    value: formatDate(lastDate),
                    icon: "calendar",
                    color: .blue
                )
            } else {
                StatItem(
                    title: "Última Vez",
                    value: "Nunca",
                    icon: "calendar",
                    color: .gray
                )
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dateToCompare = calendar.startOfDay(for: date)
        
        if calendar.isDate(dateToCompare, inSameDayAs: today) {
            return "Hoy"
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  calendar.isDate(dateToCompare, inSameDayAs: yesterday) {
            return "Ayer"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
}

// MARK: - Componente auxiliar para estadísticas

private struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview("Con racha activa") {
    @Previewable @State var habit = Habito(
        title: "Ejercicio",
        descripcion: "30 minutos de ejercicio",
        fechaInicio: Calendar.current.date(byAdding: .day, value: -30, to: Date()),
        tipoFrecuencia: .semanal,
        vecesPorPeriodo: 3,
        diasSemana: [2, 4, 6], // Lunes, Miércoles, Viernes
        diasMes: [],
        fechaCompletitud: [
            Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
            Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
        ]
    )
    
    StreakSectionView(habit: $habit)
        .padding()
}

#Preview("Sin racha") {
    @Previewable @State var habit = Habito(
        title: "Meditación",
        descripcion: "10 minutos diarios",
        fechaInicio: Calendar.current.date(byAdding: .day, value: -30, to: Date()),
        tipoFrecuencia: .semanal,
        vecesPorPeriodo: 7,
        diasSemana: [1, 2, 3, 4, 5, 6, 7],
        diasMes: [],
        fechaCompletitud: []
    )
    
    StreakSectionView(habit: $habit)
        .padding()
}

#Preview("Completado HOY") {
    @Previewable @State var habit: Habito = {
        let calendar = Calendar.current
        let today = Date()
        return Habito(
            title: "Lectura",
            descripcion: "Leer 30 minutos",
            fechaInicio: calendar.date(byAdding: .day, value: -10, to: today),
            tipoFrecuencia: .semanal,
            vecesPorPeriodo: 7,
            diasSemana: [1, 2, 3, 4, 5, 6, 7], // Todos los días
            diasMes: [],
            fechaCompletitud: [
                // Completado hoy y los últimos 2 días
                calendar.startOfDay(for: today), // HOY
                calendar.date(byAdding: .day, value: -1, to: today)!, // Ayer
                calendar.date(byAdding: .day, value: -2, to: today)!, // Anteayer
            ]
        )
    }()
    
    StreakSectionView(habit: $habit)
        .padding()
}
