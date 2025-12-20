//
//  PluginRegistry.swift
//  HabitApp
//
import Foundation
import SwiftData
import SwiftUI

/// Registro centralizado de plugins de características
class PluginRegistry {
    /// Instancia compartida del registro (Singleton)
    static let shared = PluginRegistry()
    
    /// Array de tipos de plugins registrados
    private(set) var registeredPlugins: [FeaturePlugin.Type] = []
    
    /// Instancias de plugins creadas
    private var pluginInstances: [FeaturePlugin] = []
    
    /// Inicializador privado para el patrón Singleton
    private init() {}
    
    /// Registra un nuevo tipo de plugin
    /// - Parameter pluginType: Tipo del plugin a registrar
    func register(_ pluginType: FeaturePlugin.Type) {
        guard !registeredPlugins.contains(where: { $0 == pluginType }) else {
            print("⚠️ Plugin \(pluginType) ya está registrado")
            return
        }
        
        registeredPlugins.append(pluginType)
        print("✅ Plugin registrado: \(pluginType)")
    }
    
    /// Crea instancias de todos los plugins registrados
    /// - Parameter config: Configuración de la aplicación
    /// - Returns: Array de instancias de plugins
    func createPluginInstances(config: AppConfig) -> [FeaturePlugin] {
        pluginInstances = registeredPlugins.map { pluginType in
            pluginType.init(config: config)
        }
        return pluginInstances
    }
    
    /// Obtiene todos los modelos de los plugins habilitados
    /// - Parameter plugins: Array de instancias de plugins
    /// - Returns: Array de tipos de modelos persistentes
    func getEnabledModels(from plugins: [FeaturePlugin]) -> [any PersistentModel.Type] {
        return plugins.flatMap { plugin in
            plugin.isEnabled ? plugin.models : []
        }
    }
    
    // MARK: - Notificaciones de eventos de Habito
    
    /// Notifica a todos los DataPlugins que un hábito va a ser eliminado
    /// - Parameter habito: El hábito que será eliminado
    func notifyHabitoWillBeDeleted(_ habito: Habito) async {
        let dataPlugins = pluginInstances.compactMap { $0 as? DataPlugin }
        
        await withTaskGroup(of: Void.self) { group in
            for plugin in dataPlugins where plugin.isEnabled {
                group.addTask {
                    await plugin.willDeleteHabito(habito)
                }
            }
        }
    }
    
    /// Notifica a todos los DataPlugins que un hábito ha sido eliminado
    /// - Parameter habitoId: ID del hábito eliminado
    func notifyHabitoDidDelete(habitoId: UUID) async {
        let dataPlugins = pluginInstances.compactMap { $0 as? DataPlugin }
        
        await withTaskGroup(of: Void.self) { group in
            for plugin in dataPlugins where plugin.isEnabled {
                group.addTask {
                    await plugin.didDeleteHabito(habitoId: habitoId)
                }
            }
        }
    }
    
    /// Notifica a todos los DataPlugins que un hábito va a ser actualizado
    /// - Parameter habito: El hábito que será actualizado
    func notifyHabitoWillBeUpdated(_ habito: Habito) async {
        let dataPlugins = pluginInstances.compactMap { $0 as? DataPlugin }
        
        await withTaskGroup(of: Void.self) { group in
            for plugin in dataPlugins where plugin.isEnabled {
                group.addTask {
                    await plugin.willUpdateHabito(habito)
                }
            }
        }
    }
    
    /// Notifica a todos los DataPlugins que un hábito ha sido actualizado
    /// - Parameter habito: El hábito actualizado
    func notifyHabitoDidUpdate(_ habito: Habito) async {
        let dataPlugins = pluginInstances.compactMap { $0 as? DataPlugin }
        
        await withTaskGroup(of: Void.self) { group in
            for plugin in dataPlugins where plugin.isEnabled {
                group.addTask {
                    await plugin.didUpdateHabito(habito)
                }
            }
        }
    }
    
    /// Notifica a todos los DataPlugins que un hábito ha sido creado
    /// - Parameter habito: El hábito creado
    func notifyHabitoDidCreate(_ habito: Habito) async {
        let dataPlugins = pluginInstances.compactMap { $0 as? DataPlugin }
        
        await withTaskGroup(of: Void.self) { group in
            for plugin in dataPlugins where plugin.isEnabled {
                group.addTask {
                    await plugin.didCreateHabito(habito)
                }
            }
        }
    }
    
    // MARK: - Vistas de plugins
    
    /// Limpia todos los plugins registrados (útil para testing)
    func clearAll() {
        registeredPlugins.removeAll()
        pluginInstances.removeAll()
        print("🗑️ Todos los plugins han sido eliminados del registro")
    }
    
    /// Obtiene el número de plugins registrados
    var count: Int {
        return registeredPlugins.count
    }
    
    /// Obtiene todas las vistas de fila de plugins para un hábito específico
    /// - Parameter habito: El hábito para el cual obtener las vistas
    /// - Returns: Array de vistas proporcionadas por los plugins habilitados
    func getHabitoRowViews(for habito: Habito) -> [AnyView] {
        return pluginInstances
            .compactMap { $0 as? ViewPlugin }
            .filter { $0.isEnabled }
            .map { AnyView($0.habitRowView(for: habito)) }
    }
    
    /// Obtiene todas las vistas de detalle de plugins para un hábito específico
    /// - Parameter habito: Binding al hábito para el cual obtener las vistas
    /// - Returns: Array de vistas proporcionadas por los plugins habilitados
    func getHabitoDetailViews(for habito: Binding<Habito>) -> [AnyView] {
        return pluginInstances
            .compactMap { $0 as? ViewPlugin }
            .filter { $0.isEnabled }
            .map { AnyView($0.habitDetailView(for: habito)) }
    }
    
    /// Obtiene todas las vistas de configuración de los plugins
    /// - Returns: Array de vistas de configuración proporcionadas por los plugins
    func getPluginSettingsViews() -> [AnyView] {
        return pluginInstances
            .compactMap { $0 as? ViewPlugin }
            .filter { $0.isEnabled }
            .map { AnyView($0.settingsView()) }
    }
    
    /// Obtiene información de todos los plugins registrados
    /// - Returns: Array de tuplas con información de cada plugin
    func getPluginInfo() -> [(name: String, version: String, identifier: String, enabled: Bool)] {
        return pluginInstances.map { plugin in
            (name: plugin.name, 
             version: plugin.version, 
             identifier: plugin.identifier, 
             enabled: plugin.isEnabled)
        }
    }
}