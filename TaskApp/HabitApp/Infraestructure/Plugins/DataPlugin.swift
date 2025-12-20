//
//  DataPlugin.swift
//  HabitApp
//
import Foundation

/// Protocol para plugins que gestionan datos y necesitan ser notificados de eventos
protocol DataPlugin: FeaturePlugin {
    /// Se llama cuando se va a eliminar un Habito
    /// - Parameter habito: El hábito que será eliminado
    func willDeleteHabito(_ habito: Habito) async
    
    /// Se llama después de eliminar un Habito
    /// - Parameter habitoId: ID del hábito eliminado
    func didDeleteHabito(habitoId: UUID) async
    
    /// Se llama cuando se va a actualizar un Habito
    /// - Parameter habito: El hábito que será actualizado
    func willUpdateHabito(_ habito: Habito) async
    
    /// Se llama después de actualizar un Habito
    /// - Parameter habito: El hábito actualizado
    func didUpdateHabito(_ habito: Habito) async
    
    /// Se llama cuando se crea un nuevo Habito
    /// - Parameter habito: El hábito creado
    func didCreateHabito(_ habito: Habito) async
}