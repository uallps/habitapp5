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
        VStack(alignment: .leading, spacing: 16) {
            // Toggle principal
            Toggle(isOn: $isEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gamificación")
                        .font(.headline)
                    
                    Text("Activa mecánicas de juego como puntos, niveles y logros")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: isEnabled) { _, newValue in
                // Notificar al registry para actualizar la UI
                Task { @MainActor in
                    PluginRegistry.shared.pluginStateDidChange()
                }
            }
            
            if isEnabled {
                Divider()
                
                // Configuraciones adicionales (futuras)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Configuración")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    // Placeholder para configuraciones futuras
                    Text("Las opciones de configuración estarán disponibles próximamente")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    GameSettingsView()
}
