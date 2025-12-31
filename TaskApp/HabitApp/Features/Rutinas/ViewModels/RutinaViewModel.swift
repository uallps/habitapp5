//
//  RutinaViewModel.swift
//  HabitApp
//
//  ViewModel para gestión de rutinas
//
import Foundation
import Combine
internal import SwiftUI

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
            
            for habitoId in rutina.habitoIds {
                if let index = habitos.firstIndex(where: { $0.id == habitoId }) {
                    // Usar el nuevo método toggleCompletitud para marcar como completado hoy
                    if !habitos[index].estaCompletado(en: Date()) {
                        habitos[index].marcarCompletado(en: Date())
                        markedCount += 1
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
        var modified = false
        
        for rutina in rutinas {
            if rutina.habitoIds.contains(habitoId) {
                rutina.habitoIds.removeAll { $0 == habitoId }
                modified = true
            }
        }
        
        if modified {
            await saveRutinas()
            print("Hábito eliminado de rutinas")
        }
    }
    
    // MARK: - Métodos Auxiliares
    
    func getRutinasConHabito(habitoId: UUID) -> [Rutina] {
        return rutinas.filter { $0.habitoIds.contains(habitoId) }
    }
}
