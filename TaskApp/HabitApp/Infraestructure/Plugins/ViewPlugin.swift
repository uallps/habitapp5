//
//  ViewPlugin.swift
//  HabitApp
//
import Foundation
import SwiftUI

/// Protocol para plugins que proveen vistas en diferentes puntos de la aplicación
protocol ViewPlugin: FeaturePlugin {
    /// Tipo asociado para la vista de fila que provee el plugin
    associatedtype HabitRowContent: View
    
    /// Tipo asociado para la vista de detalle que provee el plugin
    associatedtype HabitDetailContent: View
    
    /// Tipo asociado para la vista de configuración que provee el plugin
    associatedtype SettingsContent: View
    
    /// Provee una vista personalizada para mostrar en la fila de hábito
    /// - Parameter habito: El hábito para el cual crear la vista
    /// - Returns: Una vista usando ViewBuilder
    @ViewBuilder
    func habitRowView(for habito: Habito) -> HabitRowContent
    
    /// Provee una vista personalizada para mostrar en el detalle de hábito
    /// - Parameter habito: Binding al hábito para el cual crear la vista
    /// - Returns: Una vista usando ViewBuilder
    @ViewBuilder
    func habitDetailView(for habito: Binding<Habito>) -> HabitDetailContent
    
    /// Provee una vista de configuración para el plugin
    /// - Returns: Una vista de configuración usando ViewBuilder
    @ViewBuilder
    func settingsView() -> SettingsContent
    
    /// Provee una vista principal de navegación para el plugin (si tiene una)
    /// - Returns: Tupla con el título y vista principal, o nil si no tiene
    func mainNavigationView() -> (title: String, view: AnyView)?
}

// Implementación por defecto para mainNavigationView (opcional) (Se configura como extension para no forzar su implementación, es decir, si un plugin no tiene una vista principal en si no lo tendrá que usar)
extension ViewPlugin {
    func mainNavigationView() -> (title: String, view: AnyView)? {
        return nil
    }
}
