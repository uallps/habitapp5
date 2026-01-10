import Foundation
import SwiftUI
import Combine

/// Protocolo que define capacidades de un plugin de filtrado de hábitos
protocol HabitFilterProvider: FeaturePlugin {
    /// Vista de filtros que provee el plugin
    /// - Parameter categories: categorías disponibles en la app
    @MainActor func filterView(categories: [CategoryModel]) async -> AnyView

    /// Aplica el filtro a la lista de hábitos
    @MainActor func applyFilter(to habits: [Habito]) async -> [Habito]

    /// Publisher que emite cuando cambia el estado del filtro
    var filterDidChange: AnyPublisher<Void, Never> { get }
}