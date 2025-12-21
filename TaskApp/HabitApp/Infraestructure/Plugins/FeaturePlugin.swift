//
//  FeaturePlugin.swift
//  HabitApp
//
import Foundation
import SwiftData

/// Protocol que deben implementar todos los plugins de características
protocol FeaturePlugin: AnyObject {
    /// Identificador único del plugin
    var identifier: String { get }
    
    /// Nombre descriptivo del plugin
    var name: String { get }
    
    /// Modelos de datos que el plugin necesita persistir
    var models: [any PersistentModel.Type] { get }
    
    /// Indica si el plugin está habilitado
    var isEnabled: Bool { get }
    
    /// Inicializador requerido para crear instancias del plugin
    /// - Parameter config: Configuración de la aplicación
    init(config: AppConfig)
}