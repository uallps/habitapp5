//
//  GamePlugin.swift
//  HabitApp
//
//  Plugin de gamificación para HabitApp
//

import SwiftUI

/// Plugin de gamificación que añade mecánicas de juego a los hábitos
final class GamePlugin: FeaturePlugin {
    static let shared = GamePlugin()
    
    private init() {}
    
    // MARK: - FeaturePlugin Protocol
    
    var id: String {
        "com.habitapp.game"
    }
    
    var name: String {
        "Gamificación"
    }
    
    var description: String {
        "Añade mecánicas de juego como puntos, niveles y logros a tus hábitos"
    }
    
    var icon: String {
        "gamecontroller.fill"
    }
    
    var isEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "feature_game_enabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "feature_game_enabled")
            NotificationCenter.default.post(name: .featureToggled, object: nil)
        }
    }
    
    var menuOrder: Int {
        2 // Después de Rutinas (1) pero antes de otros plugins futuros
    }
    
    @ViewBuilder
    func makeView() -> some View {
        GameView()
    }
    
    @ViewBuilder
    func makeSettingsView() -> some View {
        GameSettingsView()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let featureToggled = Notification.Name("featureToggled")
}
