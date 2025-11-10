//
//  camera_pocApp.swift
//  camera-poc
//
//  Created by Diogo Camargo on 06/11/25.
//

import SwiftUI
import SwiftData

@main
struct camera_pocApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            SimpleCameraView()
        }
        .modelContainer(sharedModelContainer)
    }
}
