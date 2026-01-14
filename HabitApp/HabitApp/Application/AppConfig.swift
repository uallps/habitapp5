//
//  AppConfig.swift
//  TaskApp
//
//  Created by Aula03 on 15/10/25.
//
import SwiftUI
import Combine

class AppConfig: ObservableObject {
    @AppStorage("showPriorities")
    var showPriorities: Bool = true

    @AppStorage("enableReminders")
    var enableReminders: Bool = true

    @AppStorage("enableStreaks")
    var enableStreaks: Bool = true

    @AppStorage("enableDailyNotes")
    var enableDailyNotes: Bool = true

    @AppStorage("enableCategories")
    var enableCategories: Bool = true

    @AppStorage("enableStatistics")
    var enableStatistics: Bool = true

    @AppStorage("showDebugTools")
    var showDebugTools: Bool = false

    @AppStorage("storageType")
    var storageType: StorageType = .json

    var storageProvider: StorageProvider {
        switch storageType {
        case .swiftData:
            return SwiftDataStorageProvider.shared
        case .json:
            return JSONStorageProvider.shared
        }
    }
}

enum StorageType: String, CaseIterable, Identifiable {
    case swiftData = "SwiftData Storage"
    case json = "JSON Storage"

    var id: String { self.rawValue }
}
