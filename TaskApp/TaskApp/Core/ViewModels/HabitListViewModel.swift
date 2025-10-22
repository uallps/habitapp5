//
//  TaskListViewModel.swift
//  TaskApp
//
//  Created by Aula03 on 15/10/25.
//

import Foundation
import Combine

class TaskListViewModel: ObservableObject{
    @Published var tasks: [Habito]=[
        Habito(title: "hollow"),
        Habito(title: "Terminar LPS", prioridad=.high),
        Habito(title: "Sushi",  fechaFin: Date().addingTimeInterval(86400))
    ]

     func addTask(task: Habito) {
        tasks.append(task)
    }
    
    func toggleCompletion(task: Habito) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].completada.toggle()
        }
}
