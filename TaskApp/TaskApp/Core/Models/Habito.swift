//
//  Task.swift
//  TaskApp
//
//  Created by Aula03 on 15/10/25.
//

import Foundation

struct Habito: Identifiable, Codable {
    let id = UUID()
    var title: String
    var descripcion: String
    var prioridad: Int?
    var fechaInicio: Date?
    var fechaFin: Date?
    //var icono: Image i dont fucking know man
    //var color: ¿pillar color de interfaz o hexadecimal hardcodeado xd?  
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
    let id = UUID()
    var notas: String
    var idHabito: UUID  // reference to the Habito's ID
}

