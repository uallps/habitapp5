//
//  AppConfig.swift
//  TaskApp
//
//  Created by Aula03 on 15/10/25.
//
import SwiftUI
import Combine

class AppConfig: ObservableObject {
    @AppStorage("showDueDates")
    var showDueDates: Bool = true

    @AppStorage("showPriorities")
    var showPriorities: Bool = true

    @AppStorage("enableReminders")
    var enableReminders: Bool = true

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
