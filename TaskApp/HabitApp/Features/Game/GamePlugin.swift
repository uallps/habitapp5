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
    let name = "Gamificación"
    
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
    
    @MainActor
    private lazy var viewModel: GameViewModel = {
        return GameViewModel()
    }()
    
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
        VStack(alignment: .leading, spacing: 12) {
            // Toggle para habilitar/deshabilitar el plugin
            Toggle(isOn: Binding(
                get: { self.pluginEnabled },
                set: { newValue in
                    self.pluginEnabled = newValue
                    // Notificar al registry para actualizar la UI
                    Task { @MainActor in
                        PluginRegistry.shared.pluginStateDidChange()
                    }
                }
            )) {
                Label("Plugin de Gamificación", systemImage: "gamecontroller.fill")
                    .font(.headline)
            }
            
            Text("Añade mecánicas de juego como puntos, niveles y logros a tus hábitos")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if isEnabled {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Estado")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text("Puntos totales:")
                            .font(.caption)
                        Spacer()
                        Text("\(viewModel.totalPoints)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Nivel actual:")
                            .font(.caption)
                        Spacer()
                        Text("\(viewModel.currentLevel)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
    
    func mainNavigationView() -> (title: String, view: AnyView)? {
        return ("game", AnyView(GameView()))
    }
}
