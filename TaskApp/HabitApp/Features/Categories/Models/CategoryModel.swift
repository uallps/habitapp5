//
//  CategoryModel.swift
//  HabitApp
//
//  Created on 18/11/25.
//

import Foundation
internal import SwiftUI

/// Modelo de categoría para hábitos
struct CategoryModel: Identifiable, Codable, Hashable {
    /// ID estable para permitir persistencia. NO usar UUID() dinámico.
    let id: UUID
    let name: String
    let iconName: String
    let colorHex: String

    init(id: UUID, name: String, iconName: String, colorHex: String) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
    }

    /// Color representativo de la categoría
    var color: Color {
        Color(hex: colorHex) ?? .gray
    }
}

// MARK: - Categorías Predefinidas
extension CategoryModel {
    // UUIDs generados una sola vez y fijados manualmente para persistencia
    static let salud = CategoryModel(
        id: UUID(uuidString: "F4A3D38A-5C6B-4B0E-A6D6-4E2B2E3A0101")!,
        name: "Salud",
        iconName: "heart.fill",
        colorHex: "#FF6B6B"
    )

    static let estudio = CategoryModel(
        id: UUID(uuidString: "9E6F9B2C-2F55-4A6F-8E05-7B5A8E3A0102")!,
        name: "Estudio",
        iconName: "book.fill",
        colorHex: "#4ECDC4"
    )

    static let deporte = CategoryModel(
        id: UUID(uuidString: "1C2D3E4F-5A6B-7C8D-9E0F-A1B2C3D40103")!,
        name: "Deporte",
        iconName: "figure.run",
        colorHex: "#95E1D3"
    )

    static let trabajo = CategoryModel(
        id: UUID(uuidString: "22345678-9ABC-4DEF-8123-456789ABC104")!,
        name: "Trabajo",
        iconName: "briefcase.fill",
        colorHex: "#FFD93D"
    )

    static let creatividad = CategoryModel(
        id: UUID(uuidString: "32345678-9ABC-4DEF-8123-456789ABC105")!,
        name: "Creatividad",
        iconName: "paintbrush.fill",
        colorHex: "#A78BFA"
    )

    static let finanzas = CategoryModel(
        id: UUID(uuidString: "42345678-9ABC-4DEF-8123-456789ABC106")!,
        name: "Finanzas",
        iconName: "dollarsign.circle.fill",
        colorHex: "#34D399"
    )

    static let hogar = CategoryModel(
        id: UUID(uuidString: "52345678-9ABC-4DEF-8123-456789ABC107")!,
        name: "Hogar",
        iconName: "house.fill",
        colorHex: "#F87171"
    )

    static let social = CategoryModel(
        id: UUID(uuidString: "62345678-9ABC-4DEF-8123-456789ABC108")!,
        name: "Social",
        iconName: "person.2.fill",
        colorHex: "#60A5FA"
    )

    static let desarrollo_personal = CategoryModel(
        id: UUID(uuidString: "72345678-9ABC-4DEF-8123-456789ABC109")!,
        name: "Desarrollo Personal",
        iconName: "brain.head.profile",
        colorHex: "#FB923C"
    )

    static let otros = CategoryModel(
        id: UUID(uuidString: "82345678-9ABC-4DEF-8123-456789ABC110")!,
        name: "Otros",
        iconName: "star.fill",
        colorHex: "#94A3B8"
    )
    
    /// Lista de todas las categorías predefinidas
    static let allCategories: [CategoryModel] = [
        .salud,
        .estudio,
        .deporte,
        .trabajo,
        .creatividad,
        .finanzas,
        .hogar,
        .social,
        .desarrollo_personal,
        .otros
    ]
}

// MARK: - Color Extension para Hex
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
