//
//  Settings.swift
//  HabitApp
//
//  Created by Aula03 on 5/11/25.
//
internal import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appConfig: AppConfig

    var body: some View {
        Form {
            Section(header: Text("General")) {
                Toggle("Show Due Dates", isOn: $appConfig.showDueDates)
                Toggle("Show Priorities", isOn: $appConfig.showPriorities)
                Toggle("Enable Reminders", isOn: $appConfig.enableReminders)
                Picker("Storage Type", selection: $appConfig.storageType) {
                    ForEach(StorageType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }
            
            // Sección dinámica de plugins
            // Muestra configuración de plugins instalados (si existen)
            let pluginViews = PluginRegistry.shared.getPluginSettingsViews()
            if !pluginViews.isEmpty {
                Section(header: Text("Plugins")) {
                    ForEach(0..<pluginViews.count, id: \.self) { index in
                        pluginViews[index]
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}
