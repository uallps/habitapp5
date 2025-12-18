//
//  TaskAppApp.swift
//  TaskApp
//
//  Created by Aula03 on 15/10/25.
//

import SwiftUI

@main
struct HabitApp: App {
    @State private var selectedDetailView: String?
    
    private var storageProvider: StorageProvider {
        AppConfig().storageProvider
    }
    
    init() {
        // Solicitar permisos de notificaciones al iniciar la app
        Task {
            let notificationService = NotificationService.shared
            
            do {
                let granted = try await notificationService.requestAuthorization()
                if granted {
                    print("Permisos de notificaciones concedidos")
                } else {
                    print("Permisos de notificaciones denegados")
                }
            } catch {
                print("Error solicitando permisos de notificaciones: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup{
            #if os(iOS)
            TabView {
                HabitListView(storageProvider: storageProvider)
                    .tabItem {
                        Label("Habitos", systemImage: "checklist")
                    }
                SettingsView()
                    .tabItem {
                        Label("Ajustes", systemImage: "gearshape")
                    }
            }            .environmentObject(AppConfig())

            #else
            NavigationSplitView {
                List(selection: $selectedDetailView) {
                    NavigationLink(value: "habitos") {
                        Label("Habitos", systemImage: "checklist")
                    }
                    NavigationLink(value: "ajustes") {
                        Label("Ajustes", systemImage: "gearshape")
                    }
                }
            } detail: {
                switch selectedDetailView {
                case "habitos":
                    HabitListView(storageProvider: storageProvider)
                case "ajustes":
                    SettingsView()
                default:
                    Text("Seleccione una opción")
                }
            }            .environmentObject(AppConfig())

            #endif

        }
    }
}

