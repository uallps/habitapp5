//
//  NotificationService.swift
//  HabitApp
//
//  Created on 18/12/24.
//

import Foundation
import UserNotifications

/// Servicio encargado de gestionar las notificaciones locales para recordatorios de hábitos
class NotificationService {
    static let shared = NotificationService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {}
    
    /// Solicita permisos para mostrar notificaciones
    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        return try await notificationCenter.requestAuthorization(options: options)
    }
    
    /// Verifica el estado actual de los permisos de notificaciones
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    /// Programa una notificación para un hábito en la fecha especificada
    /// - Parameters:
    ///   - habit: El hábito para el cual se programará la notificación
    ///   - date: La fecha y hora en que se debe mostrar la notificación
    func scheduleNotification(for habit: Habito, at date: Date) async throws {
        // Verificar que la fecha sea en el futuro
        guard date > Date() else {
            print("No se puede programar notificación: la fecha debe ser en el futuro")
            return
        }
        
        // Crear el contenido de la notificación
        let content = UNMutableNotificationContent()
        content.title = "Recordatorio de hábito"
        content.body = habit.title
        
        content.sound = .default
        content.badge = 1
        
        // Agregar información adicional en el userInfo
        content.userInfo = [
            "habitId": habit.id.uuidString,
            "habitTitle": habit.title
        ]
        
        // Crear el trigger basado en la fecha
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Crear la solicitud de notificación con un identificador único basado en el ID del hábito
        let identifier = "habit-\(habit.id.uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        // Agregar la notificación al centro
        try await notificationCenter.add(request)
        
        print("Notificación programada para '\(habit.title)' el \(date)")
    }
    
    /// Cancela la notificación programada para un hábito específico
    /// - Parameter habitId: El ID del hábito cuya notificación se debe cancelar
    func cancelNotification(for habitId: UUID) {
        let identifier = "habit-\(habitId.uuidString)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🗑️ Notificación cancelada para hábito ID: \(habitId)")
    }
    
    /// Cancela todas las notificaciones pendientes
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("🗑️ Todas las notificaciones canceladas")
    }
    
    /// Actualiza la notificación de un hábito (cancela la anterior y programa una nueva)
    /// - Parameters:
    ///   - habit: El hábito cuya notificación se actualizará
    ///   - date: La nueva fecha para la notificación, o nil para cancelar
    func updateNotification(for habit: Habito, newDate: Date?) async throws {
        // Primero cancelar cualquier notificación existente
        cancelNotification(for: habit.id)
        
        // Si hay una nueva fecha, programar la notificación
        if let date = newDate {
            try await scheduleNotification(for: habit, at: date)
        }
    }
    
    /// Obtiene todas las notificaciones pendientes
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    /// Elimina las notificaciones entregadas del centro de notificaciones
    func clearDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }
}
