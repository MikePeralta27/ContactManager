//
//  ContactManagerApp.swift
//  ContactManager
//
//  Created by Michael Peralta on 7/9/26.
//

import SwiftData
import SwiftUI

@main
struct ContactManagerApp: App {
    let container: ModelContainer
    let store: ContactStore

    init() {
        do {
            container = try ModelContainer(for: Contact.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        // Seed the single user profile exactly once, before any list queries.
        ContactSeeder.seedIfNeeded(context: container.mainContext)
        // Shared source of truth used by both the SwiftUI screens and the
        // Objective-C list (via the bridge).
        store = ContactStore(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(store: store)
        }
        .modelContainer(container)
    }
}
