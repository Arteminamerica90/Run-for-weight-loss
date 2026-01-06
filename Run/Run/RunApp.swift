//
//  RunApp.swift
//  Run
//
//  Created by Artem Menshikov on 04.01.2026.
//

import SwiftUI

@main
struct RunApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
