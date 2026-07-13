//
//  Contact.swift
//  ContactManager
//

import Foundation
import SwiftData

/// The single persisted entity. SwiftData `@Model` types are Swift-only and
/// cannot be exposed to Objective-C, which is why the ObjC layer talks to
/// `ContactDTO` instead (see `ContactStore`).
@Model
final class Contact {
    var id: UUID
    var firstName: String
    var lastName: String
    var phoneNumber: String
    var email: String
    var isFavorite: Bool
    /// Exactly one record is the device owner shown in the "Me" tab.
    var isUserProfile: Bool
    /// Large blob kept out of the main store file.
    @Attribute(.externalStorage) var imageData: Data?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        firstName: String = "",
        lastName: String = "",
        phoneNumber: String = "",
        email: String = "",
        isFavorite: Bool = false,
        isUserProfile: Bool = false,
        imageData: Data? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.email = email
        self.isFavorite = isFavorite
        self.isUserProfile = isUserProfile
        self.imageData = imageData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}
