//
//  GameStorageService.swift
//  HabitApp
//
//  Servicio de persistencia para datos del plugin de gamificación
//

import Foundation

/// Servicio de almacenamiento para datos del juego
class GameStorageService {
    
    static let shared = GameStorageService()
    
    private let fileURL: URL
    private let userDefaultsKey = "game.data"
    
    private init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documentsDirectory.appendingPathComponent("game_data.json")
        print("[GameStorage] File URL: \(fileURL.path)")
    }
    
    // MARK: - Load
    
    /// Carga los datos del juego desde el almacenamiento persistente
    func loadGameData() async throws -> GameData {
        // Intentar cargar desde archivo JSON primero (para compatibilidad multiplataforma)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            if !data.isEmpty {
                let gameData = try JSONDecoder().decode(GameData.self, from: data)
                print("[GameStorage] Loaded from JSON: \(gameData.habitProgresses.count) habit progresses")
                return gameData
            }
        }
        
        // Si no existe archivo, devolver datos vacíos
        print("[GameStorage] No existing data found, returning empty GameData")
        return GameData()
    }
    
    // MARK: - Save
    
    /// Guarda los datos del juego en el almacenamiento persistente
    func saveGameData(_ gameData: GameData) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(gameData)
        
        // Guardar en archivo JSON (funciona en macOS e iOS)
        try data.write(to: fileURL, options: [.atomic])
        
        print("[GameStorage] Saved to JSON: \(gameData.habitProgresses.count) habit progresses")
        
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64) ?? -1
        print("[GameStorage] File size: \(fileSize) bytes")
    }
    
    // MARK: - Clear
    
    /// Elimina todos los datos del juego (útil para testing o reset)
    func clearAllData() async throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
            print("[GameStorage] All game data cleared")
        }
    }
}
