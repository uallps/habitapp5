//
//  GamePlugin.swift
//  HabitApp
//
//  Plugin de gamificación para HabitApp
//

import SwiftUI

/// Plugin de gamificación que añade mecánicas de juego a los hábitos
final class GamePlugin: ObservableObject, FeaturePlugin {
    static let shared = GamePlugin()
    
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "feature_game_enabled")
            NotificationCenter.default.post(name: .featureToggled, object: nil)
        }
    }
    
    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "feature_game_enabled")
    }
    
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
    
    var menuOrder: Int {
        2 // Después de Rutinas (1) pero antes de otros plugins futuros
    }
    
    func makeView() -> AnyView {
        AnyView(GameView())
    }
    
    func makeSettingsView() -> AnyView {
        AnyView(GameSettingsView())
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let featureToggled = Notification.Name("featureToggled")
}
