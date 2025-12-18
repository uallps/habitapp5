import SwiftUI

struct HabitDetailView: View {
    @Binding var habit: Habito
    var onSave: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var AppConfig: AppConfig
    @State private var showCategorySelection = false
    @State private var selectedCategoryModel: CategoryModel?
    
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
                    Toggle(isOn: $habit.completada) {
                        Text("Completada")
                    }
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
}

#Preview {
    HabitDetailView(habit: .constant(Habito(title: "Ejemplo de Habito", descripcion: "descripcion", prioridad: .high, fechaFin: Date(), completada: false)))
}
