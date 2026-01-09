import SwiftUI

private enum CalendarHabitRowKind {
    case scheduled
    case completed
}

struct CalendarView: View {
    @StateObject private var habitsViewModel: HabitListViewModel

    @State private var displayedMonth: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var draftHabit: Habito = Habito(title: "Nuevo Hábito", descripcion: "Descripcion")
    @State private var isPresentingNewHabit = false
    @State private var lastNewHabitPresentationAt: Date = .distantPast
    @State private var habitPendingDeletion: Habito? = nil
    @State private var editingHabitId: UUID? = nil

    init(storageProvider: StorageProvider) {
        _habitsViewModel = StateObject(wrappedValue: HabitListViewModel(storageProvider: storageProvider))
    }

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "es_ES")
        cal.firstWeekday = 2 // Lunes
        return cal
    }

    private var esLocale: Locale { Locale(identifier: "es_ES") }

    private var scheduledDotColor: Color { Color.secondary.opacity(0.8) }
    private var completedDotColor: Color { Color.green }
    private var todayHighlightColor: Color { Color.purple }

    private var monthStart: Date {
        let comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        return calendar.date(from: comps) ?? displayedMonth
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
    }

    // Lunes=0 ... Domingo=6
    private var leadingBlankDays: Int {
        let weekday = calendar.component(.weekday, from: monthStart)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    private var weekdaySymbolsMondayFirst: [String] {
        // En español suele ser L M X J V S D
        return ["L", "M", "X", "J", "V", "S", "D"]
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = esLocale
        formatter.setLocalizedDateFormatFromTemplate("LLLL yyyy")
        return formatter.string(from: monthStart).capitalized(with: esLocale)
    }

    private func formatSelectedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = esLocale
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMMM yyyy")
        return formatter.string(from: date).capitalized(with: esLocale)
    }

    private var completedHabitsByDay: [Date: [Habito]] {
        var dict: [Date: [Habito]] = [:]

        let monthEndExclusive = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart

        for habit in habitsViewModel.habitos {
            for completionDate in habit.fechaCompletitud {
                let day = calendar.startOfDay(for: completionDate)
                guard day >= monthStart && day < monthEndExclusive else { continue }
                guard isHabitActive(habit, on: day) else { continue }
                dict[day, default: []].append(habit)
            }
        }

        return dict
    }

    private var scheduledHabitsByDay: [Date: [Habito]] {
        var dict: [Date: [Habito]] = [:]

        let monthEndExclusive = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
        var day = monthStart

        while day < monthEndExclusive {
            let key = calendar.startOfDay(for: day)
            let scheduled = habitsViewModel.habitos.filter { habit in
                isHabitActive(habit, on: key) && habit.debeRealizarse(en: key)
            }
            if !scheduled.isEmpty {
                dict[key] = scheduled
            }
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? monthEndExclusive
        }

        return dict
    }

    private var selectedDayKey: Date {
        calendar.startOfDay(for: selectedDate)
    }

    private var isSelectedDayToday: Bool {
        calendar.isDate(selectedDayKey, inSameDayAs: Date())
    }

    private var selectedDayHabits: [Habito] {
        completedHabitsByDay[selectedDayKey] ?? []
    }

    private var selectedDayScheduledHabits: [Habito] {
        scheduledHabitsByDay[selectedDayKey] ?? []
    }

    var body: some View {
        calendarRootView
            .navigationTitle("Calendario")
            .alert(
                "Eliminar hábito",
                isPresented: Binding(
                    get: { habitPendingDeletion != nil },
                    set: { if !$0 { habitPendingDeletion = nil } }
                ),
                presenting: habitPendingDeletion
            ) { habit in
                Button("Eliminar", role: .destructive) {
                    Task { @MainActor in
                        await deleteHabit(habit)
                    }
                }
                Button("Cancelar", role: .cancel) {
                    habitPendingDeletion = nil
                }
            } message: { habit in
                Text("¿Seguro que quieres eliminar \"\(habit.title)\"?")
            }
            .task {
                await habitsViewModel.loadHabits()
                displayedMonth = monthStart
                selectedDate = calendar.startOfDay(for: Date())
            }
            .sheet(isPresented: $isPresentingNewHabit, onDismiss: {
                resetDraftHabit()
            }) {
                NavigationStack {
                    HabitDetailView(habit: $draftHabit)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancelar") {
                                    isPresentingNewHabit = false
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Crear") {
                                    let habitToCreate = draftHabit
                                    isPresentingNewHabit = false
                                    Task { @MainActor in
                                        await habitsViewModel.addHabit(habit: habitToCreate)
                                        await habitsViewModel.loadHabits()
                                    }
                                }
                            }
                        }
                }
            }
        .sheet(isPresented: Binding(
            get: { editingHabitId != nil },
            set: { if !$0 { editingHabitId = nil } }
        )) {
            if let editingHabitId,
               let index = habitsViewModel.habitos.firstIndex(where: { $0.id == editingHabitId }) {
                NavigationStack {
                    HabitDetailView(
                        habit: Binding(
                            get: { habitsViewModel.habitos[index] },
                            set: { habitsViewModel.habitos[index] = $0 }
                        ),
                        onSave: {
                            Task { @MainActor in
                                await habitsViewModel.saveHabits()
                            }
                        }
                    )
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cerrar") {
                                self.editingHabitId = nil
                            }
                        }
                    }
                }
            }
        }
    }

    private var calendarRootView: some View {
        Group {
#if os(iOS)
            List {
                Section {
                    VStack(spacing: 12) {
                        calendarHeader
                        calendarLegend
                        calendarGrid
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.vertical, 8)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowSeparator(.hidden)

                dayDetailsList
            }
            .listStyle(.plain)
#else
            ScrollView {
                VStack(spacing: 12) {
                    calendarHeader
                    calendarLegend
                    calendarGrid

                    dayDetails
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
#endif
        }
    }

    private var calendarHeader: some View {
        HStack {
            Button {
                displayedMonth = calendar.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .background(AppStyle.subtleFill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(monthTitle)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            Button {
                displayedMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
            } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .background(AppStyle.subtleFill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var calendarLegend: some View {
        HStack(spacing: 14) {
            HStack(spacing: 6) {
                Circle()
                    .fill(scheduledDotColor)
                    .frame(width: 7, height: 7)
                Text("Programados")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(completedDotColor)
                    .frame(width: 7, height: 7)
                Text("Completados")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var calendarGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header de días de la semana
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                ForEach(weekdaySymbolsMondayFirst, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Días
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                let gridStart = calendar.date(byAdding: .day, value: -leadingBlankDays, to: monthStart) ?? monthStart

                ForEach(0..<42, id: \.self) { offset in
                    let date = calendar.date(byAdding: .day, value: offset, to: gridStart) ?? gridStart
                    let key = calendar.startOfDay(for: date)
                    let isInDisplayedMonth = calendar.isDate(key, equalTo: monthStart, toGranularity: .month)

                    let hasCompletions = (completedHabitsByDay[key]?.isEmpty == false)
                    let hasScheduled = (scheduledHabitsByDay[key]?.isEmpty == false)
                    let isSelected = calendar.isDate(key, inSameDayAs: selectedDayKey)
                    let isToday = calendar.isDate(key, inSameDayAs: Date())

                    Button {
                        // Si tocas un día fuera del mes, cambiar el mes mostrado.
                        if !isInDisplayedMonth {
                            displayedMonth = key
                        }
                        selectedDate = key
                    } label: {
                        ZStack {
                            Text("\(calendar.component(.day, from: key))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(isInDisplayedMonth ? .primary : .secondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)

                            VStack {
                                Spacer()
                                HStack(spacing: 6) {
                                    if hasScheduled {
                                        Circle()
                                            .fill(scheduledDotColor)
                                            .frame(width: 6, height: 6)
                                    }
                                    if hasCompletions {
                                        Circle()
                                            .fill(completedDotColor)
                                            .frame(width: 6, height: 6)
                                    }
                                }
                                .padding(.bottom, 5)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(
                                    isSelected
                                        ? Color.accentColor.opacity(0.14)
                                        : (isToday ? todayHighlightColor.opacity(0.10) : AppStyle.subtleFill)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    isSelected
                                        ? Color.accentColor.opacity(0.55)
                                        : (isToday ? todayHighlightColor.opacity(0.65) : Color.clear),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .appCard(padding: 14)
    }

    private var dayDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formatSelectedDate(selectedDate))
                .font(.subheadline.weight(.semibold))

            Button {
                presentNewHabit()
            } label: {
                Label {
                    Text("Añadir hábito")
                } icon: {
                    Image(systemName: "plus")
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .disabled(isPresentingNewHabit)

            if selectedDayScheduledHabits.isEmpty && selectedDayHabits.isEmpty {
                Text("No hay hábitos programados ni completados este día")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !selectedDayScheduledHabits.isEmpty {
                Text("Hábitos programados")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(selectedDayScheduledHabits, id: \.id) { habit in
                    CalendarHabitRowView(
                        habit: habit,
                        referenceDate: selectedDayKey,
                        rowKind: .scheduled,
                        showsCompletionToggle: isSelectedDayToday,
                        onToggleCompletion: {
                            Task { @MainActor in
                                await toggleCompletionForSelectedDay(habit)
                            }
                        },
                        onOpenDetails: {
                            editingHabitId = habit.id
                        }
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            habitPendingDeletion = habit
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
#if os(iOS)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            habitPendingDeletion = habit
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
#endif
                }
            }

            if !selectedDayHabits.isEmpty {
                Text("Hábitos completados")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, selectedDayScheduledHabits.isEmpty ? 0 : 4)

                ForEach(selectedDayHabits, id: \.id) { habit in
                    CalendarHabitRowView(
                        habit: habit,
                        referenceDate: selectedDayKey,
                        rowKind: .completed,
                        showsCompletionToggle: false,
                        onToggleCompletion: nil,
                        onOpenDetails: {
                            editingHabitId = habit.id
                        }
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            habitPendingDeletion = habit
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
#if os(iOS)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            habitPendingDeletion = habit
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
#endif
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(padding: 14)
    }

#if os(iOS)
    private var dayDetailsList: some View {
        Group {
            // Cabecera del día seleccionado + botón de crear.
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(formatSelectedDate(selectedDate))
                        .font(.subheadline.weight(.semibold))

                    Button {
                        presentNewHabit()
                    } label: {
                        Label {
                            Text("Añadir hábito")
                        } icon: {
                            Image(systemName: "plus")
                                .symbolRenderingMode(.monochrome)
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(isPresentingNewHabit)

                    if selectedDayScheduledHabits.isEmpty && selectedDayHabits.isEmpty {
                        Text("No hay hábitos programados ni completados este día")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            if !selectedDayScheduledHabits.isEmpty {
                Section(header:
                    Text("Hábitos programados")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                ) {
                    ForEach(selectedDayScheduledHabits, id: \.id) { habit in
                        CalendarHabitRowView(
                            habit: habit,
                            referenceDate: selectedDayKey,
                            rowKind: .scheduled,
                            showsCompletionToggle: isSelectedDayToday,
                            onToggleCompletion: {
                                Task { @MainActor in
                                    await toggleCompletionForSelectedDay(habit)
                                }
                            },
                            onOpenDetails: {
                                editingHabitId = habit.id
                            }
                        )
                        .contextMenu {
                            Button(role: .destructive) {
                                habitPendingDeletion = habit
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                habitPendingDeletion = habit
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            }

            if !selectedDayHabits.isEmpty {
                Section(header:
                    Text("Hábitos completados")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                ) {
                    ForEach(selectedDayHabits, id: \.id) { habit in
                        CalendarHabitRowView(
                            habit: habit,
                            referenceDate: selectedDayKey,
                            rowKind: .completed,
                            showsCompletionToggle: false,
                            onToggleCompletion: nil,
                            onOpenDetails: {
                                editingHabitId = habit.id
                            }
                        )
                        .contextMenu {
                            Button(role: .destructive) {
                                habitPendingDeletion = habit
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                habitPendingDeletion = habit
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            }
        }
    }
#endif

    private func deleteHabit(_ habit: Habito) async {
        defer { habitPendingDeletion = nil }
        guard let index = habitsViewModel.habitos.firstIndex(where: { $0.id == habit.id }) else {
            return
        }
        await habitsViewModel.removeHabits(atOffsets: IndexSet(integer: index))
        await habitsViewModel.loadHabits()
    }

    private func presentNewHabit() {
        // En iOS (List + sheet) puede dispararse dos veces el tap.
        // Si el sheet ya está presentado, no volvemos a presentarlo.
        guard !isPresentingNewHabit else { return }

        // Debounce para evitar reaperturas inmediatas por eventos duplicados.
        let now = Date()
        guard now.timeIntervalSince(lastNewHabitPresentationAt) > 0.6 else { return }
        lastNewHabitPresentationAt = now

        let dayOfMonth = calendar.component(.day, from: selectedDayKey)

        let habit = Habito(title: "Nuevo Hábito", descripcion: "Descripcion")
        habit.tipoFrecuencia = .mensual
        habit.vecesPorPeriodo = 1
        habit.diasSemana = []
        habit.diasMes = [dayOfMonth]

        draftHabit = habit
        isPresentingNewHabit = true
    }

    private func resetDraftHabit() {
        // Preparar un borrador limpio para la próxima creación.
        draftHabit = Habito(title: "Nuevo Hábito", descripcion: "Descripcion")
    }

    private func isHabitActive(_ habit: Habito, on day: Date) -> Bool {
        let d = calendar.startOfDay(for: day)

        // Si `fechaInicio` es nil, en la UI se muestra "hoy" por defecto.
        // Para que el grid no marque programados antes del inicio, tratamos nil como "hoy".
        let effectiveStart = habit.fechaInicio ?? Date()
        if calendar.compare(d, to: effectiveStart, toGranularity: .day) == .orderedAscending {
            return false
        }

        if let end = habit.fechaFin {
            if calendar.compare(d, to: end, toGranularity: .day) == .orderedDescending {
                return false
            }
        }

        return true
    }

    @MainActor
    private func toggleCompletionForSelectedDay(_ habit: Habito) async {
        // Solo permitir completar/descompletar en el día actual.
        guard isSelectedDayToday else { return }
        guard let index = habitsViewModel.habitos.firstIndex(where: { $0.id == habit.id }) else { return }

        habitsViewModel.habitos[index].toggleCompletitud(para: selectedDayKey)
        await habitsViewModel.saveHabits()
    }

}

private struct CalendarHabitRowView: View {
    let habit: Habito
    let referenceDate: Date
    let rowKind: CalendarHabitRowKind
    let showsCompletionToggle: Bool
    let onToggleCompletion: (() -> Void)?
    let onOpenDetails: (() -> Void)?

    init(
        habit: Habito,
        referenceDate: Date,
        rowKind: CalendarHabitRowKind,
        showsCompletionToggle: Bool = false,
        onToggleCompletion: (() -> Void)? = nil,
        onOpenDetails: (() -> Void)? = nil
    ) {
        self.habit = habit
        self.referenceDate = referenceDate
        self.rowKind = rowKind
        self.showsCompletionToggle = showsCompletionToggle
        self.onToggleCompletion = onToggleCompletion
        self.onOpenDetails = onOpenDetails
    }

    @EnvironmentObject private var appConfig: AppConfig

    private var calendar: Calendar { Calendar.current }

    private var isCompletedOutsideScheduledDay: Bool {
        habit.estaCompletado(en: referenceDate) && !habit.debeRealizarse(en: referenceDate)
    }

    private var isCompletedOnReferenceDay: Bool {
        habit.estaCompletado(en: referenceDate)
    }

    private var isCompletedSectionRow: Bool {
        rowKind == .completed
    }

    private var completedTitleLeadingInset: CGFloat {
        // Ancho del icono + spacing, para alinear el resto del contenido con el inicio del título.
        isCompletedSectionRow ? 24 : 0
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if showsCompletionToggle {
                Button {
                    onToggleCompletion?()
                } label: {
                    Image(systemName: isCompletedOnReferenceDay ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isCompletedOnReferenceDay ? Color.accentColor : Color.secondary)
                        .padding(.top, 2)
                }
                .buttonStyle(.borderless)
            }

            Button {
                onOpenDetails?()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        if isCompletedSectionRow {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.body)
                                .foregroundStyle(.green)
                                .frame(width: 18, alignment: .leading)
                        }

                        Text(habit.title)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        // Frecuencia (similar a la lista)
                        HStack(spacing: 4) {
                            Text(habit.tipoFrecuenciaActual == .semanal ? "Semanal:" : "Mensual:")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if habit.tipoFrecuenciaActual == .semanal && !habit.diasSemana.isEmpty {
                                HStack(spacing: 2) {
                                    ForEach(habit.diasConfigurados) { dia in
                                        let isReferenceDay = calendar.component(.weekday, from: referenceDate) == dia.rawValue
                                        let isDone = isReferenceDay && habit.estaCompletado(en: referenceDate)
                                        Text(dia.nombreCorto)
                                            .font(.caption2.weight(.medium))
                                            .frame(width: 18, height: 18)
                                            .background(isDone ? Color.accentColor.opacity(0.18) : AppStyle.subtleFill)
                                            .foregroundStyle(isDone ? .primary : .secondary)
                                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                    }
                                }
                            } else if habit.tipoFrecuenciaActual == .mensual && !habit.diasMes.isEmpty {
                                Text(formatDiasMes(habit.diasMes))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text("(\(habit.vecesPorPeriodoActual)x)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Categoría
                        if let categoryId = habit.categoria,
                           let category = CategoryModel.allCategories.first(where: { $0.id == categoryId }) {
                            HStack(spacing: 4) {
                                Image(systemName: category.iconName)
                                    .font(.caption)
                                Text(category.name)
                                    .font(.caption)
                            }
                            .foregroundStyle(category.color)
                        }

                        if appConfig.showDueDates, let dueDate = habit.fechaFin {
                            Text("Vence: \(dueDate.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if appConfig.showPriorities, let priority = habit.prioridad {
                            Text("Prioridad: \(priority.rawValue)")
                                .font(.caption)
                                .foregroundStyle(priorityColor(for: priority))
                        }

                        if appConfig.enableReminders, let reminderDate = habit.reminderDate {
                            Label("Recordatorio: \(reminderDate.formatted(date: .abbreviated, time: .shortened))", systemImage: "bell")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

#if os(iOS)
                        if isCompletedOutsideScheduledDay {
                            Text("Completado fuera de fecha establecida")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .padding(.top, 6)
                        }
#endif
                    }
                    .padding(.leading, completedTitleLeadingInset)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

            // igual que en la lista
            ForEach(0..<PluginRegistry.shared.getHabitoRowViews(for: habit).count, id: \.self) { index in
                PluginRegistry.shared.getHabitoRowViews(for: habit)[index]
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(padding: 14)
#if os(macOS)
        .overlay {
            if isCompletedOutsideScheduledDay {
                if isCompletedSectionRow {
                    VStack {
                        Spacer(minLength: 0)
                        HStack {
                            Spacer(minLength: 0)
                            Text("Completado fuera de fecha establecida")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .padding(10)
                        }
                    }
                } else {
                    VStack {
                        HStack {
                            Spacer(minLength: 0)
                            Text("Completado fuera de fecha establecida")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .padding(10)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
#endif
    }

    private func formatDiasMes(_ dias: [Int]) -> String {
        if dias.isEmpty { return "" }
        if dias.count == 1 {
            return "Día \(dias[0])"
        }
        if dias.count <= 3 {
            return "Días " + dias.map { String($0) }.joined(separator: ", ")
        }
        return "Días \(dias.first!)...\(dias.last!)"
    }

    private func priorityColor(for priority: Prioridad) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
}
