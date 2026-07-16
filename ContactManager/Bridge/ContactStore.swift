//
//  ContactStore.swift
//  ContactManager
//
//  Single source of truth over SwiftData, exposed to Objective-C via @objc.
//  Both the SwiftUI screens and the Objective-C list read/write through here.
//

import Foundation
import SwiftData

@objc(ContactStore)
@MainActor
final class ContactStore: NSObject {

    /// Raw name string so Objective-C can observe the same notification
    /// (it observes @"ContactsDidChange").
    @objc static let contactsDidChangeNotification = "ContactsDidChange"

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        super.init()
    }

    // MARK: - Read (shared by the ObjC list and unit tests)

    /// Search-by-any-field lives here so the ObjC list and the tests use one
    /// implementation. Matches first name, last name, phone, and email.
    @objc(contactsMatchingSearch:favoritesOnly:ascending:)
    func contacts(matchingSearch search: String,
                  favoritesOnly: Bool,
                  ascending: Bool) -> [ContactDTO] {
        let predicate: Predicate<Contact>
        if favoritesOnly {
            predicate = #Predicate { $0.isUserProfile == false && $0.isFavorite == true }
        } else {
            predicate = #Predicate { $0.isUserProfile == false }
        }

        let descriptor = FetchDescriptor<Contact>(predicate: predicate)
        let all = (try? context.fetch(descriptor)) ?? []

        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered: [Contact]
        if trimmed.isEmpty {
            filtered = all
        } else {
            filtered = all.filter { c in
                c.firstName.localizedCaseInsensitiveContains(trimmed) ||
                c.lastName.localizedCaseInsensitiveContains(trimmed) ||
                c.phoneNumber.localizedCaseInsensitiveContains(trimmed) ||
                c.email.localizedCaseInsensitiveContains(trimmed)
            }
        }

        let sorted = filtered.sorted { lhs, rhs in
            let result = lhs.fullName.localizedStandardCompare(rhs.fullName)
            return ascending ? result == .orderedAscending : result == .orderedDescending
        }

        return sorted.map { ContactDTO(contact: $0) }
    }

    /// Fetch a single model by its UUID string (used when opening detail).
    func contact(withID id: String) -> Contact? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        var descriptor = FetchDescriptor<Contact>(predicate: #Predicate { $0.id == uuid })
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    /// The single user-profile contact for the "Me" tab.
    func userProfile() -> Contact? {
        var descriptor = FetchDescriptor<Contact>(predicate: #Predicate { $0.isUserProfile == true })
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    // MARK: - Write

    @discardableResult
    func createContact(
        firstName: String,
        lastName: String,
        phoneNumber: String,
        email: String,
        isFavorite: Bool,
        imageData: Data?
    ) -> Contact? {
        let contact = Contact(
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            email: email,
            isFavorite: isFavorite,
            imageData: imageData
        )
        context.insert(contact)
        guard saveAndNotify() else { return nil }
        return contact
    }

    @discardableResult
    func updateContact(
        id: String,
        firstName: String,
        lastName: String,
        phoneNumber: String,
        email: String,
        isFavorite: Bool,
        imageData: Data?
    ) -> Bool {
        guard let contact = contact(withID: id) else { return false }
        contact.firstName = firstName
        contact.lastName = lastName
        contact.phoneNumber = phoneNumber
        contact.email = email
        contact.isFavorite = isFavorite
        contact.imageData = imageData
        contact.updatedAt = .now
        return saveAndNotify()
    }

    /// Persist edits already applied on a live `Contact` instance.
    /// Prefer `updateContact` when fields are held in a view-model draft.
    @discardableResult
    func commit(_ contact: Contact) -> Bool {
        contact.updatedAt = .now
        return saveAndNotify()
    }

    @discardableResult
    @objc(deleteContactsWithIDs:)
    func deleteContacts(ids: [String]) -> Bool {
        for id in ids {
            guard let contact = contact(withID: id) else { continue }
            // Never allow deleting the device owner record.
            guard !contact.isUserProfile else { continue }
            context.delete(contact)
        }
        return saveAndNotify()
    }

    @discardableResult
    @objc(setFavorite:forID:)
    func setFavorite(_ isFavorite: Bool, forID id: String) -> Bool {
        guard let contact = contact(withID: id) else { return false }
        contact.isFavorite = isFavorite
        contact.updatedAt = .now
        return saveAndNotify()
    }

    // MARK: - Persistence

    /// Saves the context and posts `contactsDidChangeNotification` only on success.
    /// On failure, rolls back in-memory changes and returns `false`.
    @discardableResult
    private func saveAndNotify() -> Bool {
        do {
            try context.save()
            NotificationCenter.default.post(
                name: Notification.Name(ContactStore.contactsDidChangeNotification),
                object: nil
            )
            return true
        } catch {
            context.rollback()
            return false
        }
    }
}
