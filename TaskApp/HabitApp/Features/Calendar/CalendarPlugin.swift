//
//  CalendarPlugin.swift
//  HabitApp
//
//  Plugin desacoplado: vista de calendario de completitudes
//

import Foundation
import SwiftUI
import SwiftData

final class CalendarPlugin: ViewPlugin {

    // MARK: - FeaturePlugin

    let identifier = "com.habitapp.calendar"
    let name = "Calendario"

    var models: [any PersistentModel.Type] {
        // Este plugin no persiste modelos propios.
        return []
    }

    @AppStorage("plugin.calendar.enabled")
    private var pluginEnabled: Bool = true

    var isEnabled: Bool {
        pluginEnabled
    }

    private let config: AppConfig

    required init(config: AppConfig) {
        self.config = config
        print("CalendarPlugin inicializado - Enabled: \(isEnabled)")
    }

    // MARK: - ViewPlugin

    func habitRowView(for habito: Habito) -> some View {
        EmptyView()
    }

    func habitDetailView(for habito: Binding<Habito>) -> some View {
        EmptyView()
    }

    func settingsView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: Binding(
                get: { self.pluginEnabled },
                set: { newValue in
                    self.pluginEnabled = newValue
                    PluginRegistry.shared.pluginStateDidChange()
                }
            )) {
                Label("Plugin de Calendario", systemImage: "calendar")
                    .font(.headline)
            }

            Text("Consulta en el calendario tus hábitos programados y completados cada día, navega por meses y crea, modifica o elimina hábitos desde esta ventana.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            HStack {
                Text("Estado:")
                    .font(.caption)
                Spacer()
                Text(pluginEnabled ? "Activo" : "Inactivo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    func mainNavigationView() -> (title: String, view: AnyView)? {
        ("Calendario", AnyView(CalendarView(storageProvider: config.storageProvider)))
    }
}
