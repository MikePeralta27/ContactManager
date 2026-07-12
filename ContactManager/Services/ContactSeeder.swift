//
//  ContactSeeder.swift
//  ContactManager
//

import Foundation
import SwiftData

/// One-time seeding of the single "Me" user-profile record.
///
/// Runs from `ContactManagerApp.init()` (not a view) so it executes exactly
/// once per launch and cannot create duplicate profiles on view recreation.
enum ContactSeeder {
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        var descriptor = FetchDescriptor<Contact>(
            predicate: #Predicate { $0.isUserProfile == true }
        )
        descriptor.fetchLimit = 1

        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let me = Contact(
            firstName: "Me",
            lastName: "",
            phoneNumber: "",
            email: "",
            isFavorite: false,
            isUserProfile: true
        )
        context.insert(me)
        try? context.save()
    }
}
