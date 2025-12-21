//
//  JSONStorageProvider.swift
//  HabitApp
//
//  Created by Aula03 on 5/11/25.
//
import Foundation

class JSONStorageProvider: StorageProvider {

    static var shared: StorageProvider = JSONStorageProvider()

    private let fileURL: URL
    
    init(filename: String = "habits.json") {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        print("Documents Directory: \(documentsDirectory.path)")
        self.fileURL = documentsDirectory.appendingPathComponent(filename)
    }
    
    func loadHabits() async throws -> [Habito] {
        // Si el archivo aún no existe (primera ejecución), devolvemos una lista vacía.
        // Así evitamos inconsistencias entre datos en memoria y datos persistidos.
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        guard !data.isEmpty else { return [] }
        return try JSONDecoder().decode([Habito].self, from: data)
    }
    
    func saveHabits(habits: [Habito]) async throws {
        do {
            let data = try JSONEncoder().encode(habits)
            try data.write(to: fileURL)
        } catch {
            print("Error saving tasks: \(error)")
        }
    }
}
