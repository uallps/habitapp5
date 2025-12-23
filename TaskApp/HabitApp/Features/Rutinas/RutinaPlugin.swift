//
//  RutinaPlugin.swift
//  HabitApp
//
//  Plugin completamente desacoplado para gestión de rutinas
//
import Foundation
internal import SwiftUI
import SwiftData

final class RutinaPlugin: ViewPlugin, DataPlugin {
    
    // MARK: - Propiedades de FeaturePlugin
    
    let identifier = "com.habitapp.rutinas"
    let name = "Rutinas"
    
    var models: [any PersistentModel.Type] {
        return [Rutina.self]
    }
    
    // El plugin gestiona su propio estado de habilitación
    @AppStorage("plugin.rutinas.enabled")
    private var pluginEnabled: Bool = true
    
    var isEnabled: Bool {
        return pluginEnabled
    }
    
    // MARK: - Propiedades Privadas
    
    private let config: AppConfig
    private var viewModelCache: [StorageType: RutinaViewModel] = [:]

    @MainActor
    private var viewModel: RutinaViewModel {
        if let cached = viewModelCache[config.storageType] {
            return cached
        }

        let rutinaStorage: RutinaStorageProvider = (config.storageType == .swiftData)
            ? SwiftDataRutinaStorageProvider.shared
            : JSONRutinaStorageProvider.shared

        let vm = RutinaViewModel(
            storageProvider: rutinaStorage,
            habitStorageProvider: config.storageProvider
        )
        viewModelCache[config.storageType] = vm
        return vm
    }
    
    // MARK: - Inicialización
    
    required init(config: AppConfig) {
        self.config = config
        print("RutinaPlugin inicializado - Enabled: \(isEnabled)")
        Task { @MainActor in
            await self.viewModel.loadRutinas()
        }
    }
    
    // MARK: - Implementación de ViewPlugin
    
    func habitRowView(for habito: Habito) -> some View {
        HStack(spacing: 4) {
            let rutinasCount = viewModel.getRutinasConHabito(habitoId: habito.id).count
            if rutinasCount > 0 {
                Image(systemName: "list.bullet.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.purple)
                Text("\(rutinasCount)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .task {
            await self.viewModel.loadRutinas()
        }
    }
    
    func habitDetailView(for habito: Binding<Habito>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            let rutinas = viewModel.getRutinasConHabito(habitoId: habito.wrappedValue.id)
            
            if !rutinas.isEmpty {
                Text("Rutinas")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(rutinas) { rutina in
                        HStack {
                            Circle()
                                .fill(self.colorFromHex(rutina.color))
                                .frame(width: 8, height: 8)
                            Text(rutina.nombre)
                                .font(.subheadline)
                            Spacer()
                            if !rutina.isActiva {
                                Text("Inactiva")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    func settingsView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Toggle para habilitar/deshabilitar el plugin
            Toggle(isOn: Binding(
                get: { self.pluginEnabled },
                set: { newValue in
                    self.pluginEnabled = newValue
                    // Notificar al registry para actualizar la UI
                    PluginRegistry.shared.pluginStateDidChange()
                }
            )) {
                Label("Plugin de Rutinas", systemImage: "list.bullet.circle.fill")
                    .font(.headline)
            }
            
            Text("Agrupa múltiples hábitos en rutinas ejecutables")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            HStack {
                Text("Rutinas activas:")
                    .font(.caption)
                Spacer()
                Text("\(viewModel.rutinas.filter { $0.isActiva }.count)")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Total rutinas:")
                    .font(.caption)
                Spacer()
                Text("\(viewModel.rutinas.count)")
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
        .task {
            await self.viewModel.loadRutinas()
        }
    }
    
    func mainNavigationView() -> (title: String, view: AnyView)? {
        return ("Rutinas", AnyView(RutinaListView(config: config)))
    }
    
    // MARK: - Implementación de DataPlugin
    
    func willDeleteHabito(_ habito: Habito) async {
        print("[Rutinas] Hábito '\(habito.title)' será eliminado")
        let rutinas = viewModel.getRutinasConHabito(habitoId: habito.id)
        if !rutinas.isEmpty {
            print("[Rutinas] Este hábito está en \(rutinas.count) rutina(s)")
        }
    }
    
    func didDeleteHabito(habitoId: UUID) async {
        print("[Rutinas] Eliminando hábito \(habitoId) de todas las rutinas")
        await viewModel.removeHabitoFromRutinas(habitoId: habitoId)
    }
    
    func willUpdateHabito(_ habito: Habito) async {
        // No necesitamos hacer nada antes de actualizar
    }
    
    func didUpdateHabito(_ habito: Habito) async {
        // Las rutinas mantienen referencias por ID, no necesitan actualización
    }
    
    func didCreateHabito(_ habito: Habito) async {
        print("[Rutinas] Nuevo hábito '\(habito.title)' disponible para rutinas")
    }
    
    // MARK: - Métodos Auxiliares
    
    private func colorFromHex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 122, 255)
        }
        return Color(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
