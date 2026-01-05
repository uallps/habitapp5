//
//  GameSettingsView.swift
//  HabitApp
//
//  Vista de configuración del plugin de gamificación
//

import SwiftUI

struct GameSettingsView: View {
    @AppStorage("plugin.game.enabled") private var isEnabled = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Toggle para habilitar/deshabilitar el plugin
            Toggle(isOn: Binding(
                get: { isEnabled },
                set: { newValue in
                    isEnabled = newValue
                    // Notificar al registry para actualizar la UI
                    PluginRegistry.shared.pluginStateDidChange()
                }
            )) {
                Label("Plugin de Gamificación", systemImage: "gamecontroller.fill")
                    .font(.headline)
            }
            
            Text("Activa mecánicas de juego como puntos, niveles y logros")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            HStack {
                Text("Estado:")
                    .font(.caption)
                Spacer()
                Text(isEnabled ? "Activo" : "Inactivo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    GameSettingsView()
}
