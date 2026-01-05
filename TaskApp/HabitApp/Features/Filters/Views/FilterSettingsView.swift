//
//  FilterSettingsView.swift
//  HabitApp
//
//  Vista de configuración del plugin de filtros
//

import SwiftUI

struct FilterSettingsView: View {
    @AppStorage("plugin.filter.enabled") private var isEnabled = true
    
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
                Label("Plugin de Filtros", systemImage: "line.3.horizontal.decrease.circle")
                    .font(.headline)
            }
            
            Text("Permite filtrar hábitos por categoría, prioridad, frecuencia y búsqueda")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            HStack {
                Text("Filtros disponibles:")
                    .font(.caption)
                Spacer()
                Text("4")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FilterSettingsView()
}
