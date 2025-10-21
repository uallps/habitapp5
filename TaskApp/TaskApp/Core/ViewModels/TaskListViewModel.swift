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
        Habito(title: "hollow")
    ]
}
