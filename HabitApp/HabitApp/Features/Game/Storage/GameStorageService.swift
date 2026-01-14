//
//  GameStorageService.swift
//  HabitApp
//
//  Servicio de persistencia para datos del plugin de gamificación
//

import Foundation
import SwiftUI
import SwiftData

/// Tipo de almacenamiento para el plugin de Game
enum GameStorageType {
    case json
    case swiftData
}

/// Servicio de almacenamiento para datos del juego
@MainActor
class GameStorageService {
    
    // MARK: - Properties
    
    private let storageType: GameStorageType
    private let fileURL: URL
    private var swiftDataContext: ModelContext?
    
    // MARK: - Initialization
    
    init(storageType: GameStorageType) {
        self.storageType = storageType
        
        // Configurar URL para JSON
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documentsDirectory.appendingPathComponent("game_data.json")
        
        // Configurar contexto para SwiftData
        if storageType == .swiftData {
            self.swiftDataContext = SwiftDataContext.shared
        }
        
        print("[GameStorage] Initialized with \(storageType == .json ? "JSON" : "SwiftData") storage")
        print("[GameStorage] JSON File URL: \(fileURL.path)")
    }
    
    // MARK: - Load
    
    /// Carga los datos del juego desde el almacenamiento persistente
    func loadGameData() async throws -> GameData {
        switch storageType {
        case .json:
            return try await loadFromJSON()
        case .swiftData:
            return try await loadFromSwiftData()
        }
    }
    
    private func loadFromJSON() async throws -> GameData {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            if !data.isEmpty {
                let gameData = try JSONDecoder().decode(GameData.self, from: data)
                print("[GameStorage] Loaded from JSON: \(gameData.habitProgresses.count) habit progresses")
                return gameData
            }
        }
        
        print("[GameStorage] No JSON data found, returning empty GameData")
        return GameData()
    }
    
    private func loadFromSwiftData() async throws -> GameData {
        guard let context = swiftDataContext else {
            print("[GameStorage] SwiftData context not available")
            return GameData()
        }
        
        let descriptor = FetchDescriptor<GameDataModel>()
        let models = try context.fetch(descriptor)
        
        if let model = models.first {
            let gameData = try model.toGameData()
            print("[GameStorage] Loaded from SwiftData: \(gameData.habitProgresses.count) habit progresses")
            return gameData
        }
        
        print("[GameStorage] No SwiftData found, returning empty GameData")
        return GameData()
    }
    
    // MARK: - Save
    
    /// Guarda los datos del juego en el almacenamiento persistente
    func saveGameData(_ gameData: GameData) async throws {
        switch storageType {
        case .json:
            try await saveToJSON(gameData)
        case .swiftData:
            try await saveToSwiftData(gameData)
        }
    }
    
    private func saveToJSON(_ gameData: GameData) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(gameData)
        
        try data.write(to: fileURL, options: [.atomic])
        
        print("[GameStorage] Saved to JSON: \(gameData.habitProgresses.count) habit progresses")
        
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64) ?? -1
        print("[GameStorage] File size: \(fileSize) bytes")
    }
    
    private func saveToSwiftData(_ gameData: GameData) async throws {
        guard let context = swiftDataContext else {
            throw NSError(domain: "GameStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "SwiftData context not available"])
        }
        
        let descriptor = FetchDescriptor<GameDataModel>()
        let existingModels = try context.fetch(descriptor)
        
        let model: GameDataModel
        if let existing = existingModels.first {
            model = existing
        } else {
            model = GameDataModel()
            context.insert(model)
        }
        
        try model.update(from: gameData)
        try context.save()
        
        print("[GameStorage] Saved to SwiftData: \(gameData.habitProgresses.count) habit progresses")
    }
    
    // MARK: - Clear
    
    /// Elimina todos los datos del juego (útil para testing o reset)
    func clearAllData() async throws {
        switch storageType {
        case .json:
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                print("[GameStorage] All JSON game data cleared")
            }
        case .swiftData:
            guard let context = swiftDataContext else { return }
            
            let descriptor = FetchDescriptor<GameDataModel>()
            let models = try context.fetch(descriptor)
            
            for model in models {
                context.delete(model)
            }
            
            try context.save()
            print("[GameStorage] All SwiftData game data cleared")
        }
    }
}

