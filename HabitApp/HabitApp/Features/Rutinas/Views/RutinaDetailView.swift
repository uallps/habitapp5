//
//  RutinaDetailView.swift
//  HabitApp
//
//  Vista de detalle/edición de una rutina
//
import SwiftUI

struct RutinaDetailView: View {
    private enum Layout {
        static let constrainedWidth: CGFloat = 560
    }

    @ViewBuilder
    private func macConstrainedRow<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        #if os(macOS)
        HStack(spacing: 0) {
            content()
                .frame(maxWidth: Layout.constrainedWidth, alignment: .leading)
            Spacer(minLength: 0)
        }
        #else
        content()
        #endif
    }

    @Binding var rutina: Rutina
    let habitListViewModel: HabitListViewModel
    let rutinaViewModel: RutinaViewModel
    let onSave: () -> Void
    
    @State private var habitosDisponibles: [Habito] = []
    @State private var habitosEnRutina: [Habito] = []
    @State private var showingHabitSelector = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section(header: AppSectionHeader(title: "Información")) {
                macConstrainedRow {
                    TextField("Nombre", text: $rutina.nombre)
                        #if os(iOS)
                        .textInputAutocapitalization(.words)
                        #endif
                        .onChange(of: rutina.nombre) { _ in
                            Task { await rutinaViewModel.updateRutina(rutina) }
                        }
                }

                macConstrainedRow {
                    TextField("Descripción (opcional)", text: Binding(
                        get: { rutina.descripcion ?? "" },
                        set: { newValue in
                            rutina.descripcion = newValue.isEmpty ? nil : newValue
                            Task { await rutinaViewModel.updateRutina(rutina) }
                        }
                    ))
                    #if os(iOS)
                    .textInputAutocapitalization(.sentences)
                    #endif
                }
            }
            
            Section(header: AppSectionHeader(title: "Apariencia")) {
                ColorPicker("Color", selection: Binding(
                    get: { colorFromHex(rutina.color) },
                    set: { newColor in
                        rutina.color = newColor.toHex()
                        Task { await rutinaViewModel.updateRutina(rutina) }
                    }
                ))
            }
            
            Section {
                Toggle("Rutina activa", isOn: $rutina.isActiva)
                    .onChange(of: rutina.isActiva) { _ in
                        Task { await rutinaViewModel.updateRutina(rutina) }
                    }
            }
            
            Section(header: AppSectionHeader(title: "Hábitos en esta rutina")) {
                if habitosEnRutina.isEmpty {
                    Text("No hay hábitos en esta rutina")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else {
                    ForEach(habitosEnRutina) { habito in
                        macConstrainedRow {
                            HStack(spacing: 12) {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                                Text(habito.title)
                                    .foregroundStyle(.primary)
                                Spacer(minLength: 12)
                                Button(role: .destructive) {
                                    removeHabitoFromRutina(habito)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.trailing, 12)
                            .contentShape(Rectangle())
                        }
                    }
                }
                
                Button {
                    Task { @MainActor in
                        await loadHabitos()
                        showingHabitSelector = true
                    }
                } label: {
                    Label("Añadir hábito", systemImage: "plus.circle")
                }
            }
        }
        .appFormContainer()
        .navigationTitle("Editar Rutina")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        // ...existing code...
        .sheet(isPresented: $showingHabitSelector) {
            NavigationStack {
                HabitSelectorView(
                    habitosDisponibles: habitosDisponibles.filter { habito in
                        !rutina.habitoIds.contains(habito.id)
                    },
                    onSelect: { habito in
                        addHabitoToRutina(habito)
                        showingHabitSelector = false
                    }
                )
            }
        }
        .task {
            await loadHabitos()
        }
    }
    
    @MainActor
    private func loadHabitos() async {
        await habitListViewModel.loadHabits()
        let allHabitos = habitListViewModel.habitos
        habitosEnRutina = allHabitos.filter { rutina.habitoIds.contains($0.id) }
        habitosDisponibles = allHabitos
    }
    
    private func addHabitoToRutina(_ habito: Habito) {
        if !rutina.habitoIds.contains(habito.id) {
            rutina.habitoIds.append(habito.id)
            Task { @MainActor in
                await rutinaViewModel.updateRutina(rutina)
                await loadHabitos()
                PluginRegistry.shared.pluginStateDidChange()
            }
        }
    }
    
    private func removeHabitoFromRutina(_ habito: Habito) {
        rutina.habitoIds.removeAll { $0 == habito.id }
        habitosEnRutina.removeAll { $0.id == habito.id }
        Task { @MainActor in
            await rutinaViewModel.updateRutina(rutina)
        }
    }
    
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
        return Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

// MARK: - Editor para nueva rutina

struct RutinaEditorView: View {
    private enum Layout {
        static let constrainedWidth: CGFloat = 560
    }

    @ViewBuilder
    private func macConstrainedRow<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        #if os(macOS)
        HStack(spacing: 0) {
            content()
                .frame(maxWidth: Layout.constrainedWidth, alignment: .leading)
            Spacer(minLength: 0)
        }
        #else
        content()
        #endif
    }

    let habitStorageProvider: RutinaViewModel
    let onSave: (Rutina) -> Void
    
    @State private var nombre = ""
    @State private var descripcion = ""
    @State private var color = Color.blue
    @State private var habitosSeleccionados: [UUID] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section(header: AppSectionHeader(title: "Información")) {
                macConstrainedRow {
                    TextField("Nombre", text: $nombre)
                        #if os(iOS)
                        .textInputAutocapitalization(.words)
                        #endif
                }

                macConstrainedRow {
                    TextField("Descripción (opcional)", text: $descripcion)
                        #if os(iOS)
                        .textInputAutocapitalization(.sentences)
                        #endif
                }
            }
            
            Section(header: AppSectionHeader(title: "Apariencia")) {

                ColorPicker("Color", selection: $color)
            }
        }
        .appFormContainer()
        .navigationTitle("Nueva Rutina")        
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif        
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Crear") {
                    let nuevaRutina = Rutina(
                        nombre: nombre,
                        descripcion: descripcion.isEmpty ? nil : descripcion,
                        habitoIds: habitosSeleccionados,
                        color: color.toHex()
                    )
                    onSave(nuevaRutina)
                }
                .disabled(nombre.isEmpty)
            }
        }
    }
}

// MARK: - Selector de hábitos

struct HabitSelectorView: View {
    let habitosDisponibles: [Habito]
    let onSelect: (Habito) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                if habitosDisponibles.isEmpty {
                    Text("No hay hábitos disponibles")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(habitosDisponibles, id: \.id) { habito in
                        Button {
                            onSelect(habito)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                                Text(habito.title)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .appCard(padding: 12)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .appScrollBackground()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Seleccionar Hábito")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cerrar") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Extensión de Color

extension Color {
    func toHex() -> String {
        #if os(iOS)
        let components = UIColor(self).cgColor.components ?? [0, 0, 0]
        #elseif os(macOS)
        let components = NSColor(self).cgColor.components ?? [0, 0, 0]
        #endif
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
