import Foundation
import SwiftUI
import Combine

/// Protocolo que define capacidades de un plugin de filtrado de hábitos
protocol HabitFilterProvider: FeaturePlugin {
    /// Vista de filtros que provee el plugin
    /// - Parameter categories: categorías disponibles en la app
    func filterView(categories: [CategoryModel]) -> AnyView

    /// Aplica el filtro a la lista de hábitos
    func applyFilter(to habits: [Habito]) -> [Habito]

    /// Publisher que emite cuando cambia el estado del filtro
    var filterDidChange: AnyPublisher<Void, Never> { get }
}