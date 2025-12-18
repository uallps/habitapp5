import SwiftUI
import Combine

struct ReminderEditorView: View {
    @Binding var reminderDate: Date?
    @EnvironmentObject private var AppConfig: AppConfig
    @StateObject private var viewModel: ReminderViewModel

    init(reminderDate: Binding<Date?>) {
        self._reminderDate = reminderDate
        _viewModel = StateObject(wrappedValue: ReminderViewModel(reminderDate: reminderDate.wrappedValue, onChange: { newValue in
            // Will be replaced in init by binding assignment below
        }))
        // Note: We'll update the onChange closure to write back to the binding in .onAppear
    }

    var body: some View {
        Group {
            if AppConfig.enableReminders {
                Toggle(isOn: Binding(
                    get: { viewModel.reminderDate != nil },
                    set: { enabled in viewModel.toggle(enabled) }
                )) {
                    Text("Recordatorio")
                }
                if viewModel.reminderDate != nil {
                    DatePicker("Fecha de Recordatorio", selection: Binding(
                        get: { viewModel.reminderDate ?? Date() },
                        set: { viewModel.reminderDate = $0 }
                    ), displayedComponents: [.date, .hourAndMinute])
                }
            }
        }
        .onAppear {
            // Ensure the view model writes changes back to the original binding
            viewModel.objectWillChange.send()
            // Replace viewModel's onChange by creating a new one is not possible here,
            // but we can listen to published changes and write them back to the binding.
            // Using Combine would be nicer, but to keep things simple we'll use a task-based observer.
            // Mirror viewModel.reminderDate into the binding when the view appears and when it changes.
            if viewModel.reminderDate != reminderDate {
                viewModel.reminderDate = reminderDate
            }
        }
        .onChange(of: viewModel.reminderDate) { newValue in
            reminderDate = newValue
        }
        .onChange(of: reminderDate) { newValue in
            if viewModel.reminderDate != newValue {
                viewModel.reminderDate = newValue
            }
        }
    }
}

#Preview {
    ReminderEditorView(reminderDate: .constant(nil))
}
