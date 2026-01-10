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

    @Published var habitos: [Habito] = []
    
    
    func loadHabits() async {
        do {
            habitos = try await storageProvider.loadHabits()
            // Reprogramar notificaciones para hábitos cargados que tengan recordatorios futuros
            await scheduleNotificationsForLoadedHabits()
        } catch {
            print("Error loading tasks: \(error)")
        }
    }
    
    func addHabit(habit: Habito) async {
        if habit.fechaInicio == nil {
            habit.fechaInicio = Calendar.current.startOfDay(for: Date())
        }
        habitos.append(habit)

        await persistAndNotifyAfterAdding(habit)
    }

    /// Crea el hábito y devuelve inmediatamente (útil para navegar al detalle sin esperar a la persistencia).
    /// La persistencia, notificaciones y avisos a plugins ocurren en segundo plano.
    func addHabitOptimistically(habit: Habito) {
        if habit.fechaInicio == nil {
            habit.fechaInicio = Calendar.current.startOfDay(for: Date())
        }
        habitos.append(habit)

        Task { @MainActor in
            await persistAndNotifyAfterAdding(habit)
        }
    }

    private func persistAndNotifyAfterAdding(_ habit: Habito) async {
        // Persistir inmediatamente para que cualquier pantalla/feature que lea
        // desde StorageProvider vea el mismo estado que la lista principal.
        do {
            try await storageProvider.saveHabits(habits: habitos)
        } catch {
            print("[ERROR] Failed saving habits after add: \(error)")
        }

        // Notificar a plugins que se creó un nuevo hábito
        await PluginRegistry.shared.notifyHabitoDidCreate(habit)

        // Programar notificación si tiene fecha de recordatorio
        if let reminderDate = habit.reminderDate {
            try? await notificationService.scheduleNotification(for: habit, at: reminderDate)
        }
    }
    
    func removeHabits(atOffsets offsets: IndexSet) async{
        // Notificar a plugins antes de eliminar y cancelar notificaciones
        for index in offsets {
            let habit = habitos[index]
            await PluginRegistry.shared.notifyHabitoWillBeDeleted(habit)
            notificationService.cancelNotification(for: habit.id)
        }
        
        // Guardar IDs antes de eliminar para notificar después
        let deletedIds = offsets.map { habitos[$0].id }
        
        // Importante (SwiftData/iOS): si eliminamos del ModelContext en el mismo ciclo en que la List
        // todavía está renderizando una fila, SwiftData puede lanzar un fatal error por objeto "detached".
        // 1) Quitamos el elemento del array sin animación.
        // 2) Retrasamos ligeramente el guardado (que elimina del contexto) para dar tiempo a la UI a
        //    recomputar sin tocar el objeto eliminado.
        withTransaction(Transaction(animation: nil)) {
            habitos.remove(atOffsets: offsets)
        }

        try? await Task.sleep(nanoseconds: 250_000_000)

        do {
            try await storageProvider.saveHabits(habits: habitos)
        } catch {
            print("[ERROR] Failed saving habits after delete: \(error)")
        }
        
        // Notificar a plugins después de eliminar
        for id in deletedIds {
            await PluginRegistry.shared.notifyHabitoDidDelete(habitoId: id)
        }
    }
    
    func saveHabits() async {
        // Notificar a plugins antes de guardar
        for habit in habitos {
            await PluginRegistry.shared.notifyHabitoWillBeUpdated(habit)
        }
        
        do {
            try await storageProvider.saveHabits(habits: habitos)
        } catch {
            print("[ERROR] Failed saving habits: \(error)")
        }
        
        // Notificar a plugins después de guardar
        for habit in habitos {
            await PluginRegistry.shared.notifyHabitoDidUpdate(habit)
        }
        
        // Actualizar notificaciones de todos los hábitos
        await updateAllNotifications()
    }
    
    func toggleCompletion(task: Habito) async {
        guard let index = habitos.firstIndex(where: { $0.id == task.id }) else {
            return
        }

        // Toggle completitud para el día actual
        habitos[index].toggleCompletitud(para: Date())

        do {
            try await storageProvider.saveHabits(habits: habitos)
        } catch {
            print("[ERROR] Failed saving habits after toggleCompletion: \(error)")
        }

        await PluginRegistry.shared.notifyHabitoDidUpdate(habitos[index])
        await updateAllNotifications()
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
