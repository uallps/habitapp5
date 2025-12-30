internal import SwiftUI

struct HabitDetailView: View {
    @Binding var habit: Habito
    var onSave: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var AppConfig: AppConfig
    @State private var showCategorySelection = false
    @State private var selectedCategoryModel: CategoryModel?
    @State private var pendingSaveTask: Task<Void, Never>?

    private func scheduleSave() {
        pendingSaveTask?.cancel()
        pendingSaveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            onSave?()
        }
    }
    
    var body: some View {
        HStack() {
            Spacer()
            Form {
                TextField("Título del hábito", text: $habit.title)
                
                // Sección de Categoría
                Section(header: Text("Categoría")) {
                    Button(action: {
                        showCategorySelection = true
                    }) {
                        HStack {
                            if let categoryModel = selectedCategoryModel {
                                Image(systemName: categoryModel.iconName)
                                    .foregroundColor(categoryModel.color)
                                Text(categoryModel.name)
                                    .foregroundColor(.primary)
                            } else {
                                Image(systemName: "tag")
                                    .foregroundColor(.gray)
                                Text("Seleccionar categoría")
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    
                    if selectedCategoryModel != nil {
                        Button(role: .destructive) {
                            selectedCategoryModel = nil
                            habit.categoria = nil
                        } label: {
                            Text("Quitar categoría")
                        }
                    }
                }
                
                Section(header: Text("Detalles del Hábito")) {
                    if AppConfig.showDueDates {
                        Toggle(isOn: Binding(
                            get: { habit.fechaFin != nil },
                            set: { newValue in
                                if newValue {
                                    habit.fechaFin = Date()
                                } else {
                                    habit.fechaFin = nil
                                }
                            }
                        )) {
                            Text("Vencimiento")
                        }
                        if let dueDate = habit.fechaFin {
                            DatePicker("Fecha de Vencimiento", selection: Binding(
                                get: { dueDate },
                                set: { habit.fechaFin = $0 }
                            ), displayedComponents: .date)
                        }
                    }
                    if AppConfig.showPriorities {
                        Picker("Prioridad", selection: Binding(
                            get: { habit.prioridad },
                            set: { habit.prioridad = $0 }
                        )) {
                            Text("Ninguna").tag(nil as Prioridad?)
                            Text("Baja").tag(Prioridad.low)
                            Text("Media").tag(Prioridad.medium)
                            Text("Alta").tag(Prioridad.high)
                        }
                    }
                    // Recordatorio moved to Features/Reminders
                    ReminderEditorView(reminderDate: $habit.reminderDate)
                }
                
                // Sección de Frecuencia
                Section(header: Text("Frecuencia")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selecciona los días de la semana")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(DiaSemana.allCases) { dia in
                                Button(action: {
                                    toggleDiaSemana(dia)
                                }) {
                                    Text(dia.nombreCorto)
                                        .font(.system(size: 14, weight: .medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            habit.diasSemana.contains(dia.rawValue) 
                                                ? Color.accentColor 
                                                : Color.gray.opacity(0.2)
                                        )
                                        .foregroundColor(
                                            habit.diasSemana.contains(dia.rawValue) 
                                                ? .white 
                                                : .primary
                                        )
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        if habit.diasSemana.isEmpty {
                            Text("Ningún día seleccionado (se considera diario)")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Sección de Historial de Completitud
                Section(header: Text("Historial de Completitud")) {
                    if habit.fechaCompletitud.isEmpty {
                        Text("Aún no has completado este hábito")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(habit.fechaCompletitud.count) días completados")
                                .font(.headline)
                            
                            // Mostrar últimos 7 días completados
                            ForEach(habit.fechaCompletitud.sorted(by: >).prefix(7), id: \.self) { fecha in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(fecha.formatted(date: .abbreviated, time: .omitted))
                                    Spacer()
                                    Text(nombreDiaSemana(fecha))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if habit.fechaCompletitud.count > 7 {
                                Text("Y \(habit.fechaCompletitud.count - 7) días más...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Sección dinámica de plugins
                // Si hay plugins activos (ej: Rutinas), sus vistas aparecen automáticamente
                ForEach(0..<PluginRegistry.shared.getHabitoDetailViews(for: $habit).count, id: \.self) { index in
                    Section {
                        PluginRegistry.shared.getHabitoDetailViews(for: $habit)[index]
                    }
                }
            }
            .navigationTitle($habit.title)
            .onDisappear {
                onSave?()
            }
            .onAppear {
                // Cargar la categoría seleccionada si existe
                if let categoryId = habit.categoria {
                    selectedCategoryModel = CategoryModel.allCategories.first { $0.id == categoryId }
                }
            }
            .onChange(of: habit.title) { _, _ in scheduleSave() }
            .onChange(of: habit.descripcion) { _, _ in scheduleSave() }
            .onChange(of: habit.fechaFin) { _, _ in scheduleSave() }
            .onChange(of: habit.prioridad) { _, _ in scheduleSave() }
            .onChange(of: habit.reminderDate) { _, _ in scheduleSave() }
            .onChange(of: habit.categoria) { _, _ in scheduleSave() }
            .onChange(of: habit.diasSemana) { _, _ in scheduleSave() }
            .onChange(of: selectedCategoryModel) { oldValue, newValue in
                habit.categoria = newValue?.id
            }
            .sheet(isPresented: $showCategorySelection) {
                NavigationStack {
                    CategorySelectionView(selectedCategory: $selectedCategoryModel)
                }
            }
        }
        Spacer()
    }
    
    // MARK: - Helper Methods
    
    private func toggleDiaSemana(_ dia: DiaSemana) {
        if let index = habit.diasSemana.firstIndex(of: dia.rawValue) {
            habit.diasSemana.remove(at: index)
        } else {
            habit.diasSemana.append(dia.rawValue)
            habit.diasSemana.sort()
        }
    }
    
    private func nombreDiaSemana(_ fecha: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: fecha)
        return DiaSemana(rawValue: weekday)?.nombre ?? ""
    }
}

#Preview {
    HabitDetailView(habit: .constant(Habito(title: "Ejemplo de Habito", descripcion: "descripcion", prioridad: .high, fechaFin: Date(), completada: false)))
}
