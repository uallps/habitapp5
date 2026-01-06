//
//  Settings.swift
//  HabitApp
//
//  Created by Aula03 on 5/11/25.
//
import SwiftUI


struct SettingsView: View {
    private enum Layout {
        static let maxContentWidth: CGFloat = 560
    }

    @EnvironmentObject private var appConfig: AppConfig
    @ObservedObject private var pluginRegistry = PluginRegistry.shared

    private var settingsForm: some View {
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
            let pluginViews = pluginRegistry.getPluginSettingsViews()
            if !pluginViews.isEmpty {
                Section(header: Text("Plugins")) {
                    ForEach(0..<pluginViews.count, id: \.self) { index in
                        #if os(macOS)
                        HStack(spacing: 0) {
                            pluginViews[index]
                                .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                        #else
                        pluginViews[index]
                        #endif
                    }
                }
            }
        }
    }

    var body: some View {
        Group {
            #if os(macOS)
            ScrollView {
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    settingsForm
                        .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 8)
            }
            #else
            settingsForm
            #endif
        }
        .appFormContainer()
        .navigationTitle("Ajustes")
    }
}
