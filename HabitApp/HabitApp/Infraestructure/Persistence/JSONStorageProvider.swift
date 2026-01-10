//
//  JSONStorageProvider.swift
//  HabitApp
//
//  Created by Aula03 on 5/11/25.
//
import Foundation

class JSONStorageProvider: StorageProvider {

    static let shared = JSONStorageProvider()

    private let fileURL: URL
    
    init(filename: String = "habits.json") {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        print("[DEBUG] JSONStorageProvider: Documents Directory: \(documentsDirectory.path)")
        self.fileURL = documentsDirectory.appendingPathComponent(filename)
        print("[DEBUG] JSONStorageProvider: File URL: \(self.fileURL.path)")
    }
    
    func loadHabits() async throws -> [Habito] {
        print("[DEBUG] JSONStorageProvider: Loading from \(fileURL.path)")
        // Si el archivo aún no existe (primera ejecución), devolvemos una lista vacía.
        // Así evitamos inconsistencias entre datos en memoria y datos persistidos.
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("[DEBUG] JSONStorageProvider: Archivo de hábitos no existe, devolviendo array vacío")
            return []
        }

        let data = try Data(contentsOf: fileURL)
        guard !data.isEmpty else {
            print("[DEBUG] JSONStorageProvider: Archivo de hábitos vacío")
            return []
        }
        let habitos = try JSONDecoder().decode([Habito].self, from: data)
        print("[DEBUG] JSONStorageProvider: Habitos cargados: \(habitos.map { $0.title })")
        return habitos
    }
    
    func saveHabits(habits: [Habito]) async throws {
        let data = try JSONEncoder().encode(habits)
        try data.write(to: fileURL, options: [.atomic])
        print("[DEBUG] JSONStorageProvider: Habitos guardados: \(habits.map { $0.title })")

        let exists = FileManager.default.fileExists(atPath: fileURL.path)
        let fileSize: Int64 = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64) ?? -1
        print("[DEBUG] JSONStorageProvider: Post-save exists=\(exists) size=\(fileSize) bytes")
    }
}
