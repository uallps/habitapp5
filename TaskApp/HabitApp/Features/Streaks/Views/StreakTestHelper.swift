// TaskApp/HabitApp/Features/Streaks/Views/StreakTestHelper.swift

import SwiftUI

/// Vista compacta para añadir fechas de prueba manualmente
/// Úsala temporalmente en HabitDetailView para probar rachas
struct StreakTestHelper: View {
    @Binding var habit: Habito
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    
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
                    .font(.caption)
                Spacer()
                Text("Completados: \(habit.fechaCompletitud.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Botones rápidos de acceso
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
            
            Divider()
            
            // Selector de fecha personalizada
            VStack(alignment: .leading, spacing: 8) {
                Text("Añadir fecha personalizada:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    DatePicker(
                        "Fecha",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    
                    Button("Añadir") {
                        habit.marcarCompletado(en: selectedDate)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(8)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(8)
            
            // Atajos para semanas pasadas
            VStack(alignment: .leading, spacing: 6) {
                Text("Atajos rápidos:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Button("Semana pasada") {
                        addLastWeekDates()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Últimos 7 días") {
                        addLast7Days()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            Divider()
            
            // Información de configuración
            VStack(alignment: .leading, spacing: 4) {
                if habit.debeRealizarse(en: Date()) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Hoy SÍ debe realizarse")
                    }
                    .font(.caption2)
                    .foregroundColor(.green)
                } else {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.orange)
                        Text("Hoy NO debe realizarse según config")
                    }
                    .font(.caption2)
                    .foregroundColor(.orange)
                }
                
                // Mostrar configuración del hábito
                if habit.tipoFrecuenciaActual == .semanal {
                    let dias = habit.diasConfigurados.map { $0.nombreCorto }.joined(separator: ", ")
                    Text("Días configurados: \(dias)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    let dias = habit.diasMes.map { String($0) }.joined(separator: ", ")
                    Text("Días del mes: \(dias)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Lista de fechas completadas (últimas 5)
            if !habit.fechaCompletitud.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Últimas completitudes:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    ForEach(habit.fechaCompletitud.sorted(by: >).prefix(5), id: \.self) { fecha in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            
                            Text(formatDate(fecha))
                                .font(.caption2)
                            
                            Spacer()
                            
                            Button(action: {
                                habit.desmarcarCompletado(en: fecha)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    if habit.fechaCompletitud.count > 5 {
                        Text("... y \(habit.fechaCompletitud.count - 5) más")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Helpers
    
    /// Añade fechas de la semana pasada que coincidan con la configuración del hábito
    private func addLastWeekDates() {
        let calendar = Calendar.current
        let today = Date()
        
        // Semana pasada (7-13 días atrás)
        for daysAgo in 7...13 {
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                if habit.debeRealizarse(en: date) {
                    habit.marcarCompletado(en: date)
                }
            }
        }
    }
    
    /// Añade todos los días de los últimos 7 días que coincidan con la configuración
    private func addLast7Days() {
        let calendar = Calendar.current
        let today = Date()
        
        for daysAgo in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                if habit.debeRealizarse(en: date) {
                    habit.marcarCompletado(en: date)
                }
            }
        }
    }
    
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
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var habit = Habito(
        title: "Test Semanal",
        descripcion: "Sábado y Domingo",
        fechaInicio: Calendar.current.date(byAdding: .day, value: -30, to: Date()),
        tipoFrecuencia: .semanal,
        vecesPorPeriodo: 2,
        diasSemana: [1, 7], // Domingo=1, Sábado=7
        diasMes: [],
        fechaCompletitud: []
    )
    
    return VStack {
        StreakSectionView(habit: $habit)
        StreakTestHelper(habit: $habit)
    }
    .padding()
}