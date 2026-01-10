//
//  Rutina.swift
//  HabitApp
//
//  Modelo para rutinas que agrupan múltiples hábitos
//
import Foundation
import SwiftData

@Model
final class Rutina: Identifiable, Codable {
    private enum CodingKeys: CodingKey {
        case id, nombre, descripcion, habitoIds, color, isActiva, fechaCreacion, ordenEjecucion
    }
    
    var id: UUID
    var nombre: String
    var descripcion: String?
    var habitoIds: [UUID]  // IDs de los hábitos que componen la rutina
    var color: String  // Representación hexadecimal del color
    var isActiva: Bool
    var fechaCreacion: Date
    var ordenEjecucion: Int  // Para ordenar rutinas en la lista
    
    init(
        nombre: String,
        descripcion: String? = nil,
        habitoIds: [UUID] = [],
        color: String = "#007AFF",
        isActiva: Bool = true,
        ordenEjecucion: Int = 0
    ) {
        self.id = UUID()
        self.nombre = nombre
        self.descripcion = descripcion
        self.habitoIds = habitoIds
        self.color = color
        self.isActiva = isActiva
        self.fechaCreacion = Date()
        self.ordenEjecucion = ordenEjecucion
    }
    
    // MARK: - Codable
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        nombre = try container.decode(String.self, forKey: .nombre)
        descripcion = try container.decodeIfPresent(String.self, forKey: .descripcion)
        habitoIds = try container.decode([UUID].self, forKey: .habitoIds)
        color = try container.decode(String.self, forKey: .color)
        isActiva = try container.decode(Bool.self, forKey: .isActiva)
        fechaCreacion = try container.decode(Date.self, forKey: .fechaCreacion)
        ordenEjecucion = try container.decode(Int.self, forKey: .ordenEjecucion)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(nombre, forKey: .nombre)
        try container.encodeIfPresent(descripcion, forKey: .descripcion)
        try container.encode(habitoIds, forKey: .habitoIds)

        try container.encode(color, forKey: .color)
        try container.encode(isActiva, forKey: .isActiva)
        try container.encode(fechaCreacion, forKey: .fechaCreacion)
        try container.encode(ordenEjecucion, forKey: .ordenEjecucion)
    }
}
