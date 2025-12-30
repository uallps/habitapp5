//
//  Task.swift
//  TaskApp
//
//  Created by Aula03 on 15/10/25.
//
import Foundation
import SwiftData

// Enum para representar días de la semana
// Coincide con Calendar.weekday: Domingo=1, Lunes=2, ..., Sábado=7
enum DiaSemana: Int, Codable, CaseIterable, Identifiable {
    case domingo = 1
    case lunes = 2
    case martes = 3
    case miercoles = 4
    case jueves = 5
    case viernes = 6
    case sabado = 7
    
    var id: Int { rawValue }
    
    var nombre: String {
        switch self {
        case .domingo: return "Domingo"
        case .lunes: return "Lunes"
        case .martes: return "Martes"
        case .miercoles: return "Miércoles"
        case .jueves: return "Jueves"
        case .viernes: return "Viernes"
        case .sabado: return "Sábado"
        }
    }
    
    var nombreCorto: String {
        switch self {
        case .domingo: return "D"
        case .lunes: return "L"
        case .martes: return "M"
        case .miercoles: return "X"
        case .jueves: return "J"
        case .viernes: return "V"
        case .sabado: return "S"
        }
    }
}

@Model
class Habito: Identifiable, Codable {
    private enum CodingKeys: CodingKey {
        case id, title, descripcion, prioridad, fechaInicio, fechaFin, fechaCompletitud, reminderDate, categoria, diasSemana
    }
    
    let id: UUID
    var title: String
    var descripcion: String?
    var prioridad: Prioridad?
    var fechaInicio: Date?
    var fechaFin: Date?
    
    // Sistema de frecuencia: días de la semana en que se debe realizar el hábito
    // Si está vacío, se considera que el hábito es "diario" (todos los días)
    var diasSemana: [Int] = [] // Guardamos rawValue de DiaSemana
    
    // Array de fechas en que el hábito se completó
    // Cada entrada representa una fecha específica completada (ej: 2025-01-13 para el lunes de esa semana)
    var fechaCompletitud: [Date] = []
    
    var reminderDate: Date?
    var categoria: UUID? // ID de la categoría seleccionada
    
    init(title: String, descripcion: String, prioridad: Prioridad? = nil, fechaInicio: Date? = nil, fechaFin: Date? = nil, diasSemana: [Int] = [], fechaCompletitud: [Date] = [], categoria: UUID? = nil) {
        self.id = UUID()
        self.title = title
        self.descripcion = descripcion
        self.prioridad = prioridad
        self.fechaInicio = fechaInicio
        self.fechaFin = fechaFin
        self.diasSemana = diasSemana
        self.fechaCompletitud = fechaCompletitud
        self.reminderDate = nil
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
        diasSemana = try container.decodeIfPresent([Int].self, forKey: .diasSemana) ?? []
        fechaCompletitud = try container.decodeIfPresent([Date].self, forKey: .fechaCompletitud) ?? []
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
        try container.encode(diasSemana, forKey: .diasSemana)
        try container.encode(fechaCompletitud, forKey: .fechaCompletitud)
        try container.encodeIfPresent(reminderDate, forKey: .reminderDate)
        try container.encodeIfPresent(categoria, forKey: .categoria)
    }
    
    // MARK: - Métodos auxiliares para frecuencia y completitud
    
    /// Obtiene los días de la semana configurados para este hábito
    var diasConfigurados: [DiaSemana] {
        return diasSemana.compactMap { DiaSemana(rawValue: $0) }
    }
    
    /// Verifica si el hábito debe realizarse en un día específico
    func debeRealizarse(en fecha: Date) -> Bool {
        // Si no hay días configurados, se considera diario
        if diasSemana.isEmpty {
            return true
        }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: fecha)
        return diasSemana.contains(weekday)
    }
    
    /// Verifica si el hábito está completado para una fecha específica
    func estaCompletado(en fecha: Date) -> Bool {
        let calendar = Calendar.current
        return fechaCompletitud.contains { completedDate in
            calendar.isDate(completedDate, inSameDayAs: fecha)
        }
    }
    
    /// Marca el hábito como completado para una fecha específica
    mutating func marcarCompletado(en fecha: Date) {
        let calendar = Calendar.current
        let fechaNormalizada = calendar.startOfDay(for: fecha)
        
        // Solo agregar si no está ya completado
        if !estaCompletado(en: fechaNormalizada) {
            fechaCompletitud.append(fechaNormalizada)
        }
    }
    
    /// Desmarca el hábito como completado para una fecha específica
    mutating func desmarcarCompletado(en fecha: Date) {
        let calendar = Calendar.current
        fechaCompletitud.removeAll { completedDate in
            calendar.isDate(completedDate, inSameDayAs: fecha)
        }
    }
    
    /// Alterna el estado de completitud para una fecha específica
    /// Esta función encapsula la lógica de negocio de marcar/desmarcar
    /// Debe ser llamada desde el ViewModel, no directamente desde la Vista
    mutating func toggleCompletitud(para fecha: Date = Date()) {
        if estaCompletado(en: fecha) {
            desmarcarCompletado(en: fecha)
        } else {
            marcarCompletado(en: fecha)
        }
    }
}

enum Prioridad: String, Codable {
    case low, medium, high
}

