//
//  GamePlugin.swift
//  HabitApp
//
//  Plugin de gamificación para HabitApp
//

import Foundation
import SwiftUI
import SwiftData

final class GamePlugin: ViewPlugin {
    
    // MARK: - Propiedades de FeaturePlugin
    
    let identifier = "com.habitapp.game"
    let name = "Juego"
    
    var models: [any PersistentModel.Type] {
        return [] // TODO: Agregar modelos cuando se implementen
    }
    
    // El plugin gestiona su propio estado de habilitación
    @AppStorage("plugin.game.enabled")
    private var pluginEnabled: Bool = false
    
    var isEnabled: Bool {
        return pluginEnabled
    }
    
    // MARK: - Propiedades Privadas
    
    private let config: AppConfig
    
    // MARK: - Inicialización
    
    required init(config: AppConfig) {
        self.config = config
        print("GamePlugin inicializado - Enabled: \(isEnabled)")
    }
    
    // MARK: - Implementación de ViewPlugin
    
    func habitRowView(for habito: Habito) -> some View {
        // Por ahora, no mostramos nada en la fila del hábito
        EmptyView()
    }
    
    func habitDetailView(for habito: Binding<Habito>) -> some View {
        // Por ahora, no mostramos nada en el detalle del hábito
        EmptyView()
    }
    
    func settingsView() -> some View {
        GameSettingsView()
    }
    
    func mainNavigationView() -> (title: String, view: AnyView)? {
        return ("Juego", AnyView(
            GameView(storageProvider: config.storageProvider)
                .environmentObject(config)
        ))
    }
}
