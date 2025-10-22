//
//  TaskListView.swift
//  TaskApp
//
//  Created by Aula03 on 15/10/25.
//

import Foundation
import SwiftUI

struct HabitListView: View {
    @StateObject var viewModel = HabitListView()

    var body: some View {
        VStack{
            NavigationStack{
                List($viewModel.tasks) { $task in
                    NavigationLink(destination: TaskDetailView(task: $task)){
                        TaskRowView(task: task, toggleCompletion: {
                            viewModel.toggleCompletion(task:task)
                        })}
                }
                .toolbar {
                    Button("Añadir Hábito") {
                        let newTask = Task(title:"Nuevo Hábito")
                        viewModel.addTask(task:newTask)
                    }
                }.navigationTitle("Hábitos")
            }
        }
    }
}

#Preview {
    HabitListView()
}