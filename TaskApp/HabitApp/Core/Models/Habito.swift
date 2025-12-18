//
//  Task.swift
//  TaskApp
//
//  Created by Aula03 on 15/10/25.
//
import Foundation
import SwiftData

@Model
class Habito: Identifiable, Codable {
    private enum CodingKeys: CodingKey {
        case id, title, descripcion, prioridad, fechaInicio, fechaFin, completada, fechaCompletitud, reminderDate, categoria
    }
    
    let id: UUID
    var title: String
    var descripcion: String?
    var prioridad: Prioridad?
    var fechaInicio: Date?
    var fechaFin: Date?
    var completada: Bool = false
    var fechaCompletitud: [Date]?=[]
    var reminderDate: Date?
    var categoria: UUID? // ID de la categoría seleccionada
    //var icono: Image i dont fucking know man
    //var color: ¿pillar color de interfaz o hexadecimal hardcodeado xd?
    
    init(title: String, descripcion: String, prioridad: Prioridad? = nil, fechaInicio: Date? = nil, fechaFin: Date? = nil, completada: Bool = false, fechaCompletitud: [Date]? = nil, categoria: UUID? = nil) {
        self.id = UUID()
        self.title = title
        self.descripcion = descripcion
        self.prioridad = prioridad
        self.fechaInicio = fechaInicio
        self.fechaFin = fechaFin
        self.completada = completada
        self.fechaCompletitud = fechaCompletitud
        self.reminderDate = reminderDate
        self.categoria = categoria
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        descripcion = try container.decodeIfPresent(String.self, forKey: .descripcion)
        prioridad = try container.decodeIfPresent(Prioridad.self, forKey: .prioridad)
        fechaInicio = try container.decodeIfPresent(Date.self, forKey: .fechaInicio)
        fechaFin = try container.decodeIfPresent(Date.self, forKey: .fechaFin)
        completada = try container.decode(Bool.self, forKey: .completada)
        fechaCompletitud = try container.decodeIfPresent([Date].self, forKey: .fechaCompletitud)
        reminderDate = try container.decodeIfPresent(Date.self, forKey: .reminderDate)
        categoria = try container.decodeIfPresent(UUID.self, forKey: .categoria)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(descripcion, forKey: .descripcion)
        try container.encodeIfPresent(prioridad, forKey: .prioridad)
        try container.encodeIfPresent(fechaInicio, forKey: .fechaInicio)
        try container.encodeIfPresent(fechaFin, forKey: .fechaFin)
        try container.encode(completada, forKey: .completada)
        try container.encodeIfPresent(fechaCompletitud, forKey: .fechaCompletitud)
        try container.encodeIfPresent(reminderDate, forKey: .reminderDate)
        try container.encodeIfPresent(categoria, forKey: .categoria)
    }
}

enum Prioridad: String, Codable {
    case low, medium, high
}

enum TipoCompletitud: String, Codable {
    case completo, incompleto, enProgreso
}

enum Frecuencia: String, Codable{
    case diaria, semanal, mensual
}

enum Categoria: String, Codable{
    case salud, estudio, deporte
    //revisar que mas añadir, luego ver para que el usuario añada mas--¿feature?
}

struct Observaciones: Identifiable, Codable {
    let id: UUID
    var notas: String
    var idHabito: UUID  // reference to the Habito's ID
}

