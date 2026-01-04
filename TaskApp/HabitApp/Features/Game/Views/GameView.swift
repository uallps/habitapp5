//
//  GameView.swift
//  HabitApp
//
//  Vista principal del plugin de gamificación
//

import SwiftUI

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Encabezado temporal
                    headerSection
                    
                    // Contenido placeholder
                    placeholderContent
                }
                .padding()
            }
            .navigationTitle("Game")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Components
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Gamificación")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Convierte tus hábitos en un juego")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.purple.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var placeholderContent: some View {
        VStack(spacing: 16) {
            InfoCard(
                icon: "star.fill",
                title: "Puntos",
                description: "Gana puntos completando hábitos",
                color: .yellow
            )
            
            InfoCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Niveles",
                description: "Sube de nivel y desbloquea recompensas",
                color: .blue
            )
            
            InfoCard(
                icon: "trophy.fill",
                title: "Logros",
                description: "Desbloquea logros especiales",
                color: .orange
            )
        }
    }
}

// MARK: - Supporting Views

private struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundStyle(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    GameView()
}
