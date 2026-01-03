//
//  StreakTestHelper.swift
//  HabitApp
//
//  Utilidad temporal para probar rachas
//  UBICACIÓN: Features/Streaks/Views/
//

import SwiftUI

/// Vista compacta para añadir fechas de prueba manualmente
/// Úsala temporalmente en HabitDetailView para probar rachas
struct StreakTestHelper: View {
    @Binding var habit: Habito
    @State private var selectedDate = Date()
    
    private var streakData: StreakData {
        StreakCalculator.calculate(for: habit)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🧪 Test de Rachas")
                .font(.caption)
                .bold()
            
            // Info rápida
            HStack {
                Label("\(streakData.currentStreak)", systemImage: "flame.fill")
                    .foregroundColor(.orange)
                Spacer()
                Text("Completados: \(habit.fechaCompletitud.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Botones rápidos
            HStack(spacing: 8) {
                Button("+ Hoy") {
                    habit.marcarCompletado(en: Date())
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("+ Ayer") {
                    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
                    habit.marcarCompletado(en: yesterday)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Limpiar") {
                    habit.fechaCompletitud.removeAll()
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.small)
            }
            
            // Verificar si hoy debe realizarse
            if habit.debeRealizarse(en: Date()) {
                Text("✅ Hoy SÍ debe realizarse")
                    .font(.caption2)
                    .foregroundColor(.green)
            } else {
                Text("⚠️ Hoy NO debe realizarse según config")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var habit = Habito(
        title: "Test",
        descripcion: "Para probar",
        fechaInicio: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
        tipoFrecuencia: .semanal,
        vecesPorPeriodo: 7,
        diasSemana: [1, 2, 3, 4, 5, 6, 7],
        diasMes: [],
        fechaCompletitud: []
    )
    
    return VStack {
        StreakSectionView(habit: $habit)
        StreakTestHelper(habit: $habit)
    }
    .padding()
}
