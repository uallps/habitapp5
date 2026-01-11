//
//  Task.swift
//  TaskApp
//
//  Created by Aula03 on 15/10/25.
//
import Foundation
import SwiftData

// Tipo de frecuencia del hábito
enum TipoFrecuencia: String, Codable, CaseIterable {
    case semanal = "Semanal"
    case mensual = "Mensual"
}

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
        case id, title, descripcion, prioridad, fechaInicio, fechaFin, fechaCompletitud, reminderDate, categoria, tipoFrecuencia, vecesPorPeriodo, diasSemana, diasMes
    }
    
    let id: UUID
    var title: String
    var descripcion: String?
    var prioridad: Prioridad?
    var fechaInicio: Date?
    var fechaFin: Date?
    
    // Sistema de frecuencia
    var tipoFrecuencia: TipoFrecuencia?
    
    // Número de veces que se debe completar por periodo (1-7 para semanal, 1-31 para mensual)
    var vecesPorPeriodo: Int?
    
    // Para frecuencia semanal: días de la semana (rawValue de DiaSemana)
    var diasSemana: [Int] = []
    
    // Para frecuencia mensual: días del mes (1-31)
    var diasMes: [Int] = []
    
    // Array de fechas en que el hábito se completó
    var fechaCompletitud: [Date] = []
    
    var reminderDate: Date?
    var categoria: UUID? // ID de la categoría seleccionada
    
    init(title: String, descripcion: String? = nil, prioridad: Prioridad? = nil, fechaInicio: Date? = nil, fechaFin: Date? = nil, tipoFrecuencia: TipoFrecuencia? = .semanal, vecesPorPeriodo: Int? = 1, diasSemana: [Int] = [], diasMes: [Int] = [], fechaCompletitud: [Date] = [], categoria: UUID? = nil) {
        self.id = UUID()
        self.title = title
        if let descripcion, !descripcion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.descripcion = descripcion
        } else {
            self.descripcion = nil
        }
        self.prioridad = prioridad
        self.fechaInicio = fechaInicio
        self.fechaFin = fechaFin
        self.tipoFrecuencia = tipoFrecuencia
        self.vecesPorPeriodo = vecesPorPeriodo
        self.diasSemana = diasSemana
        self.diasMes = diasMes
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
        tipoFrecuencia = try container.decodeIfPresent(TipoFrecuencia.self, forKey: .tipoFrecuencia)
        vecesPorPeriodo = try container.decodeIfPresent(Int.self, forKey: .vecesPorPeriodo)
        diasSemana = try container.decodeIfPresent([Int].self, forKey: .diasSemana) ?? []
        diasMes = try container.decodeIfPresent([Int].self, forKey: .diasMes) ?? []
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
        try container.encode(tipoFrecuencia, forKey: .tipoFrecuencia)
        try container.encode(vecesPorPeriodo, forKey: .vecesPorPeriodo)
        try container.encode(diasSemana, forKey: .diasSemana)
        try container.encode(diasMes, forKey: .diasMes)
        try container.encode(fechaCompletitud, forKey: .fechaCompletitud)
        try container.encodeIfPresent(reminderDate, forKey: .reminderDate)
        try container.encodeIfPresent(categoria, forKey: .categoria)
    }
    
    // MARK: - Métodos auxiliares para frecuencia y completitud
    
    /// Obtiene el tipo de frecuencia con valor por defecto
    var tipoFrecuenciaActual: TipoFrecuencia {
        return tipoFrecuencia ?? .semanal
    }
    
    /// Obtiene las veces por periodo con valor por defecto
    var vecesPorPeriodoActual: Int {
        return vecesPorPeriodo ?? 1
    }
    
    /// Obtiene los días de la semana configurados para este hábito
    var diasConfigurados: [DiaSemana] {
        return diasSemana.compactMap { DiaSemana(rawValue: $0) }
    }
    
    /// Verifica si el hábito debe realizarse en un día específico
    func debeRealizarse(en fecha: Date) -> Bool {
        let calendar = Calendar.current
        
        switch tipoFrecuenciaActual {
        case .semanal:
            // Si no hay días configurados, se considera que no está configurado
            if diasSemana.isEmpty {
                return false
            }
            let weekday = calendar.component(.weekday, from: fecha)
            return diasSemana.contains(weekday)
            
        case .mensual:
            // Si no hay días configurados, se considera que no está configurado
            if diasMes.isEmpty {
                return false
            }
            let day = calendar.component(.day, from: fecha)
            
            // Verificar si el día está en la lista de días configurados
            if diasMes.contains(day) {
                return true
            }
            
            // Manejar caso especial: si hay días mayores al máximo del mes actual
            // (ej: día 31 en febrero), considerar el último día del mes
            let maxDayInMonth = calendar.range(of: .day, in: .month, for: fecha)?.count ?? 31
            let diasMayoresAlMes = diasMes.filter { $0 > maxDayInMonth }
            
            if !diasMayoresAlMes.isEmpty && day == maxDayInMonth {
                return true
            }
            
            return false
        }
    }
    
    /// Verifica si el hábito está completado para una fecha específica
    func estaCompletado(en fecha: Date) -> Bool {
        let calendar = Calendar.current
        return fechaCompletitud.contains { completedDate in
            calendar.isDate(completedDate, inSameDayAs: fecha)
        }
    }
    
    /// Marca el hábito como completado para una fecha específica
    func marcarCompletado(en fecha: Date) {
        let calendar = Calendar.current
        let fechaNormalizada = calendar.startOfDay(for: fecha)
        
        // Solo agregar si no está ya completado
        if !estaCompletado(en: fechaNormalizada) {
            fechaCompletitud.append(fechaNormalizada)
        }
    }
    
    /// Desmarca el hábito como completado para una fecha específica
    func desmarcarCompletado(en fecha: Date) {
        let calendar = Calendar.current
        fechaCompletitud.removeAll { completedDate in
            calendar.isDate(completedDate, inSameDayAs: fecha)
        }
    }
    
    /// Alterna el estado de completitud para una fecha específica
    /// Esta función encapsula la lógica de negocio de marcar/desmarcar
    /// Debe ser llamada desde el ViewModel, no directamente desde la Vista
    func toggleCompletitud(para fecha: Date = Date()) {
        if estaCompletado(en: fecha) {
            desmarcarCompletado(en: fecha)
        } else {
            marcarCompletado(en: fecha)
        }
    }
    
    // MARK: - Validación de frecuencia mensual
    
    /// Obtiene el número máximo de días válidos para un mes específico
    static func diasEnMes(fecha: Date = Date()) -> Int {
        let calendar = Calendar.current
        return calendar.range(of: .day, in: .month, for: fecha)?.count ?? 31
    }
    
    /// Valida si un día del mes es válido para el mes actual
    func esValidoDiaMes(_ dia: Int, para fecha: Date = Date()) -> Bool {
        return dia >= 1 && dia <= Habito.diasEnMes(fecha: fecha)
    }
    
    /// Obtiene advertencia si hay días configurados que exceden el mes actual
    func advertenciaDiasMes(para fecha: Date = Date()) -> String? {
        guard tipoFrecuenciaActual == .mensual else { return nil }
        
        let maxDias = Habito.diasEnMes(fecha: fecha)
        let diasInvalidos = diasMes.filter { $0 > maxDias }
        
        if !diasInvalidos.isEmpty {
            let calendar = Calendar.current
            let monthName = calendar.monthSymbols[calendar.component(.month, from: fecha) - 1]
            return "\(monthName) solo tiene \(maxDias) días. Los días \(diasInvalidos.map { String($0) }.joined(separator: ", ")) se ejecutarán el último día del mes."
        }
        
        return nil
    }
    
    /// Verifica si el hábito está activo en una fecha específica
    /// Un hábito es activo si:
    /// - No tiene fecha fin, O
    /// - La fecha fin es >= fecha proporcionada (el mismo día cuenta como activo)
    func isActive(at date: Date = Date()) -> Bool {
        guard let fechaFin = fechaFin else { return true }
        let calendar = Calendar.current
        let dateStart = calendar.startOfDay(for: date)
        let finStart = calendar.startOfDay(for: fechaFin)
        return finStart >= dateStart
    }
}

enum Prioridad: String, Codable {
    case low, medium, high
}

