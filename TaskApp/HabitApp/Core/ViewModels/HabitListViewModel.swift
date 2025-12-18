//
//  TaskListViewModel.swift
//  TaskApp
//
//  Created by Aula03 on 15/10/25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class HabitListViewModel: ObservableObject{
    private let storageProvider: StorageProvider
    private let notificationService = NotificationService.shared
    
    init(storageProvider: StorageProvider = SwiftDataStorageProvider()) {
        self.storageProvider = storageProvider
    }

    @Published var habitos: [Habito]=[
        Habito(title: "Jugar al Hollow", descripcion: "Es un juegazo", prioridad: .low, fechaFin: Date().addingTimeInterval(86400)),
        Habito(title: "Terminar LPS", descripcion: "Vamos atrasados", prioridad: .high)
    ]
    
    
    func loadHabits() async {
        do {
            habitos = try await storageProvider.loadHabits()
            // Reprogramar notificaciones para hábitos cargados que tengan recordatorios futuros
            await scheduleNotificationsForLoadedHabits()
        } catch {
            print("Error loading tasks: \(error)")
        }
    }
    
    func addHabit(habit: Habito) {
        habitos.append(habit)
        
        // Programar notificación si tiene fecha de recordatorio
        if let reminderDate = habit.reminderDate {
            Task {
                try? await notificationService.scheduleNotification(for: habit, at: reminderDate)
            }
        }
    }
    
    func removeHabits(atOffsets offsets: IndexSet) async{
        // Cancelar notificaciones de los hábitos que se van a eliminar
        for index in offsets {
            notificationService.cancelNotification(for: habitos[index].id)
        }
        
        habitos.remove(atOffsets: offsets)
        try? await storageProvider.saveHabits(habits: habitos)
    }
    
    func saveHabits() async {
        try? await storageProvider.saveHabits(habits: habitos)
        
        // Actualizar notificaciones de todos los hábitos
        await updateAllNotifications()
    }
    
    func toggleCompletion(task: Habito) {
        if let index = habitos.firstIndex(where: { $0.id == task.id }) {
            habitos[index].completada.toggle()
            
            if habitos[index].completada {
                habitos[index].fechaCompletitud?.append(Date())
            } else {
                //tasks[index].fechaCompletitud?.
            }
        }
    }
    
    // MARK: - Notification Management
    
    /// Programa notificaciones para todos los hábitos cargados que tengan recordatorios
    private func scheduleNotificationsForLoadedHabits() async {
        for habit in habitos {
            if let reminderDate = habit.reminderDate, reminderDate > Date() {
                try? await notificationService.scheduleNotification(for: habit, at: reminderDate)
            }
        }
    }
    
    /// Actualiza las notificaciones de todos los hábitos
    private func updateAllNotifications() async {
        for habit in habitos {
            try? await notificationService.updateNotification(for: habit, newDate: habit.reminderDate)
        }
    }
    
}
