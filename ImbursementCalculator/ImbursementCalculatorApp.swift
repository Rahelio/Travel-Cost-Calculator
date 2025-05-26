//
//  ImbursementCalculatorApp.swift
//  ImbursementCalculator
//
//  Created by Rahelio on 26/05/2025.
//

import SwiftUI

@main
struct ImbursementCalculatorApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
