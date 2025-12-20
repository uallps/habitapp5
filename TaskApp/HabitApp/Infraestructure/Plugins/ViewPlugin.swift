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
}