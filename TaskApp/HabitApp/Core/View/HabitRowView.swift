import SwiftUI

struct HabitRowView: View {
    
    let habit: Habito
    let toggleCompletion : () -> Void
    
    @EnvironmentObject private var AppConfig: AppConfig
    
    var body: some View {
        HStack {
            Button(action: toggleCompletion){
                Image(systemName: habit.completada ? "checkmark.circle.fill" : "circle")
            }.buttonStyle(.plain)
            VStack(alignment: .leading) {
                Text(habit.title)
                    .strikethrough(habit.completada)
                
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
                        .foregroundColor(.secondary)
                }
                if AppConfig.showPriorities, let priority = habit.prioridad {
                    Text("Prioridad: \(priority.rawValue)")
                        .font(.caption)
                        .foregroundColor(priorityColor(for: priority))
                }
                if AppConfig.enableReminders, let reminderDate = habit.reminderDate {
                    Label("Recordatorio: \(reminderDate.formatted(date: .abbreviated, time: .shortened))", systemImage: "bell")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func priorityColor(for priority: Prioridad) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
}
