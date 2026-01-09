import SwiftUI

struct HabitDetailView: View {
    private var formView: some View {
        let pluginDetailViews = PluginRegistry.shared.getHabitoDetailViews(for: $habit)

        return Form {
            Section {
                TextField("Título del hábito", text: $habit.title)
                    #if os(iOS)
                    .textInputAutocapitalization(.sentences)
                    #endif
            }

            Section(header: AppSectionHeader(title: "Categoría")) {
                Button {
                    showCategorySelection = true
                } label: {
                    HStack {
                        if let categoryModel = selectedCategoryModel {
                            Image(systemName: categoryModel.iconName)
                                .foregroundStyle(categoryModel.color)
                            Text(categoryModel.name)
                                .foregroundStyle(.primary)
                        } else {
                            Image(systemName: "tag")
                                .foregroundStyle(.secondary)
                            Text("Seleccionar categoría")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                }
                #if os(macOS)
                .frame(maxWidth: .infinity, alignment: .leading)
                #endif

                if selectedCategoryModel != nil {
                    Button(role: .destructive) {
                        selectedCategoryModel = nil
                        habit.categoria = nil
                    } label: {
                        Text("Quitar categoría")
                    }
                    #if os(macOS)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    #endif
                }
            }

            Section(header: AppSectionHeader(title: "Fechas")) {
                LabeledContent("Inicio") {
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

                if AppConfig.showDueDates {
                    Toggle(isOn: Binding(
                        get: { habit.fechaFin != nil },
                        set: { newValue in
                            habit.fechaFin = newValue ? (habit.fechaFin ?? Date()) : nil
                        }
                    )) {
                        Text("Vencimiento")
                    }

                    if let dueDate = habit.fechaFin {
                        LabeledContent("Fecha") {
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

            Section(header: AppSectionHeader(title: "Detalles")) {
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

            Section(header: AppSectionHeader(title: "Frecuencia")) {
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
                            .foregroundStyle(.secondary)

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
                                .foregroundStyle(.tint)
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

            // Sección de Notas Diarias
            Section(header: AppSectionHeader(title: "Notas Diarias")) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        DailyNoteView(habit: habit)
                    }
                }
            }

            // Sección de Historial de Completitud
            Section(header: AppSectionHeader(title: "Historial de Completitud")) {
                VStack(alignment: .leading, spacing: 8) {
                    if habit.fechaCompletitud.isEmpty {
                    Text("Aún no has completado este hábito")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(habit.fechaCompletitud.count) días completados")
                        .font(.headline)
                        
                    // Mostrar últimos 7 días completados
                    ForEach(habit.fechaCompletitud.sorted(by: >).prefix(7), id: \.self) { fecha in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fecha.formatted(date: .abbreviated, time: .omitted))
                                if !habit.debeRealizarse(en: fecha) {
                                    Text("(fuera de días establecidos)")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                            Spacer()
                            Text(nombreDiaSemana(fecha))
                                .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if habit.fechaCompletitud.count > 7 {
                            Text("Y \(habit.fechaCompletitud.count - 7) días más...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
            }

            // Sección de Racha
            Section(header: AppSectionHeader(title: "Racha")) {
                StreakSectionView(habit: $habit)
                
                // TEMPORAL: Helper para probar rachas
                // Comentar o eliminar esta línea cuando no hagamos debug de rachas
                StreakTestHelper(habit: $habit)
            }

            // Sección dinámica de plugins
            // Si hay plugins activos (ej: Rutinas), sus vistas aparecen automáticamente
            if !pluginDetailViews.isEmpty {
                ForEach(pluginDetailViews.indices, id: \.self) { index in
                    Section {
                        #if os(macOS)
                        HStack(spacing: 0) {
                            pluginDetailViews[index]
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        #else
                        pluginDetailViews[index]
                        #endif
                    }
                }
            }
        }
    }

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
    
    var body: some View { finalView }

    private var baseView: some View {
        #if os(macOS)
        ScrollView {
            formView
                // Help the ScrollView compute a real content height.
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
        #else
        formView
        #endif
    }

    private var titledView: some View {
        baseView
            .appFormContainer()
            .navigationTitle(habit.title)
    }

    private var lifecycleView: some View {
        titledView
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
            .onDisappear {
                onSave?()
            }
    }

    private var autosaveView: some View {
        lifecycleView
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
            .onChange(of: selectedCategoryModel) { _, newValue in
                habit.categoria = newValue?.id
            }
    }

    private var finalView: some View {
        autosaveView
            .sheet(isPresented: $showCategorySelection) {
                NavigationStack {
                    CategorySelectionView(selectedCategory: $selectedCategoryModel)
                }
            }
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
