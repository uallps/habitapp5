//
//  RutinaViewModel.swift
//  HabitApp
//
//  ViewModel para gestión de rutinas
//
import Foundation
import Combine
import SwiftUI

@MainActor
class RutinaViewModel: ObservableObject {
    @Published var rutinas: [Rutina] = []
    
    private let storageProvider: RutinaStorageProvider
    let habitStorageProvider: StorageProvider // Público para acceso desde vistas
    
    // Inyección de dependencias: recibe el storage provider correcto (JSON o SwiftData)
    // según la configuración del usuario en AppConfig
    init(
        storageProvider: RutinaStorageProvider,
        habitStorageProvider: StorageProvider
    ) {
        self.storageProvider = storageProvider
        self.habitStorageProvider = habitStorageProvider
    }
    
    // MARK: - Carga y Guardado
    
    func loadRutinas() async {
        do {
            rutinas = try await storageProvider.loadRutinas()
            rutinas.sort { $0.ordenEjecucion < $1.ordenEjecucion }
        } catch {
            print("❌ Error cargando rutinas: \(error)")
            rutinas = []
        }
    }
    
    private func saveRutinas() async {
        do {
            try await storageProvider.saveRutinas(rutinas: rutinas)
        } catch {
            print("❌ Error guardando rutinas: \(error)")
        }
    }
    
    // MARK: - Operaciones CRUD
    
    func addRutina(rutina: Rutina) async {
        rutina.ordenEjecucion = rutinas.count
        rutinas.append(rutina)
        await saveRutinas()
    }
    
    func updateRutina(_ rutina: Rutina) async {
        if let index = rutinas.firstIndex(where: { $0.id == rutina.id }) {
            rutinas[index] = rutina
            await saveRutinas()
            // Forzar notificación de cambio
            objectWillChange.send()
        }
    }
    
    func removeRutinas(atOffsets offsets: IndexSet) async {
        rutinas.remove(atOffsets: offsets)
        // Reordenar
        for (index, rutina) in rutinas.enumerated() {
            rutina.ordenEjecucion = index
        }
        await saveRutinas()
    }
    
    func toggleRutinaActiva(_ rutina: Rutina) async {
        if let index = rutinas.firstIndex(where: { $0.id == rutina.id }) {
            rutinas[index].isActiva.toggle()
            await saveRutinas()
        }
    }
    
    // MARK: - Operaciones con Hábitos
    
    /// Ejecuta todos los hábitos de una rutina (marca como completados)
    func ejecutarRutina(_ rutina: Rutina) async -> (markedAsCompleted: Int, totalHabits: Int)? {
        guard rutina.isActiva else {
            print("⚠️ Rutina \(rutina.nombre) está desactivada")
            return nil
        }
        
        do {
            var habitos = try await habitStorageProvider.loadHabits()

            var markedCount = 0
            let today = Date()
            
            for habitoId in rutina.habitoIds {
                if let index = habitos.firstIndex(where: { $0.id == habitoId }) {
                    // Solo marcar si el hábito está activo (no vencido) y aún no está completado hoy
                    if habitos[index].isActive(at: today) && !habitos[index].estaCompletado(en: today) {
                        habitos[index].marcarCompletado(en: today)
                        // Recontar por si en el futuro la lógica de marcar aplica más validaciones
                        if habitos[index].estaCompletado(en: today) {
                            markedCount += 1
                        }
                    }
                }
            }
            
            try await habitStorageProvider.saveHabits(habits: habitos)
            print("✅ Rutina '\(rutina.nombre)' ejecutada: \(rutina.habitoIds.count) hábitos")
            return (markedAsCompleted: markedCount, totalHabits: rutina.habitoIds.count)
        } catch {
            print("❌ Error ejecutando rutina: \(error)")
            return nil
        }
    }
    
    /// Obtiene los hábitos de una rutina
    func getHabitosForRutina(_ rutina: Rutina) async -> [Habito] {
        do {
            let allHabitos = try await habitStorageProvider.loadHabits()
            return allHabitos.filter { rutina.habitoIds.contains($0.id) }
        } catch {
            print("❌ Error obteniendo hábitos de rutina: \(error)")
            return []
        }
    }
    
    /// Obtiene todos los hábitos disponibles
    func getAllHabitos() async -> [Habito] {
        do {
            return try await habitStorageProvider.loadHabits()
        } catch {
            print("❌ Error obteniendo todos los hábitos: \(error)")
            return []
        }
    }
    
    /// Elimina un hábito de todas las rutinas
    func removeHabitoFromRutinas(habitoId: UUID) async {
        do {
            // Cargar siempre las rutinas desde el storage para evitar usar
            // instancias de SwiftData que ya hayan sido eliminadas del contexto.
            var actuales = try await storageProvider.loadRutinas()
            var modified = false

            for rutina in actuales {
                if rutina.habitoIds.contains(habitoId) {
                    rutina.habitoIds.removeAll { $0 == habitoId }
                    modified = true
                }
            }

            if modified {
                try await storageProvider.saveRutinas(rutinas: actuales)
                // Mantener el estado del ViewModel sincronizado con lo persistido
                rutinas = actuales.sorted { $0.ordenEjecucion < $1.ordenEjecucion }
                print("Hábito eliminado de rutinas")
            }
        } catch {
            print("❌ Error eliminando hábito de rutinas: \(error)")
        }
    }
    
    // MARK: - Métodos Auxiliares
    
    func getRutinasConHabito(habitoId: UUID) -> [Rutina] {
        // Para depuración y uso en plugins preferimos trabajar con el
        // estado en memoria actual, pero si algún modelo estuviera
        // detached de SwiftData, este acceso se podría volver inseguro.
        // En ese caso se podría migrar esta función a una versión async
        // que recargue desde storage, similar a removeHabitoFromRutinas.
        return rutinas.filter { $0.habitoIds.contains(habitoId) }
    }
}
