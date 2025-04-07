//
//  PuzzleLocatorApp.swift
//  PuzzleLocator
//
//  Created by Sheng Ma on 4/7/25.
//

import SwiftUI

@main
struct PuzzleLocatorApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
