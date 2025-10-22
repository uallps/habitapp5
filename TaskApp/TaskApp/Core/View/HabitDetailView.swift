import SwiftUI

struct TaskDetailView: View {
    @Binding var task: Habito;
    
    var body: some View {
        Form {
            TextField("Título de la tarea", text: $task.title)
        }
        .navigationTitle($task.title)
    
    }
}