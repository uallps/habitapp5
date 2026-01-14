//
//  RutinaStorageProvider.swift
//  HabitApp
//
//  Provider para persistencia de rutinas
//
import Foundation
import SwiftData

protocol RutinaStorageProvider {
    func loadRutinas() async throws -> [Rutina]
    func saveRutinas(rutinas: [Rutina]) async throws
    func loadRutina(for id: UUID) async throws -> Rutina?
    func saveRutina(_ rutina: Rutina) async throws
    func deleteRutina(_ rutina: Rutina) async throws
}

// MARK: - Implementación SwiftData

@MainActor
final class SwiftDataRutinaStorageProvider: RutinaStorageProvider {
    static let shared = SwiftDataRutinaStorageProvider()
    
    private let context: ModelContext
    
    private init() {
        guard let context = SwiftDataContext.shared else {
            fatalError("SwiftData context not initialized")
        }
        self.context = context
    }
    
    func loadRutinas() async throws -> [Rutina] {
        let descriptor = FetchDescriptor<Rutina>(
            sortBy: [SortDescriptor(\.ordenEjecucion)]
        )
        let rutinas = try context.fetch(descriptor)
        print("✅ Cargadas \(rutinas.count) rutinas desde SwiftData")
        return rutinas
    }
    
    func saveRutinas(rutinas: [Rutina]) async throws {
        let existingRutinas = try context.fetch(FetchDescriptor<Rutina>())
        let desiredIds = Set(rutinas.map { $0.id })
        var existingById: [UUID: Rutina] = Dictionary(
            uniqueKeysWithValues: existingRutinas.map { ($0.id, $0) }
        )

        // Eliminar las rutinas que ya no están en la lista
        for existing in existingRutinas where !desiredIds.contains(existing.id) {
            context.delete(existing)
        }

        // Insertar o actualizar
        for rutina in rutinas {
            if let existing = existingById[rutina.id] {
                // Si por algún motivo viene otra instancia, sincronizar campos
                if existing !== rutina {
                    existing.nombre = rutina.nombre
                    existing.descripcion = rutina.descripcion
                    existing.habitoIds = rutina.habitoIds
                    existing.color = rutina.color
                    existing.isActiva = rutina.isActiva
                    existing.fechaCreacion = rutina.fechaCreacion
                    existing.ordenEjecucion = rutina.ordenEjecucion
                }
            } else {
                context.insert(rutina)
                existingById[rutina.id] = rutina
            }
        }
        try context.save()
        print("Guardadas \(rutinas.count) rutinas en SwiftData")
    }
    
    func loadRutina(for id: UUID) async throws -> Rutina? {
        let descriptor = FetchDescriptor<Rutina>(
            predicate: #Predicate { $0.id == id }
        )
        let rutinas = try context.fetch(descriptor)
        return rutinas.first
    }
    
    func saveRutina(_ rutina: Rutina) async throws {
        let existing = try await loadRutina(for: rutina.id)
        if existing == nil {
            context.insert(rutina)
        }
        try context.save()
    }
    
    func deleteRutina(_ rutina: Rutina) async throws {
        if let existing = try await loadRutina(for: rutina.id) {
            context.delete(existing)
        } else {
            context.delete(rutina)
        }
        try context.save()
        print("Rutina eliminada de SwiftData")
    }
}

// MARK: - Implementación JSON

final class JSONRutinaStorageProvider: RutinaStorageProvider {
    static let shared = JSONRutinaStorageProvider()
    
    private let fileManager = FileManager.default
    private let fileName = "rutinas.json"
    
    private init() {}
    
    private var fileURL: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    func loadRutinas() async throws -> [Rutina] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("Archivo de rutinas no existe, devolviendo array vacío")
            return []
        }
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let rutinas = try decoder.decode([Rutina].self, from: data)
        print("✅ Cargadas \(rutinas.count) rutinas desde JSON")
        return rutinas
    }
    
    func saveRutinas(rutinas: [Rutina]) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(rutinas)
        try data.write(to: fileURL, options: .atomic)
        print("Guardadas \(rutinas.count) rutinas en JSON")
    }
    
    func loadRutina(for id: UUID) async throws -> Rutina? {
        let rutinas = try await loadRutinas()
        return rutinas.first { $0.id == id }
    }
    
    func saveRutina(_ rutina: Rutina) async throws {
        var rutinas = try await loadRutinas()
        if let index = rutinas.firstIndex(where: { $0.id == rutina.id }) {
            rutinas[index] = rutina
        } else {
            rutinas.append(rutina)
        }
        try await saveRutinas(rutinas: rutinas)
    }
    
    func deleteRutina(_ rutina: Rutina) async throws {
        var rutinas = try await loadRutinas()
        rutinas.removeAll { $0.id == rutina.id }
        try await saveRutinas(rutinas: rutinas)
    }
}

// MARK: - Implementación Mock

final class MockRutinaStorageProvider: RutinaStorageProvider {
    static let shared = MockRutinaStorageProvider()
    
    private var rutinas: [Rutina] = []
    
    private init() {}
    
    func loadRutinas() async throws -> [Rutina] {
        print("[Mock] Cargando rutinas")
        return rutinas
    }
    
    func saveRutinas(rutinas: [Rutina]) async throws {
        self.rutinas = rutinas
        print("[Mock] Guardadas \(rutinas.count) rutinas")
    }
    
    func loadRutina(for id: UUID) async throws -> Rutina? {
        return rutinas.first { $0.id == id }
    }
    
    func saveRutina(_ rutina: Rutina) async throws {
        if let index = rutinas.firstIndex(where: { $0.id == rutina.id }) {
            rutinas[index] = rutina
        } else {
            rutinas.append(rutina)
        }
    }
    
    func deleteRutina(_ rutina: Rutina) async throws {
        rutinas.removeAll { $0.id == rutina.id }
    }
}
