import Foundation
import Combine

final class ReminderViewModel: ObservableObject {
    @Published var reminderDate: Date? {
        didSet {
            onChange(reminderDate)
        }
    }

    private var onChange: (Date?) -> Void
    private let notificationService = NotificationService.shared

    init(reminderDate: Date?, onChange: @escaping (Date?) -> Void) {
        self.reminderDate = reminderDate
        self.onChange = onChange
    }

    func toggle(_ enabled: Bool) {
        if enabled {
            // Establecer una fecha por defecto: mañana a la misma hora
            reminderDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        } else {
            reminderDate = nil
        }
    }
    
    /// Programa una notificación para un hábito
    /// - Parameters:
    ///   - habit: El hábito para el cual programar la notificación
    ///   - date: La fecha del recordatorio
    func scheduleNotification(for habit: Habito, date: Date) async throws {
        try await notificationService.scheduleNotification(for: habit, at: date)
    }
    
    /// Actualiza la notificación de un hábito
    /// - Parameters:
    ///   - habit: El hábito a actualizar
    ///   - newDate: La nueva fecha del recordatorio (nil para cancelar)
    func updateNotification(for habit: Habito, newDate: Date?) async throws {
        try await notificationService.updateNotification(for: habit, newDate: newDate)
    }
    
    /// Cancela la notificación de un hábito
    /// - Parameter habitId: El ID del hábito
    func cancelNotification(for habitId: UUID) {
        notificationService.cancelNotification(for: habitId)
    }
}
