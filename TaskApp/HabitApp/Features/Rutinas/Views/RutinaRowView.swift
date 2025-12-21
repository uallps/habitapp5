//
//  RutinaRowView.swift
//  HabitApp
//
//  Vista de fila para una rutina
//
internal import SwiftUI

struct RutinaRowView: View {
    let rutina: Rutina
    let habitCount: Int
    let onToggleActiva: () -> Void
    let onEjecutar: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Cuadro de color de la rutina
            RoundedRectangle(cornerRadius: 8)
                .fill(colorFromHex(rutina.color))
                .frame(width: 8, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(rutina.nombre)
                    .font(.headline)
                    .strikethrough(!rutina.isActiva)
                
                HStack(spacing: 8) {
                    Label("\(habitCount)", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !rutina.isActiva {
                        Text("Desactivada")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                if let descripcion = rutina.descripcion, !descripcion.isEmpty {
                    Text(descripcion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Botón ejecutar
            if rutina.isActiva {
                Button(action: onEjecutar) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    
    private func colorFromHex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 122, 255) // Default blue
        }
        return Color(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
