internal import SwiftUI

struct HabitRowView: View {
    
    let habit: Habito
    let toggleCompletion : () -> Void
    
    @EnvironmentObject private var AppConfig: AppConfig
    
    var body: some View {
        HStack {
            Button(action: toggleCompletion){
                Image(systemName: habit.estaCompletado(en: Date()) ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(habit.estaCompletado(en: Date()) ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading) {
                Text(habit.title)
                    .font(.body.weight(.semibold))
                    .strikethrough(habit.estaCompletado(en: Date()))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                // Mostrar configuración de frecuencia
                HStack(spacing: 4) {
                    Text(habit.tipoFrecuenciaActual == .semanal ? "Semanal:" : "Mensual:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if habit.tipoFrecuenciaActual == .semanal && !habit.diasSemana.isEmpty {
                        HStack(spacing: 2) {
                            ForEach(habit.diasConfigurados) { dia in
                                let isDone = habit.estaCompletado(en: proximaOcurrencia(de: dia))
                                Text(dia.nombreCorto)
                                    .font(.caption2.weight(.medium))
                                    .frame(width: 18, height: 18)
                                    .background(isDone ? Color.accentColor.opacity(0.18) : AppStyle.subtleFill)
                                    .foregroundStyle(isDone ? .primary : .secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            }
                        }
                    } else if habit.tipoFrecuenciaActual == .mensual && !habit.diasMes.isEmpty {
                        Text(formatDiasMes(habit.diasMes))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("(\(habit.vecesPorPeriodoActual)x)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
                
                // Mostrar categoría si existe
                if let categoryId = habit.categoria,
                   let category = CategoryModel.allCategories.first(where: { $0.id == categoryId }) {
                    HStack(spacing: 4) {
                        Image(systemName: category.iconName)
                            .font(.caption)
                        Text(category.name)
                            .font(.caption)
                    }
                    .foregroundColor(category.color)
                }
                
                if AppConfig.showDueDates, let dueDate = habit.fechaFin {
                    Text("Vence: \(dueDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if AppConfig.showPriorities, let priority = habit.prioridad {
                    Text("Prioridad: \(priority.rawValue)")
                        .font(.caption)
                        .foregroundStyle(priorityColor(for: priority))
                }
                if AppConfig.enableReminders, let reminderDate = habit.reminderDate {
                    Label("Recordatorio: \(reminderDate.formatted(date: .abbreviated, time: .shortened))", systemImage: "bell")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Mostrar vistas de plugins de forma dinámica
            // Si hay plugins activos, sus vistas aparecen automáticamente aquí
            ForEach(0..<PluginRegistry.shared.getHabitoRowViews(for: habit).count, id: \.self) { index in
                PluginRegistry.shared.getHabitoRowViews(for: habit)[index]
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Helper Methods
    
    private func formatDiasMes(_ dias: [Int]) -> String {
        if dias.isEmpty { return "" }
        if dias.count <= 3 {
            return "Días " + dias.map { String($0) }.joined(separator: ", ")
        }
        return "Días \(dias.first!)...\(dias.last!)"
    }
    
    private func proximaOcurrencia(de dia: DiaSemana) -> Date {
        let calendar = Calendar.current
        let hoy = Date()
        let weekdayHoy = calendar.component(.weekday, from: hoy)
        
        if weekdayHoy == dia.rawValue {
            return calendar.startOfDay(for: hoy)
        }
        
        // Buscar la próxima ocurrencia
        var fechaBusqueda = hoy
        for _ in 0..<7 {
            fechaBusqueda = calendar.date(byAdding: .day, value: 1, to: fechaBusqueda)!
            let weekday = calendar.component(.weekday, from: fechaBusqueda)
            if weekday == dia.rawValue {
                return calendar.startOfDay(for: fechaBusqueda)
            }
        }
        
        return calendar.startOfDay(for: hoy)
    }
    
    private func priorityColor(for priority: Prioridad) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
}
