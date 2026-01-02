//
//  TaskAppApp.swift
//  TaskApp
//
//  Created by Aula03 on 15/10/25.
//

internal import SwiftUI
import SwiftData

@main
struct HabitApp: App {
    @State private var selectedDetailView: String?
    @StateObject private var appConfig: AppConfig
    //Necesitamos pluginRegistry para poder observar cambios y actualizar la vista de plugins.
    @StateObject private var pluginRegistry = PluginRegistry.shared
    
    private var storageProvider: StorageProvider {
        appConfig.storageProvider
    }
    
    init() {
        // Crear UNA sola instancia de AppConfig y compartirla con toda la app y los plugins.
        // Esto evita que cada plugin tenga su propio AppConfig (y potencialmente un StorageProvider distinto) (Ya ha ocurrido :D).
        let config = AppConfig()
        _appConfig = StateObject(wrappedValue: config)

        // IMPORTANTE: Inicializar SwiftData ANTES de cualquier otra cosa
        // para que los storage providers puedan usarlo
        Self.initializeSwiftDataOnce()
        
        // Inicializar sistema de plugins con auto-discovery
        setupPlugins(config: config)
        
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
    
    // Inicializa SwiftData una sola vez con todos los modelos del core y plugins
    private static var isSwiftDataInitialized = false
    private static func initializeSwiftDataOnce() {
        guard !isSwiftDataInitialized else { return }
        isSwiftDataInitialized = true
        
        var allModels: [any PersistentModel.Type] = [Habito.self]
        
        // Descubrir plugins y agregar sus modelos
        let discoveredPlugins = PluginDiscovery.discoverPlugins()
        for pluginType in discoveredPlugins {
            // Crear una instancia temporal solo para obtener los modelos
            // Sin usar AppConfig para evitar ciclos
            let plugin = pluginType.init(config: AppConfig())
            allModels.append(contentsOf: plugin.models)
        }
        
        SwiftDataContext.initialize(with: allModels)
        print("SwiftData inicializado con \(allModels.count) modelos")
    }
    
    // Auto-discovery: descubre y registra automáticamente todos los plugins disponibles
    // Permite que la app funcione con o sin plugins presentes
    private func setupPlugins(config: AppConfig) {
        print("Inicializando sistema de plugins...")
        
        let registry = PluginRegistry.shared
        
        // Descubrir automáticamente todos los plugins
        let discoveredPlugins = PluginDiscovery.discoverPlugins()
        for plugin in discoveredPlugins {
            registry.register(plugin)
        }
        
        // Crear instancias de los plugins registrados usando la MISMA configuración que el core.
        _ = registry.createPluginInstances(config: config)
        
        print("Plugins registrados: \(registry.count)")
    }

    var body: some Scene {
        WindowGroup{
            #if os(iOS)
            TabView {
                HabitListView(storageProvider: storageProvider)
                    .tabItem {
                        Label("Habitos", systemImage: "checklist")
                    }
                
                StatisticsView()
                    .tabItem {
                        Label("Estadísticas", systemImage: "chart.bar.fill")
                    }
                
                // Vistas de navegación proporcionadas por los plugins
                ForEach(PluginRegistry.shared.getPluginMainNavigationViews(), id: \.id) { nav in
                    nav.view
                        .tabItem {
                            Label(nav.title, systemImage: "puzzlepiece.extension")
                        }
                }
                
                SettingsView()
                    .tabItem {
                        Label("Ajustes", systemImage: "gearshape")
                    }
            }            .environmentObject(appConfig)

            #else
            NavigationSplitView {
                List(selection: $selectedDetailView) {
                    NavigationLink(value: "habitos") {
                        Label("Habitos", systemImage: "checklist")
                    }
                    
                    NavigationLink(value: "estadisticas") {
                        Label("Estadísticas", systemImage: "chart.bar.fill")
                    }
                    
                    // Links de navegación proporcionados por los plugins
                    ForEach(PluginRegistry.shared.getPluginMainNavigationViews(), id: \.id) { nav in
                        NavigationLink(value: nav.id) {
                            Label(nav.title, systemImage: "puzzlepiece.extension")
                        }
                    }
                    
                    NavigationLink(value: "ajustes") {
                        Label("Ajustes", systemImage: "gearshape")
                    }
                }
            } detail: {
                let pluginNavViews = PluginRegistry.shared.getPluginMainNavigationViews()
                
                NavigationStack {
                    switch selectedDetailView {
                    case "habitos":
                        HabitListView(storageProvider: storageProvider)
                    case "estadisticas":
                        StatisticsView()
                    case "ajustes":
                        SettingsView()
                    default:
                        // Buscar si es una vista de plugin
                        if let pluginNav = pluginNavViews.first(where: { $0.id == selectedDetailView }) {
                            pluginNav.view
                        } else {
                            Text("Seleccione una opción")
                        }
                    }
                }
            }            .environmentObject(appConfig)

            #endif

        }
    }
}

