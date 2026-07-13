//
//  PreviewSupport.swift
//  ContactManager
//
//  Helpers for SwiftUI #Preview blocks: an in-memory store seeded with sample
//  contacts so previews render without touching the on-disk store.
//

#if DEBUG
import Foundation
import SwiftData

enum PreviewSupport {
    @MainActor
    static func makeStore(withSamples: Bool = true) -> ContactStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // Force-try is acceptable in preview-only code.
        let container = try! ModelContainer(for: Contact.self, configurations: config)
        let context = container.mainContext

        context.insert(Contact(firstName: "Me", isUserProfile: true))
        if withSamples {
            context.insert(Contact(firstName: "Ada", lastName: "Lovelace",
                                   phoneNumber: "5551110000", email: "ada@math.org",
                                   isFavorite: true))
            context.insert(Contact(firstName: "Alan", lastName: "Turing",
                                   phoneNumber: "5552223333", email: "alan@enigma.uk"))
        }
        try? context.save()

        // Retain the container for the preview's lifetime.
        PreviewSupport.retained = container
        return ContactStore(context: context)
    }

    /// Keeps the in-memory container alive while a preview is on screen.
    @MainActor static var retained: ModelContainer?
}
#endif
