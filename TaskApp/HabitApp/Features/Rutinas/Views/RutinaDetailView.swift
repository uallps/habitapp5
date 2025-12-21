//
//  RutinaDetailView.swift
//  HabitApp
//
//  Vista de detalle/edición de una rutina
//
internal import SwiftUI

struct RutinaDetailView: View {
    @Binding var rutina: Rutina
    let habitListViewModel: HabitListViewModel
    let onSave: () -> Void
    
    @State private var habitosDisponibles: [Habito] = []
    @State private var habitosEnRutina: [Habito] = []
    @State private var showingHabitSelector = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section("Información") {
                TextField("Nombre", text: $rutina.nombre)
                TextField("Descripción (opcional)", text: Binding(
                    get: { rutina.descripcion ?? "" },
                    set: { rutina.descripcion = $0.isEmpty ? nil : $0 }
                ))
            }
            
            Section("Apariencia") {
                ColorPicker("Color", selection: Binding(
                    get: { colorFromHex(rutina.color) },
                    set: { rutina.color = $0.toHex() }
                ))
            }
            
            Section {
                Toggle("Rutina activa", isOn: $rutina.isActiva)
            }
            
            Section("Hábitos en esta rutina") {
                if habitosEnRutina.isEmpty {
                    Text("No hay hábitos en esta rutina")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    ForEach(habitosEnRutina) { habito in
                        HStack {
                            Image(systemName: "circle")
                            Text(habito.title)
                            Spacer()
                            Button(role: .destructive) {
                                removeHabitoFromRutina(habito)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
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
        .navigationTitle("Editar Rutina")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    onSave()
                    dismiss()
                }
                .disabled(rutina.nombre.isEmpty)
            }
        }
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
        print("[DEBUG] Habitos cargados en RutinaDetailView: \(allHabitos.map { $0.title })")
        habitosEnRutina = allHabitos.filter { rutina.habitoIds.contains($0.id) }
        habitosDisponibles = allHabitos
        print("[DEBUG] Habitos en rutina: \(habitosEnRutina.map { $0.title })")
        print("[DEBUG] Habitos disponibles para añadir: \(habitosDisponibles.filter { !rutina.habitoIds.contains($0.id) }.map { $0.title })")
    }
    
    private func addHabitoToRutina(_ habito: Habito) {
        if !rutina.habitoIds.contains(habito.id) {
            rutina.habitoIds.append(habito.id)
            Task { @MainActor in
                await loadHabitos()
            }
        }
    }
    
    private func removeHabitoFromRutina(_ habito: Habito) {
        rutina.habitoIds.removeAll { $0 == habito.id }
        habitosEnRutina.removeAll { $0.id == habito.id }
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
    let habitStorageProvider: RutinaViewModel
    let onSave: (Rutina) -> Void
    
    @State private var nombre = ""
    @State private var descripcion = ""
    @State private var color = Color.blue
    @State private var habitosSeleccionados: [UUID] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section("Información") {
                TextField("Nombre", text: $nombre)
                TextField("Descripción (opcional)", text: $descripcion)
            }
            
            Section("Apariencia") {

                ColorPicker("Color", selection: $color)
            }
        }
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
        print("[DEBUG] HabitSelectorView: habitosDisponibles count = \(habitosDisponibles.count), ids = \(habitosDisponibles.map { $0.id })")
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if habitosDisponibles.isEmpty {
                    Text("No hay hábitos disponibles")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(habitosDisponibles, id: \.id) { habito in
                        Button {
                            onSelect(habito)
                        } label: {
                            HStack {
                                Image(systemName: "circle")
                                Text(habito.title)
                                Spacer()
                            }
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                    }
                }
            }
        }
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
