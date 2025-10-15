//
//  Task.swift
//  TaskApp
//
//  Created by Aula03 on 15/10/25.
//

import Foundation

struct Task{
    let id=UUID()
    var title: String
    var isCompleted: Bool = false
        var dueDate: Date?
        var priority: Int?
}

enum Priority: String, Codable{
    case Low, Medium, High
}
