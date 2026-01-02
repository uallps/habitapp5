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
                
                // Categoría
                Text("Categoría")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
                
                Section {
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
                
                // Fechas de duración
                Text("Fechas de duración")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
                
                Section {
                    // Fecha de Inicio
                    HStack {
                        Text("Fecha de Inicio")
                            .frame(width: 150, alignment: .leading)
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { habit.fechaInicio ?? Date() },
                                set: { habit.fechaInicio = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                    }
                    
                    // Fecha de Vencimiento
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
                            HStack {
                                Text("Fecha de Vencimiento")
                                    .frame(width: 150, alignment: .leading)
                                DatePicker(
                                    "",
                                    selection: Binding(
                                        get: { dueDate },
                                        set: { habit.fechaFin = $0 }
                                    ),
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                            }
                        }
                    }
                }
                
                // Detalles del Hábito
                Text("Detalles del Hábito")
                    .font(.headline)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
                    .foregroundColor(.primary)
                
                Section {
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
                
                // Frecuencia
                Text("Frecuencia")
                    .font(.headline)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
                    .foregroundColor(.primary)
                
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        // Selector de tipo de frecuencia
                        Picker("Tipo de frecuencia", selection: Binding(
                            get: { habit.tipoFrecuencia ?? .semanal },
                            set: { habit.tipoFrecuencia = $0 }
                        )) {
                            ForEach(TipoFrecuencia.allCases, id: \.self) { tipo in
                                Text(tipo.rawValue).tag(tipo)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: habit.tipoFrecuencia) { _, _ in
                            // Limpiar configuración al cambiar de tipo
                            habit.diasSemana = []
                            habit.diasMes = []
                            habit.vecesPorPeriodo = 1
                        }
                        
                        // Selector de veces por periodo
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Veces por \(habit.tipoFrecuenciaActual == .semanal ? "semana" : "mes")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Stepper(value: Binding(
                                get: { habit.vecesPorPeriodo ?? 1 },
                                set: { newValue in
                                    let diasActuales = habit.tipoFrecuenciaActual == .semanal ? habit.diasSemana.count : habit.diasMes.count
                                    // Solo permitir cambiar si el nuevo valor es mayor o igual a los días seleccionados
                                    if newValue >= diasActuales {
                                        habit.vecesPorPeriodo = newValue
                                    }
                                }
                            ), 
                                   in: 1...(habit.tipoFrecuenciaActual == .semanal ? 7 : 31)) {
                                Text("\(habit.vecesPorPeriodoActual) \(habit.vecesPorPeriodoActual == 1 ? "vez" : "veces")")
                            }
                            
                            // Advertencia si hay días seleccionados que impiden reducir el número
                            let diasSeleccionados = habit.tipoFrecuenciaActual == .semanal ? habit.diasSemana.count : habit.diasMes.count
                            if diasSeleccionados > 0 && habit.vecesPorPeriodoActual <= diasSeleccionados {
                                Text("Deselecciona días para poder reducir el número de veces")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Divider()
                        
                        // Selector de días según el tipo
                        if habit.tipoFrecuenciaActual == .semanal {
                            frecuenciaSemanalView
                        } else {
                            frecuenciaMensualView
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
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(fecha.formatted(date: .abbreviated, time: .omitted))
                                        if !habit.debeRealizarse(en: fecha) {
                                            Text("(fuera de días establecidos)")
                                                .font(.caption2)
                                                .foregroundColor(.orange)
                                        }
                                    }
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
                // Inicializar valores por defecto si son nil (migración de datos existentes)
                if habit.tipoFrecuencia == nil {
                    habit.tipoFrecuencia = .semanal
                }
                if habit.vecesPorPeriodo == nil {
                    habit.vecesPorPeriodo = 1
                }
                
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
            .onChange(of: habit.tipoFrecuencia) { _, _ in scheduleSave() }
            .onChange(of: habit.vecesPorPeriodo) { _, _ in scheduleSave() }
            .onChange(of: habit.diasSemana) { _, _ in scheduleSave() }
            .onChange(of: habit.diasMes) { _, _ in scheduleSave() }
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
    
    // Vista para frecuencia semanal
    private var frecuenciaSemanalView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selecciona los días de la semana")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
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
            
            // Validación
            let vecesRequeridas = habit.vecesPorPeriodoActual
            let diasSeleccionados = habit.diasSemana.count
            
            if diasSeleccionados == 0 {
                Text("Selecciona \(vecesRequeridas) \(vecesRequeridas == 1 ? "día" : "días")")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else if diasSeleccionados < vecesRequeridas {
                Text("Selecciona \(vecesRequeridas) \(vecesRequeridas == 1 ? "día" : "días") (faltan \(vecesRequeridas - diasSeleccionados))")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else if diasSeleccionados == vecesRequeridas {
                Text("✓ \(diasSeleccionados) \(diasSeleccionados == 1 ? "día seleccionado" : "días seleccionados")")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
    
    // Vista para frecuencia mensual
    private var frecuenciaMensualView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selecciona los días del mes")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Mostrar advertencia si hay días que exceden el mes actual
            if let advertencia = habit.advertenciaDiasMes() {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(advertencia)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Grid de días (1-31)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(1...31, id: \.self) { dia in
                    Button(action: {
                        toggleDiaMes(dia)
                    }) {
                        Text("\(dia)")
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                habit.diasMes.contains(dia) 
                                    ? Color.accentColor 
                                    : Color.gray.opacity(0.2)
                            )
                            .foregroundColor(
                                habit.diasMes.contains(dia) 
                                    ? .white 
                                    : .primary
                            )
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Validación
            let vecesRequeridas = habit.vecesPorPeriodoActual
            let diasSeleccionados = habit.diasMes.count
            
            if diasSeleccionados == 0 {
                Text("Selecciona \(vecesRequeridas) \(vecesRequeridas == 1 ? "día" : "días")")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else if diasSeleccionados < vecesRequeridas {
                Text("Selecciona \(vecesRequeridas) \(vecesRequeridas == 1 ? "día" : "días") (faltan \(vecesRequeridas - diasSeleccionados))")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else if diasSeleccionados == vecesRequeridas {
                Text("✓ \(diasSeleccionados) \(diasSeleccionados == 1 ? "día seleccionado" : "días seleccionados")")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
    
    private func toggleDiaSemana(_ dia: DiaSemana) {
        if let index = habit.diasSemana.firstIndex(of: dia.rawValue) {
            // Siempre permitir deseleccionar
            habit.diasSemana.remove(at: index)
        } else {
            // Solo permitir agregar si no excede el número de veces por periodo
            if habit.diasSemana.count < habit.vecesPorPeriodoActual {
                habit.diasSemana.append(dia.rawValue)
                habit.diasSemana.sort()
            }
        }
    }
    
    private func toggleDiaMes(_ dia: Int) {
        if let index = habit.diasMes.firstIndex(of: dia) {
            // Siempre permitir deseleccionar
            habit.diasMes.remove(at: index)
        } else {
            // Solo permitir agregar si no excede el número de veces por periodo
            if habit.diasMes.count < habit.vecesPorPeriodoActual {
                habit.diasMes.append(dia)
                habit.diasMes.sort()
            }
        }
    }
    
    private func nombreDiaSemana(_ fecha: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: fecha)
        return DiaSemana(rawValue: weekday)?.nombre ?? ""
    }
}

#Preview {
    HabitDetailView(habit: .constant(Habito(title: "Ejemplo de Habito", descripcion: "descripcion", prioridad: .high, fechaFin: Date())))
}
